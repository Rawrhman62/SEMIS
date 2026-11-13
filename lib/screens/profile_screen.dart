import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../models/records.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun? Sesi lokal di perangkat ini akan dibersihkan.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onLogin: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                );
              },
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  void _showAccountInfo(BuildContext context, AuthUser? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Informasi Akun Pengguna', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
            const SizedBox(height: 16),
            _infoRow('Nama Lengkap', user?.name ?? 'Dias Ferdian (Admin)'),
            _infoRow('Email Terdaftar', user?.email ?? 'peternak.semis@gmail.com'),
            _infoRow('ID Akun', user?.id ?? 'USR-DEMO-01'),
            _infoRow('Waktu Login', user != null ? '${user.loggedInAt.day}/${user.loggedInAt.month}/${user.loggedInAt.year} ${user.loggedInAt.hour}:${user.loggedInAt.minute.toString().padLeft(2,'0')}' : '-'),
            _infoRow('Izin Google Drive', (user?.hasDriveScope ?? true) ? 'Tersedia (Granted)' : 'Belum diizinkan'),
            _infoRow('Mode Sesi', (user?.isOffline ?? false) ? 'Offline Cache' : 'Online OAuth 2.0'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF14532D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: DatabaseHelper.instance.getPendingSync(),
        builder: (ctx, snapshot) {
          final pending = snapshot.data ?? [];
          final isOnline = AuthService.instance.isOnlineNotifier.value;
          final lastSync = SyncService.instance.lastSyncedAt.value;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.cloud_sync_rounded, color: Color(0xFF14532D)),
                SizedBox(width: 10),
                Text('Status Sinkronisasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Status Jaringan', isOnline ? 'Terhubung (Online)' : 'Terputus (Offline)'),
                _infoRow('Data Menunggu Sync', '${pending.length} perubahan'),
                _infoRow('Terakhir Sync', lastSync != null ? '${lastSync.hour.toString().padLeft(2,'0')}:${lastSync.minute.toString().padLeft(2,'0')} WIB' : 'Belum pernah'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'Perubahan data saat offline disimpan lokal di SQLite dan otomatis diunggah ke Google Drive saat perangkat online.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF14532D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Sekarang'),
                onPressed: () {
                  SyncService.instance.triggerManualSync();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proses sinkronisasi sedang berjalan...')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.manage_accounts_rounded, color: Color(0xFF14532D)),
              SizedBox(width: 10),
              Text('Kelola Akun (FR-04)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<UserAccount>>(
              future: DatabaseHelper.instance.getAllUsers(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: u.role == 'Admin' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          child: Icon(u.role == 'Admin' ? Icons.shield_rounded : Icons.person_rounded, size: 18, color: u.role == 'Admin' ? const Color(0xFFD97706) : const Color(0xFF14532D)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${u.email} • ${u.role}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'role') {
                              final newRole = u.role == 'Admin' ? 'Peternak' : 'Admin';
                              final updated = UserAccount(id: u.id, name: u.name, email: u.email, role: newRole, isActive: u.isActive);
                              await DatabaseHelper.instance.updateUser(updated);
                              setDialogState(() {});
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'role',
                              child: Text('Ubah Role ke ${u.role == 'Admin' ? 'Peternak' : 'Admin'}'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF14532D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Panduan Aplikasi SEMIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fitur Utama:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D))),
              SizedBox(height: 8),
              Text('• Beranda: Ringkasan statistik jumlah populasi, kondisi kesehatan, dan status koneksi.'),
              SizedBox(height: 6),
              Text('• Domba: Kelola identitas domba, cari/filter, rekam medis harian, dan riwayat penimbangan.'),
              SizedBox(height: 6),
              Text('• Silsilah: Visualisasi bagan pohon keturunan (Sire & Dam) dan pencatatan perkawinan.'),
              SizedBox(height: 6),
              Text('• Kandang: Pengaturan kapasitas kandang dan pemantauan rasio keterisian ternak.'),
              SizedBox(height: 6),
              Text('• Profil: Pengelolaan akun pengguna (Admin) dan kontrol sinkronisasi Google Drive.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF14532D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallMobile = screenWidth < 360;
        final hPad = isSmallMobile ? 14.0 : 20.0;

        return ValueListenableBuilder<AuthUser?>(
          valueListenable: AuthService.instance.currentUserNotifier,
          builder: (context, user, _) {
            final name = user?.name ?? 'Dias Ferdian (Admin)';
            final email = user?.email ?? 'peternak.semis@gmail.com';
            final isOffline = user?.isOffline ?? false;

            return SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                children: [
                  const Text(
                    'Profil Akun',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF163321),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 18 : 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B5A47), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14532D).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFDCFCE7),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: Color(0xFF14532D),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOffline
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOffline
                                ? 'Mode Offline (Sesi Lokal)'
                                : 'Online (Google Drive Terhubung)',
                            style: TextStyle(
                              color: isOffline
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF14532D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProfileOption(
                    icon: Icons.person_outline,
                    title: 'Informasi Akun (FR-03)',
                    subtitle: 'Detail data akun dan izin sesi',
                    onTap: () => _showAccountInfo(context, user),
                  ),
                  _ProfileOption(
                    icon: Icons.cloud_done_outlined,
                    title: 'Status Sinkronisasi Drive',
                    subtitle: 'Koneksi cloud & antrean data lokal',
                    onTap: () => _showSyncStatus(context),
                  ),
                  _ProfileOption(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Kelola Akun Pengguna (FR-04)',
                    subtitle: 'Hak akses Admin & Peternak',
                    onTap: () => _showUserManagement(context),
                  ),
                  _ProfileOption(
                    icon: Icons.help_outline,
                    title: 'Bantuan & Panduan',
                    subtitle: 'Petunjuk penggunaan fitur aplikasi',
                    onTap: () => _showHelpGuide(context),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'SEMIS • Versi 1.0.0 (Full Functional)',
                      style: TextStyle(color: Color(0xFF829087), fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4ECE4), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF14532D), size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF163321))),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF829087), size: 20),
            onTap: onTap,
          ),
        ),
      );
}
