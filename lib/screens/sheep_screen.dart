import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/livestock.dart';
import '../models/records.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class SheepScreen extends StatefulWidget {
  const SheepScreen({super.key});

  static Future<void> showAddDialog(BuildContext context, [VoidCallback? onSaved]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LivestockForm(),
    );
    if (result == true) {
      onSaved?.call();
    }
  }

  @override
  State<SheepScreen> createState() => _SheepScreenState();
}

class _SheepScreenState extends State<SheepScreen> {
  String _query = '';
  String? _filterSpecies;
  String? _filterStatus;
  List<Livestock> _livestock = [];
  bool _isLoading = true;

  static const _speciesFilterOptions = ['Domba', 'Kambing', 'Sapi', 'Kerbau'];
  static const _statusFilterOptions = ['Sehat', 'Sakit', 'Pantau'];

  @override
  void initState() {
    super.initState();
    _loadData();
    SyncService.instance.isRefreshing.addListener(_onRefreshDone);
  }

  @override
  void dispose() {
    SyncService.instance.isRefreshing.removeListener(_onRefreshDone);
    super.dispose();
  }

  void _onRefreshDone() {
    if (!SyncService.instance.isRefreshing.value) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllLivestock();
    if (mounted) setState(() { _livestock = data; _isLoading = false; });
  }

  List<Livestock> get _filtered => _livestock.where((s) {
    final q = _query.toLowerCase();
    final matchQuery = q.isEmpty ||
        s.name.toLowerCase().contains(q) ||
        s.id.toLowerCase().contains(q) ||
        s.species.toLowerCase().contains(q) ||
        s.breed.toLowerCase().contains(q);
    final matchSpecies = _filterSpecies == null || s.species == _filterSpecies;
    final matchStatus = _filterStatus == null || s.healthStatus == _filterStatus;
    return matchQuery && matchSpecies && matchStatus;
  }).toList();

  Future<void> _showForm([Livestock? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LivestockForm(existing: existing, allLivestock: _livestock),
    );
    if (result == true) await _loadData();
  }

  Future<void> _showDetail(Livestock item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LivestockDetailSheet(
        livestock: item,
        allLivestock: _livestock,
        onEdit: () {
          Navigator.pop(context);
          _showForm(item);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, item);
        },
        onDataChanged: _loadData,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Livestock item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Ternak'),
        content: Text('Hapus "${item.name}" (${item.id})? Data tidak akan hilang permanen dan akan disinkronkan ke Drive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.softDeleteLivestock(item.id);
      if (AuthService.instance.isOnlineNotifier.value) {
        SyncService.instance.triggerManualSync();
      }
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data dihapus dan ditandai sinkronisasi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallMobile = screenWidth < 360;
        final hPad = isSmallMobile ? 14.0 : 20.0;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OfflineBanner(),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Domba',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF163321),
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Katalog & status rekam medis',
                              style: TextStyle(color: Color(0xFF718276), fontSize: 12),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: () => _showForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF14532D),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SyncStatusBar(),
                    const SizedBox(height: 14),
                    // Search Bar
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF14532D)),
                        hintText: 'Cari nama, ID, atau ras domba...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE4ECE4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dropdown Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            hint: 'Semua Jenis',
                            value: _filterSpecies,
                            options: _speciesFilterOptions,
                            onChanged: (v) => setState(() => _filterSpecies = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterDropdown(
                            hint: 'Semua Status',
                            value: _filterStatus,
                            options: _statusFilterOptions,
                            onChanged: (v) => setState(() => _filterStatus = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${_filtered.length} ekor terdaftar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF48604E)),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<bool>(
                          valueListenable: SyncService.instance.isRefreshing,
                          builder: (_, refreshing, __) => refreshing
                              ? const Row(
                                  children: [
                                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 6),
                                    Text('Memperbarui...', style: TextStyle(fontSize: 11, color: Color(0xFF718276))),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async {
                              await SyncService.instance.triggerBackgroundRefresh();
                              await _loadData();
                            },
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _LivestockCard(
                                livestock: _filtered[i],
                                onTap: () => _showDetail(_filtered[i]),
                                onEdit: () => _showForm(_filtered[i]),
                                onDelete: () => _confirmDelete(context, _filtered[i]),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.pets_rounded, size: 36, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),
              const Text('Tidak ada domba yang cocok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155))),
              const SizedBox(height: 4),
              const Text('Coba reset filter atau gunakan kata kunci lain.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ),
      );
}

// ─── Offline Banner ─────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isOnlineNotifier,
      builder: (_, isOnline, __) {
        if (isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF92400E),
          child: const Row(children: [
            Icon(Icons.cloud_off_rounded, size: 15, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode Offline — Data tersimpan di SQLite lokal',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── Filter Dropdown ─────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final void Function(String?) onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECE4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: Color(0xFF718276))),
          style: const TextStyle(fontSize: 12, color: Color(0xFF163321), fontWeight: FontWeight.w600),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 12)),
            ),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Sync Status Bar ────────────────────────────────────────────────────────

class _SyncStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isOnlineNotifier,
      builder: (_, isOnline, __) => ValueListenableBuilder<bool>(
        valueListenable: SyncService.instance.isSyncing,
        builder: (_, isSyncing, __) => ValueListenableBuilder<DateTime?>(
          valueListenable: SyncService.instance.lastSyncedAt,
          builder: (_, lastSync, __) {
            final bgColor = isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFFF3CD);
            final textColor = isOnline ? const Color(0xFF166534) : const Color(0xFF856404);
            final icon = isSyncing
                ? Icons.sync_rounded
                : isOnline
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded;

            String label;
            if (isSyncing) {
              label = 'Menyinkronkan ke Google Drive...';
            } else if (!isOnline) {
              label = 'Mode Offline — Data tersimpan aman lokal';
            } else if (lastSync != null) {
              final time = '${lastSync.hour.toString().padLeft(2,'0')}:${lastSync.minute.toString().padLeft(2,'0')}';
              label = 'Tersinkronkan pukul $time WIB';
            } else {
              label = 'Online — Google Drive Terhubung';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(icon, size: 15, color: textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isOnline && !isSyncing) ...[
                  GestureDetector(
                    onTap: () => SyncService.instance.triggerManualSync(),
                    child: Text('Sync', style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ]
              ]),
            );
          },
        ),
      ),
    );
  }
}

