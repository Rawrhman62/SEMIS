import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/livestock.dart';
import 'database_helper.dart';

/// Mengelola komunikasi dengan Google Drive API untuk sinkronisasi data ternak.
/// File master JSON disimpan di Drive App Data folder (appDataFolder scope).
class DriveService {
  DriveService._internal();
  static final DriveService instance = DriveService._internal();

  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApiBase =
      'https://www.googleapis.com/upload/drive/v3';
  static const String _masterFileName = 'semis_livestock_master.json';

  /// Ambil file ID dari file master JSON di Drive, null jika belum ada.
  Future<String?> _getMasterFileId(String accessToken) async {
    final uri = Uri.parse(
      '$_driveApiBase/files'
      '?spaces=appDataFolder'
      '&q=name%3D%27$_masterFileName%27'
      '&fields=files(id)',
    );

    final response = await http.get(uri, headers: _authHeaders(accessToken));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final files = body['files'] as List<dynamic>;
      if (files.isNotEmpty) {
        return files.first['id'] as String?;
      }
    } else {
      debugPrint('[Drive] Get file list error: ${response.statusCode} ${response.body}');
    }
    return null;
  }

  /// Unduh data master saat ini dari Drive (untuk merge sebelum upload).
  Future<List<Livestock>> downloadMaster(String accessToken) async {
    final fileId = await _getMasterFileId(accessToken);
    if (fileId == null) return [];

    final uri = Uri.parse('$_driveApiBase/files/$fileId?alt=media');
    final response = await http.get(uri, headers: _authHeaders(accessToken));

    if (response.statusCode == 200) {
      try {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => Livestock.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[Drive] Parse master JSON error: $e');
        return [];
      }
    }
    debugPrint('[Drive] Download error: ${response.statusCode}');
    return [];
  }

  /// Upload data ternak ke file master JSON di Drive (create atau update).
  /// [pendingRecords] adalah record baru/diubah dari lokal.
  /// Fungsi ini merge dengan data existing di Drive agar tidak overwrite data lain.
  Future<bool> uploadMaster({
    required String accessToken,
    required List<Livestock> pendingRecords,
  }) async {
    // 1. Unduh data existing dari Drive
    final existing = await downloadMaster(accessToken);

    // 2. Merge: data pending menimpa record dengan id yang sama
    final Map<String, Livestock> merged = {
      for (final e in existing) e.id: e,
    };
    for (final record in pendingRecords) {
      merged[record.id] = record.copyWith(statusSync: SyncStatus.synced);
    }

    final jsonBody = jsonEncode(merged.values.map((e) => e.toJson()).toList());
    final bodyBytes = utf8.encode(jsonBody);

    // 3. Cari file ID existing di Drive
    final fileId = await _getMasterFileId(accessToken);

    bool success;
    if (fileId == null) {
      // Buat file baru
      success = await _createFile(accessToken, bodyBytes);
    } else {
      // Update file yang sudah ada
      success = await _updateFile(accessToken, fileId, bodyBytes);
    }

    return success;
  }

  Future<bool> _createFile(String accessToken, List<int> body) async {
    final metadata = jsonEncode({
      'name': _masterFileName,
      'parents': ['appDataFolder'],
      'mimeType': 'application/json',
    });

    final boundary = 'semis_boundary_${DateTime.now().millisecondsSinceEpoch}';
    final multipart = '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json\r\n\r\n'
        '${utf8.decode(body)}\r\n'
        '--$boundary--';

    final uri = Uri.parse(
        '$_uploadApiBase/files?uploadType=multipart&fields=id');

    final response = await http.post(
      uri,
      headers: {
        ..._authHeaders(accessToken),
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: utf8.encode(multipart),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('[Drive] File master dibuat.');
      return true;
    }
    debugPrint('[Drive] Create error: ${response.statusCode} ${response.body}');
    return false;
  }

  Future<bool> _updateFile(
      String accessToken, String fileId, List<int> body) async {
    final uri = Uri.parse(
        '$_uploadApiBase/files/$fileId?uploadType=media');

    final response = await http.patch(
      uri,
      headers: {
        ..._authHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      debugPrint('[Drive] File master diperbarui.');
      return true;
    }
    debugPrint('[Drive] Update error: ${response.statusCode} ${response.body}');
    return false;
  }

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
      };

  /// Background refresh: unduh file master dari Drive dan upsert ke DB lokal.
  /// Record lokal yang statusnya 'synced' akan diperbarui jika Drive lebih baru.
  /// Record lokal yang 'pending' TIDAK ditimpa — local changes take priority.
  Future<bool> fetchAndRefreshLocalCache(String accessToken) async {
    debugPrint('[Drive] Memulai background refresh dari Drive...');
    final driveRecords = await downloadMaster(accessToken);

    if (driveRecords.isEmpty) {
      debugPrint('[Drive] Tidak ada data di Drive atau gagal mengunduh.');
      return false;
    }

    for (final remote in driveRecords) {
      final local = await DatabaseHelper.instance.getLivestockById(remote.id);

      if (local == null) {
        // Record baru dari Drive, simpan sebagai synced
        await DatabaseHelper.instance.insertLivestock(
          remote.copyWith(statusSync: SyncStatus.synced),
        );
      } else if (local.statusSync == SyncStatus.synced &&
          remote.updatedAt.isAfter(local.updatedAt)) {
        // Drive lebih baru dan tidak ada perubahan lokal — timpa
        await DatabaseHelper.instance.updateLivestock(
          remote.copyWith(statusSync: SyncStatus.synced),
        );
        // Setelah update dari Drive, langsung tandai synced
        await DatabaseHelper.instance.markAsSynced(remote.id);
      }
      // Jika local.statusSync == pending → abaikan, lokal lebih prioritas
    }

    debugPrint('[Drive] Refresh selesai: ${driveRecords.length} record diproses.');
    return true;
  }
}
