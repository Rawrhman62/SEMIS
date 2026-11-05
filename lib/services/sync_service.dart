import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'drive_service.dart';

/// Mengelola background sync: unggah data pending ke Google Drive saat online (US-02 AC-3).
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier(null);
  final ValueNotifier<String?> syncError = ValueNotifier(null);
  final ValueNotifier<bool> isRefreshing = ValueNotifier(false);

  StreamSubscription<bool>? _connectivitySub;
  bool _isInitialized = false;

  /// Mulai listening perubahan koneksi. Panggil sekali dari main.dart.
  void initialize() {
    if (_isInitialized) return;

    // Dengarkan perubahan status online dari AuthService
    AuthService.instance.isOnlineNotifier.addListener(_onConnectivityChanged);
    _isInitialized = true;
    debugPrint('[Sync] SyncService initialized.');

    // Jika saat init sudah online, langsung coba sync
    if (AuthService.instance.isOnlineNotifier.value) {
      _triggerSync();
      triggerBackgroundRefresh();
    }
  }

  void _onConnectivityChanged() {
    final isOnline = AuthService.instance.isOnlineNotifier.value;
    if (isOnline) {
      debugPrint('[Sync] Koneksi tersedia, memulai background sync...');
      _triggerSync();
      triggerBackgroundRefresh();
    }
  }

  /// Trigger sync manual (bisa dipanggil dari UI juga).
  Future<void> triggerManualSync() => _triggerSync();

  /// Background refresh: tarik data terbaru dari Drive ke local DB.
  Future<void> triggerBackgroundRefresh() async {
    if (isRefreshing.value) return;
    final user = AuthService.instance.currentUserNotifier.value;
    if (user == null || user.accessToken == null) return;

    isRefreshing.value = true;
    debugPrint('[Sync] Background refresh dimulai...');
    try {
      await DriveService.instance.fetchAndRefreshLocalCache(user.accessToken!);
    } catch (e) {
      debugPrint('[Sync] Background refresh error: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _triggerSync() async {
    // Hindari sync ganda yang berjalan bersamaan
    if (isSyncing.value) return;

    final user = AuthService.instance.currentUserNotifier.value;
    if (user == null || user.accessToken == null) {
      debugPrint('[Sync] Tidak ada sesi aktif, skip sync.');
      return;
    }

    final pendingItems = await DatabaseHelper.instance.getPendingSync();
    if (pendingItems.isEmpty) {
      debugPrint('[Sync] Tidak ada data pending, skip sync.');
      return;
    }

    isSyncing.value = true;
    syncError.value = null;
    debugPrint('[Sync] Mengunggah ${pendingItems.length} record ke Drive...');

    try {
      final success = await DriveService.instance.uploadMaster(
        accessToken: user.accessToken!,
        pendingRecords: pendingItems,
      );

      if (success) {
        // Tandai semua yang berhasil diunggah sebagai 'synced'
        for (final item in pendingItems) {
          await DatabaseHelper.instance.markAsSynced(item.id);
        }
        lastSyncedAt.value = DateTime.now();
        debugPrint('[Sync] Sync selesai. ${pendingItems.length} record synced.');
      } else {
        syncError.value = 'Gagal mengunggah data ke Google Drive.';
        debugPrint('[Sync] Upload gagal.');
      }
    } catch (e) {
      syncError.value = 'Error sinkronisasi: $e';
      debugPrint('[Sync] Error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    AuthService.instance.isOnlineNotifier.removeListener(_onConnectivityChanged);
    isSyncing.dispose();
    lastSyncedAt.dispose();
    syncError.dispose();
    isRefreshing.dispose();
    _isInitialized = false;
  }
}