// ─── Livestock Card ──────────────────────────────────────────────────────────

class _LivestockCard extends StatelessWidget {
  final Livestock livestock;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LivestockCard({
    required this.livestock,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = livestock.statusSync == SyncStatus.pending;
    final isHealthy = livestock.healthStatus == 'Sehat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? const Color(0xFFFFD700).withValues(alpha: 0.6) : const Color(0xFFE4ECE4),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.pets_rounded, color: Color(0xFF14532D), size: 24),
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
                                  livestock.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF163321)),
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
                                  livestock.id,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${livestock.breed} (${livestock.species})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF718276), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isPending)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(8)),
                        child: const Text('pending', style: TextStyle(fontSize: 10, color: Color(0xFF856404), fontWeight: FontWeight.bold)),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'detail') {
                          onTap();
                        } else if (v == 'edit') {
                          onEdit();
                        } else if (v == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Lihat Detail')])),
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Color(0xFFDC2626)))])),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  children: [
                    _InfoChip(icon: Icons.wc_rounded, text: livestock.sex),
                    const SizedBox(width: 6),
                    _InfoChip(icon: Icons.home_work_outlined, text: livestock.pen),
                    const SizedBox(width: 6),
                    _InfoChip(icon: Icons.monitor_weight_outlined, text: livestock.weight != null ? '${livestock.weight} kg' : '- kg'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isHealthy ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        livestock.healthStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isHealthy ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF6FAF7), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: const Color(0xFF55705D)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF48604E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Detail Sheet with Health & Growth Tracking (FR-09 & FR-10) ─────────────

class _LivestockDetailSheet extends StatefulWidget {
  final Livestock livestock;
  final List<Livestock> allLivestock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDataChanged;

  const _LivestockDetailSheet({
    required this.livestock,
    required this.allLivestock,
    required this.onEdit,
    required this.onDelete,
    required this.onDataChanged,
  });

  @override
  State<_LivestockDetailSheet> createState() => _LivestockDetailSheetState();
}

class _LivestockDetailSheetState extends State<_LivestockDetailSheet> {
  List<HealthRecord> _healthRecords = [];
  List<GrowthRecord> _growthRecords = [];
  bool _isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final health = await DatabaseHelper.instance.getHealthRecords(widget.livestock.id);
    final growth = await DatabaseHelper.instance.getGrowthRecords(widget.livestock.id);
    if (mounted) {
      setState(() {
        _healthRecords = health;
        _growthRecords = growth;
        _isLoadingRecords = false;
      });
    }
  }

  void _showAddHealthDialog() {
    final diagCtrl = TextEditingController();
    final treatCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String condition = 'Sehat';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Catat Pemeriksaan Kesehatan (FR-09)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: const InputDecoration(labelText: 'Status / Kondisi'),
                  items: const [
                    DropdownMenuItem(value: 'Sehat', child: Text('Sehat')),
                    DropdownMenuItem(value: 'Pantau', child: Text('Pantau (Lesu/Observasi)')),
                    DropdownMenuItem(value: 'Sakit', child: Text('Sakit (Butuh Penanganan)')),
                  ],
                  onChanged: (v) => setDialogState(() => condition = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: diagCtrl, decoration: const InputDecoration(labelText: 'Diagnosis / Gejala *', hintText: 'misal: Nafsu makan menurun')),
                const SizedBox(height: 12),
                TextField(controller: treatCtrl, decoration: const InputDecoration(labelText: 'Tindakan / Obat *', hintText: 'misal: Vitamin B & obat cacing')),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
              onPressed: () async {
                if (diagCtrl.text.trim().isEmpty) return;
                final rec = HealthRecord(
                  id: 'HLT-${const Uuid().v4().substring(0, 6).toUpperCase()}',
                  livestockId: widget.livestock.id,
                  date: DateTime.now(),
                  condition: condition,
                  diagnosis: diagCtrl.text.trim(),
                  treatment: treatCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                );
                await DatabaseHelper.instance.insertHealthRecord(rec);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadRecords();
                widget.onDataChanged();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGrowthDialog() {
    final weightCtrl = TextEditingController(text: widget.livestock.weight?.toString() ?? '');
    final heightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Catat Penimbangan & Bobot (FR-10)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Bobot Badan (kg) *', hintText: 'misal: 45.5'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tinggi Pundak (cm)', hintText: 'misal: 62'),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan Pertumbuhan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
            onPressed: () async {
              final w = double.tryParse(weightCtrl.text.trim());
              if (w == null || w <= 0) return;
              final rec = GrowthRecord(
                id: 'GRW-${const Uuid().v4().substring(0, 6).toUpperCase()}',
                livestockId: widget.livestock.id,
                date: DateTime.now(),
                weight: w,
                height: double.tryParse(heightCtrl.text.trim()),
                notes: notesCtrl.text.trim(),
              );
              await DatabaseHelper.instance.insertGrowthRecord(rec);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadRecords();
              widget.onDataChanged();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.livestock;
    final sire = widget.allLivestock.where((s) => s.id == l.sireId).firstOrNull;
    final dam = widget.allLivestock.where((s) => s.id == l.damId).firstOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF163321))),
                      Text('${l.id} • ${l.breed} (${l.species})', style: const TextStyle(color: Color(0xFF718276), fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: widget.onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)), onPressed: widget.onDelete),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  _detailRow('Jenis Kelamin', l.sex),
                  _detailRow('Kandang', l.pen),
                  _detailRow('Bobot Terkini', l.weight != null ? '${l.weight} kg' : 'Belum tercatat'),
                  _detailRow('Status Kesehatan', l.healthStatus),
                  _detailRow('Ayah (Sire)', sire != null ? '${sire.name} (${sire.id})' : (l.sireId ?? 'Tidak diketahui')),
                  _detailRow('Ibu (Dam)', dam != null ? '${dam.name} (${dam.id})' : (l.damId ?? 'Tidak diketahui')),
                  if (l.notes != null && l.notes!.isNotEmpty) _detailRow('Catatan', l.notes!),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Rekam Medis (FR-09)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rekam Medis Kesehatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
                TextButton.icon(
                  onPressed: _showAddHealthDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Catat Sakit'),
                ),
              ],
            ),
            if (_isLoadingRecords)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_healthRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada riwayat pemeriksaan kesehatan.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              )
            else
              ..._healthRecords.map((h) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        h.condition == 'Sehat' ? Icons.check_circle_outline : Icons.healing_outlined,
                        color: h.condition == 'Sehat' ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                      ),
                      title: Text('${h.diagnosis} • ${h.condition}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Tindakan: ${h.treatment}\nTanggal: ${h.date.day}/${h.date.month}/${h.date.year}', style: const TextStyle(fontSize: 11)),
                    ),
                  )),

            const SizedBox(height: 20),

            // Tab Pertumbuhan (FR-10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Penimbangan (FR-10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
                TextButton.icon(
                  onPressed: _showAddGrowthDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Timbang'),
                ),
              ],
            ),
            if (_growthRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada data penimbangan berkala.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              )
            else
              ..._growthRecords.map((g) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF1D4ED8)),
                      title: Text('${g.weight} kg ${g.height != null ? '• TB: ${g.height} cm' : ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${g.notes.isNotEmpty ? '${g.notes} • ' : ''}Tanggal: ${g.date.day}/${g.date.month}/${g.date.year}', style: const TextStyle(fontSize: 11)),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)))),
          ],
        ),
      );
}

