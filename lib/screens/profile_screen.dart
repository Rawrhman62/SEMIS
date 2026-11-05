import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun? Sesi lokal di perangkat ini akan dibersihkan.',
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, user, _) {
        final name = user?.name ?? 'Dias Ferdian';
        final email = user?.email ?? 'peternak.semis@gmail.com';
        final isOffline = user?.isOffline ?? false;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF163321),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF14532D),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFFDCFCE7),
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 43,
                              color: Color(0xFF14532D),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOffline
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFBBF7D0),
                        borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 22),
              const _ProfileOption(
                icon: Icons.person_outline,
                title: 'Informasi akun',
              ),
              const _ProfileOption(
                icon: Icons.cloud_done_outlined,
                title: 'Status Sinkronisasi Drive',
              ),
              const _ProfileOption(
                icon: Icons.notifications_none,
                title: 'Notifikasi',
              ),
              const _ProfileOption(
                icon: Icons.help_outline,
                title: 'Bantuan',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.all(15),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'SEMIS • Versi 1.0.0',
                  style: TextStyle(color: Color(0xFF829087), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  const _ProfileOption({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4ECE4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(icon, color: const Color(0xFF14532D)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF829087)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title dikelola via Google & Local Storage.')),
            ),
          ),
        ),
      );
}
