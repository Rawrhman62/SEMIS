import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, user, _) {
        final displayName = user != null
            ? user.name.split(' ').first
            : 'Dias';
        final isOffline = user?.isOffline ?? false;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset('assets/icon_small.jpeg', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEMIS',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: green,
                          ),
                        ),
                        Text(
                          'Sistem pemuliaan domba',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718276),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connection Badge
                  ValueListenableBuilder<bool>(
                    valueListenable: AuthService.instance.isOnlineNotifier,
                    builder: (context, online, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: online
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              online
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              size: 14,
                              color: online
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              online ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: online
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Belum ada notifikasi baru.')),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14532D), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8,
                      bottom: -24,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 125,
                        color: Colors.white.withValues(alpha: .10),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $displayName! 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOffline
                              ? 'Mode Offline Aktif\nSesi Lokal'
                              : 'Terhubung ke\nGoogle Drive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOffline
                                    ? Icons.storage_rounded
                                    : Icons.sync_rounded,
                                color: green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOffline
                                    ? 'Data tersimpan di Secure Storage'
                                    : 'Sinkronisasi Cloud Aktif',
                                style: const TextStyle(
                                  color: green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163321),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pets_rounded,
                      number: '${sampleSheep.length}',
                      label: 'Total domba',
                      color: const Color(0xFFDCFCE7),
                      iconColor: green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatCard(
                      icon: Icons.home_work_rounded,
                      number: '3',
                      label: 'Kandang',
                      color: Color(0xFFDBEAFE),
                      iconColor: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      number: '3',
                      label: 'Domba dewasa',
                      color: Color(0xFFFFEDD5),
                      iconColor: Color(0xFFC2410C),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.monitor_heart_rounded,
                      number: '1',
                      label: 'Domba muda',
                      color: Color(0xFFFEE2E2),
                      iconColor: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Domba terbaru',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF163321),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              ...sampleSheep.take(2).map(
                    (sheep) => _SheepRow(
                      name: sheep.name,
                      id: sheep.id,
                      breed: sheep.breed,
                      status: sheep.status,
                    ),
                  ),
              const SizedBox(height: 10),
              const Text(
                'Akses cepat',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163321),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'Tambah domba',
                      color: green,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Form tambah domba dapat dikembangkan berikutnya.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.account_tree_outlined,
                      label: 'Silsilah',
                      color: const Color(0xFF1D4ED8),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Buka menu Silsilah pada navigasi bawah.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number, label;
  final Color color, iconColor;
  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EEE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 13),
            Text(
              number,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF163321),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF718276)),
            ),
          ],
        ),
      );
}

class _SheepRow extends StatelessWidget {
  final String name, id, breed, status;
  const _SheepRow({
    required this.name,
    required this.id,
    required this.breed,
    required this.status,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EEE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xFF14532D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$id • $breed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718276),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'Sehat'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: status == 'Sehat'
                      ? const Color(0xFF166534)
                      : const Color(0xFF9A3412),
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF24392B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