// ─── Form Tambah / Edit ──────────────────────────────────────────────────────

class _LivestockForm extends StatefulWidget {
  final Livestock? existing;
  final List<Livestock>? allLivestock;
  const _LivestockForm({this.existing, this.allLivestock});

  @override
  State<_LivestockForm> createState() => _LivestockFormState();
}

class _LivestockFormState extends State<_LivestockForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _notesCtrl;

  String _species = 'Domba';
  String _sex = 'Jantan';
  String _healthStatus = 'Sehat';
  String _selectedPen = 'Kandang A';
  String? _selectedSireId;
  String? _selectedDamId;
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365));
  bool _isSaving = false;
  List<Pen> _availablePens = [];

  static const _speciesOptions = ['Domba', 'Kambing', 'Sapi', 'Kerbau'];
  static const _sexOptions = ['Jantan', 'Betina'];
  static const _statusOptions = ['Sehat', 'Sakit', 'Pantau'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _idCtrl = TextEditingController(text: e?.id ?? 'SM-${const Uuid().v4().substring(0, 4).toUpperCase()}');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _breedCtrl = TextEditingController(text: e?.breed ?? 'Domba Garut');
    _weightCtrl = TextEditingController(text: e?.weight?.toString() ?? '35.0');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _species = e.species;
      _sex = e.sex;
      _healthStatus = e.healthStatus;
      _birthDate = e.birthDate;
      _selectedPen = e.pen;
      _selectedSireId = e.sireId;
      _selectedDamId = e.damId;
    }
    _loadPens();
  }

  Future<void> _loadPens() async {
    final pens = await DatabaseHelper.instance.getAllPens();
    if (mounted) {
      setState(() {
        _availablePens = pens;
        if (pens.isNotEmpty && !_availablePens.any((p) => p.name == _selectedPen)) {
          _selectedPen = pens.first.name;
        }
      });
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final isEdit = widget.existing != null;
    final livestock = Livestock(
      id: _idCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      species: _species,
      breed: _breedCtrl.text.trim(),
      sex: _sex,
      birthDate: _birthDate,
      healthStatus: _healthStatus,
      pen: _selectedPen,
      weight: double.tryParse(_weightCtrl.text.trim()),
      sireId: _selectedSireId,
      damId: _selectedDamId,
      notes: _notesCtrl.text.trim(),
      statusSync: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      await DatabaseHelper.instance.updateLivestock(livestock);
    } else {
      await DatabaseHelper.instance.insertLivestock(livestock);
    }

    if (AuthService.instance.isOnlineNotifier.value) {
      SyncService.instance.triggerManualSync();
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final all = widget.allLivestock ?? [];
    final maleOptions = all.where((s) => s.sex == 'Jantan' && s.id != widget.existing?.id).toList();
    final femaleOptions = all.where((s) => s.sex == 'Betina' && s.id != widget.existing?.id).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Data Domba' : 'Tambah Domba Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
              const SizedBox(height: 18),

              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(labelText: 'Tag / ID *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Domba *', hintText: 'misal: Bimo'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _buildDropdown('Jenis', _speciesOptions, _species, (v) => setState(() => _species = v!))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(
                  controller: _breedCtrl,
                  decoration: const InputDecoration(labelText: 'Ras', hintText: 'Domba Garut'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ras wajib' : null,
                )),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _buildDropdown('Jenis Kelamin', _sexOptions, _sex, (v) => setState(() => _sex = v!))),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPen,
                    decoration: const InputDecoration(labelText: 'Kandang'),
                    items: (_availablePens.isEmpty
                            ? ['Kandang A', 'Kandang B', 'Kandang C']
                            : _availablePens.map((p) => p.name).toList())
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPen = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Bobot (kg)', hintText: '40.5'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown('Status', _statusOptions, _healthStatus, (v) => setState(() => _healthStatus = v!)),
                ),
              ]),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF3F7F5), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF14532D)),
                    const SizedBox(width: 8),
                    Text('Tanggal Lahir: ${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF163321), fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedSireId,
                    decoration: const InputDecoration(labelText: 'Ayah (Sire)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tidak Ada')),
                      ...maleOptions.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.id})', overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _selectedSireId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedDamId,
                    decoration: const InputDecoration(labelText: 'Ibu (Dam)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tidak Ada')),
                      ...femaleOptions.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.id})', overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _selectedDamId = v),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan Khusus'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF14532D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Ternak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }
}
