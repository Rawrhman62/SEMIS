import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF163321))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: const Color(0xFF14532D), borderRadius: BorderRadius.circular(24)),
            child: const Column(children: [
              CircleAvatar(radius: 38, backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.person_rounded, size: 43, color: Color(0xFF14532D))),
              SizedBox(height: 12),
              Text('Dias Ferdian', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Peternak • Pengguna SEMIS', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 22),
          const _ProfileOption(icon: Icons.person_outline, title: 'Informasi akun'),
          const _ProfileOption(icon: Icons.notifications_none, title: 'Notifikasi'),
          const _ProfileOption(icon: Icons.help_outline, title: 'Bantuan'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo: fungsi keluar dapat dihubungkan ke autentikasi.')),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB91C1C), padding: const EdgeInsets.all(15), side: const BorderSide(color: Color(0xFFFECACA))),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('SEMIS • Versi 1.0.0', style: TextStyle(color: Color(0xFF829087), fontSize: 12))),
        ],
      ),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4ECE4))),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF14532D)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF829087)),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title belum diaktifkan pada versi demo.'))),
    ),
  );
}
