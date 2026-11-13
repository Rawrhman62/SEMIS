import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../models/livestock.dart';
import '../models/records.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'main_shell.dart';
import 'sheep_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Livestock> _allLivestock = [];
  List<Pen> _allPens = [];
  List<BreedingRecord> _breedingRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    SyncService.instance.isRefreshing.addListener(_onRefreshChange);
  }

  @override
  void dispose() {
    SyncService.instance.isRefreshing.removeListener(_onRefreshChange);
    super.dispose();
  }

  void _onRefreshChange() {
    if (!SyncService.instance.isRefreshing.value) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final livestock = await DatabaseHelper.instance.getAllLivestock();
    final pens = await DatabaseHelper.instance.getAllPens();
    final breeding = await DatabaseHelper.instance.getAllBreedingRecords();

    if (mounted) {
      setState(() {
        _allLivestock = livestock;
        _allPens = pens;
        _breedingRecords = breeding;
        _isLoading = false;
      });
    }
  }

  void _showNotificationDialog() {
    final pendingCount = _allLivestock.where((s) => s.statusSync == SyncStatus.pending).length;
    final sickCount = _allLivestock.where((s) => s.healthStatus != 'Sehat').length;
    final pregnantCount = _breedingRecords.where((b) => b.status == 'Bunting').length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Color(0xFF14532D)),
            SizedBox(width: 10),
            Text('Aktivitas Peternakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _notificationItem(
              Icons.pets_rounded,
              'Populasi Domba',
              'Total ${_allLivestock.length} ekor domba aktif tercatat di peternakan.',
              const Color(0xFF16A34A),
            ),
            const SizedBox(height: 12),
            _notificationItem(
              Icons.healing_rounded,
              'Pemantauan Kesehatan',
              sickCount > 0 ? '$sickCount ekor domba dalam status pantau/sakit.' : 'Semua domba dalam kondisi sehat.',
              sickCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
            ),
            const SizedBox(height: 12),
            _notificationItem(
              Icons.favorite_rounded,
              'Program Pemuliaan',
              pregnantCount > 0 ? '$pregnantCount indukan saat ini dalam kondisi bunting.' : 'Tidak ada indukan bunting saat ini.',
              const Color(0xFF2563EB),
            ),
            const SizedBox(height: 12),
            _notificationItem(
              Icons.cloud_sync_rounded,
              'Sinkronisasi Google Drive',
              pendingCount > 0 ? '$pendingCount perubahan siap disinkronkan ke Drive.' : 'Semua data telah tersinkronisasi rapi.',
              pendingCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF14532D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _notificationItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    final totalSheep = _allLivestock.length;
    final totalPens = _allPens.length;
    final now = DateTime.now();

    final adultSheep = _allLivestock.where((s) => now.difference(s.birthDate).inDays >= 365).length;
    final youngSheep = _allLivestock.where((s) => now.difference(s.birthDate).inDays < 365).length;
    final sickSheep = _allLivestock.where((s) => s.healthStatus != 'Sehat').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallMobile = screenWidth < 360;
        final horizontalPadding = isSmallMobile ? 14.0 : 20.0;

        return ValueListenableBuilder<AuthUser?>(
          valueListenable: AuthService.instance.currentUserNotifier,
          builder: (context, user, _) {
            final displayName = user != null ? user.name.split(' ').first : 'Dias';
            final isOffline = user?.isOffline ?? false;

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await SyncService.instance.triggerBackgroundRefresh();
                  await _loadDashboardData();
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
                  children: [
                    // Header Brand & Connection Bar
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: green.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: green,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Pemuliaan & Silsilah Domba',
                                style: TextStyle(fontSize: 11, color: Color(0xFF55705D), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        // Online / Offline Status Badge
                        ValueListenableBuilder<bool>(
                          valueListenable: AuthService.instance.isOnlineNotifier,
                          builder: (context, online, _) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: online ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: online ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: online ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  online ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: online ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showNotificationDialog,
                          icon: const Icon(Icons.notifications_none_rounded, color: green),
                          tooltip: 'Aktivitas & Notifikasi',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Hero Welcome Card (Gradient Forest SEMIS Theme)
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
                            color: green.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -14,
                            bottom: -28,
                            child: Icon(
                              Icons.eco_rounded,
                              size: 130,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.waving_hand_rounded, color: Color(0xFFFDE047), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Halo, $displayName!',
                                    style: const TextStyle(
                                      color: Color(0xFFBBF7D0),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isOffline ? 'Mode Offline Aktif\nSesi Lokal Siap' : 'Terhubung ke\nGoogle Drive',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallMobile ? 21 : 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => SyncService.instance.triggerManualSync(),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBBF7D0),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOffline ? Icons.storage_rounded : Icons.sync_rounded,
                                          color: green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isOffline ? 'Data tersimpan lokal' : 'Sinkronkan Sekarang',
                                          style: const TextStyle(
                                            color: green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Quick Action Buttons (Modern Pill Cards)
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionPill(
                            icon: Icons.add_circle_outline,
                            label: 'Tambah',
                            sublabel: 'Domba Baru',
                            color: green,
                            onTap: () => SheepScreen.showAddDialog(context, _loadDashboardData),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionPill(
                            icon: Icons.account_tree_outlined,
                            label: 'Silsilah',
                            sublabel: 'Garis Keturunan',
                            color: const Color(0xFF1D4ED8),
                            onTap: () => MainShell.switchTab(context, 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionPill(
                            icon: Icons.home_work_outlined,
                            label: 'Kandang',
                            sublabel: 'Kapasitas',
                            color: const Color(0xFFD97706),
                            onTap: () => MainShell.switchTab(context, 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ringkasan Populasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF163321),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalSheep Ekor',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Responsive 2-Column Grid for Metrics
                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => MainShell.switchTab(context, 1),
                              borderRadius: BorderRadius.circular(20),
                              child: _MetricCard(
                                icon: Icons.pets_rounded,
                                count: '$totalSheep',
                                title: 'Total Domba',
                                subtitle: 'Tercatat di sistem',
                                cardColor: Colors.white,
                                accentColor: green,
                                badgeColor: const Color(0xFFDCFCE7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => MainShell.switchTab(context, 3),
                              borderRadius: BorderRadius.circular(20),
                              child: _MetricCard(
                                icon: Icons.home_work_rounded,
                                count: '$totalPens',
                                title: 'Kandang Aktif',
                                subtitle: 'Blok penempatan',
                                cardColor: Colors.white,
                                accentColor: const Color(0xFF1D4ED8),
                                badgeColor: const Color(0xFFDBEAFE),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.favorite_rounded,
                              count: '$adultSheep',
                              title: 'Dewasa',
                              subtitle: 'Usia ≥ 12 bulan',
                              cardColor: Colors.white,
                              accentColor: const Color(0xFFC2410C),
                              badgeColor: const Color(0xFFFFEDD5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.child_care_rounded,
                              count: '$youngSheep',
                              title: 'Muda / Cempe',
                              subtitle: 'Usia < 12 bulan',
                              cardColor: Colors.white,
                              accentColor: const Color(0xFF7E22CE),
                              badgeColor: const Color(0xFFF3E8FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.monitor_heart_rounded,
                              count: '$sickSheep',
                              title: 'Perlu Pantau',
                              subtitle: sickSheep > 0 ? 'Perlu tindakan' : 'Semua sehat',
                              cardColor: Colors.white,
                              accentColor: sickSheep > 0 ? const Color(0xFFB91C1C) : const Color(0xFF16A34A),
                              badgeColor: sickSheep > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Recent Sheep Header & List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Domba Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF163321),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => MainShell.switchTab(context, 1),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (_allLivestock.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE4ECE4)),
                        ),
                        child: const Center(
                          child: Text('Belum ada data domba terdaftar.', style: TextStyle(color: Color(0xFF718276))),
                        ),
                      )
                    else
                      ..._allLivestock.take(4).map(
                            (sheep) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SheepCompactRow(
                                sheep: sheep,
                                onTap: () => MainShell.switchTab(context, 1),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color accentColor;
  final Color badgeColor;

  const _MetricCard({
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.accentColor,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE4), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF163321),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF163321),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF718276),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE4ECE4), width: 0.9),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163321),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF718276),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheepCompactRow extends StatelessWidget {
  final Livestock sheep;
  final VoidCallback onTap;

  const _SheepCompactRow({required this.sheep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);
    final isHealthy = sheep.healthStatus == 'Sehat';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE4ECE4), width: 0.9),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.pets, color: green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sheep.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF163321),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sheep.id,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${sheep.breed} • ${sheep.pen}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF718276), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isHealthy ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isHealthy ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sheep.healthStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
