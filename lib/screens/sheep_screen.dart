import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/livestock.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class SheepScreen extends StatefulWidget {
  const SheepScreen({super.key});

  @override
  State<SheepScreen> createState() => _SheepScreenState();
}

class _SheepScreenState extends State<SheepScreen> {
  String _query = '';
  String? _filterSpecies; // null = semua jenis
  String? _filterStatus;  // null = semua status
  List<Livestock> _livestock = [];
  bool _isLoading = true;

  static const _speciesFilterOptions = ['Domba', 'Kambing', 'Sapi', 'Kerbau', 'Babi'];
  static const _statusFilterOptions = ['Sehat', 'Sakit', 'Pantau'];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Setelah refresh selesai, reload list dari DB lokal
    SyncService.instance.isRefreshing.addListener(_onRefreshDone);
  }

  @override
  void dispose() {
    SyncService.instance.isRefreshing.removeListener(_onRefreshDone);
    super.dispose();
  }

  void _onRefreshDone() {
    // Listener dipanggil saat nilai berubah; reload saat refresh selesai (false)
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Offline Banner (AC-3) ──────────────────────────────────────────
          _OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Data Domba', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF163321))),
              const SizedBox(height: 5),
              const Text('Kelola identitas ternak', style: TextStyle(color: Color(0xFF718276))),
              const SizedBox(height: 12),
              _SyncStatusBar(),
              const SizedBox(height: 16),
              // ── Search Bar (AC-2) ──────────────────────────────────────────
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama, ID, atau jenis...',
                ),
              ),
              const SizedBox(height: 10),
              // ── Dropdown Filter (AC-2) ─────────────────────────────────────
              Row(children: [
                Expanded(child: _FilterDropdown(
                  hint: 'Semua Jenis',
                  value: _filterSpecies,
                  options: _speciesFilterOptions,
                  onChanged: (v) => setState(() => _filterSpecies = v),
                )),
                const SizedBox(width: 10),
                Expanded(child: _FilterDropdown(
                  hint: 'Semua Status',
                  value: _filterStatus,
                  options: _statusFilterOptions,
                  onChanged: (v) => setState(() => _filterStatus = v),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text('${_filtered.length} domba terdaftar', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48604E)))),
                // Indikator background refresh
                ValueListenableBuilder<bool>(
                  valueListenable: SyncService.instance.isRefreshing,
                  builder: (_, refreshing, __) => refreshing
                      ? const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const SizedBox.shrink(),
                ),
                FilledButton.icon(
                  onPressed: () => _showForm(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _LivestockCard(
                            livestock: _filtered[i],
                            onEdit: () => _showForm(context, _filtered[i]),
                            onDelete: () => _confirmDelete(context, _filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.pets_rounded, size: 56, color: Color(0xFFB0C4B8)),
      SizedBox(height: 12),
      Text('Belum ada data ternak', style: TextStyle(color: Color(0xFF718276))),
    ]),
  );

  Future<void> _showForm(BuildContext context, Livestock? existing) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LivestockForm(existing: existing),
    );
    if (result == true) await _loadData();
  }

  Future<void> _confirmDelete(BuildContext context, Livestock item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      // Coba sync jika online
      if (AuthService.instance.isOnlineNotifier.value) {
        SyncService.instance.triggerManualSync();
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data dihapus dan akan disinkronkan.')),
        );
      }
    }
  }
}

// ─── Offline Banner (US-03 AC-3) ────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isOnlineNotifier,
      builder: (_, isOnline, __) {
        if (isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF92400E),
          child: const Row(children: [
            Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode Offline — Menggunakan Data Tersimpan',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF718276))),
          style: const TextStyle(fontSize: 13, color: Color(0xFF163321)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 13)),
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
              label = 'Menyinkronkan...';
            } else if (!isOnline) {
              label = 'Mode Offline — data tersimpan lokal';
            } else if (lastSync != null) {
              final time = '${lastSync.hour.toString().padLeft(2,'0')}:${lastSync.minute.toString().padLeft(2,'0')}';
              label = 'Tersinkronkan pukul $time';
            } else {
              label = 'Online';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600)),
                if (isOnline && !isSyncing) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => SyncService.instance.triggerManualSync(),
                    child: Text('Sync sekarang', style: TextStyle(fontSize: 11, color: textColor, decoration: TextDecoration.underline)),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LivestockCard({required this.livestock, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPending = livestock.statusSync == SyncStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPending ? const Color(0xFFFFD700).withOpacity(0.6) : const Color(0xFFE4ECE4)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(17)),
            child: const Icon(Icons.pets_rounded, color: Color(0xFF14532D), size: 29),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(livestock.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 3),
            Text('${livestock.id} • ${livestock.breed}', style: const TextStyle(color: Color(0xFF718276), fontSize: 12)),
          ])),
          // Badge status sync
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(8)),
              child: const Text('pending', style: TextStyle(fontSize: 10, color: Color(0xFF856404), fontWeight: FontWeight.bold)),
            ),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Color(0xFFDC2626)))])),
            ],
          ),
        ]),
        const Divider(height: 24),
        Row(children: [
          _InfoChip(icon: Icons.wc_rounded, text: livestock.sex),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.home_work_outlined, text: livestock.pen),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.category_outlined, text: livestock.species),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Text('Kondisi', style: TextStyle(color: Color(0xFF718276), fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: livestock.healthStatus == 'Sehat' ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(livestock.healthStatus, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: livestock.healthStatus == 'Sehat' ? const Color(0xFF166534) : const Color(0xFF9A3412),
            )),
          ),
        ]),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(color: const Color(0xFFF4F8F3), borderRadius: BorderRadius.circular(11)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 14, color: const Color(0xFF55705D)),
      const SizedBox(width: 4),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF48604E)))),
    ]),
  ));
}

// ─── Form Tambah / Edit ──────────────────────────────────────────────────────

class _LivestockForm extends StatefulWidget {
  final Livestock? existing;
  const _LivestockForm({this.existing});

  @override
  State<_LivestockForm> createState() => _LivestockFormState();
}

class _LivestockFormState extends State<_LivestockForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _penCtrl;

  String _species = 'Domba';
  String _sex = 'Jantan';
  String _healthStatus = 'Sehat';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365));
  bool _isSaving = false;

  static const _speciesOptions = ['Domba', 'Kambing', 'Sapi', 'Kerbau', 'Babi'];
  static const _sexOptions = ['Jantan', 'Betina'];
  static const _statusOptions = ['Sehat', 'Sakit', 'Pantau'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _breedCtrl = TextEditingController(text: e?.breed ?? '');
    _penCtrl = TextEditingController(text: e?.pen ?? '');
    if (e != null) {
      _species = e.species;
      _sex = e.sex;
      _healthStatus = e.healthStatus;
      _birthDate = e.birthDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _breedCtrl.dispose(); _penCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final isEdit = widget.existing != null;
    final livestock = Livestock(
      id: isEdit ? widget.existing!.id : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      species: _species,
      breed: _breedCtrl.text.trim(),
      sex: _sex,
      birthDate: _birthDate,
      healthStatus: _healthStatus,
      pen: _penCtrl.text.trim(),
      statusSync: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      await DatabaseHelper.instance.updateLivestock(livestock);
    } else {
      await DatabaseHelper.instance.insertLivestock(livestock);
    }

    // Coba sync jika online
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE4ECE4), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Data Ternak' : 'Tambah Ternak Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
              const SizedBox(height: 20),

              // Nama
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Ternak', hintText: 'Contoh: Bimo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Jenis & Ras
              Row(children: [
                Expanded(child: _buildDropdown('Jenis', _speciesOptions, _species, (v) => setState(() => _species = v!))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _breedCtrl,
                  decoration: const InputDecoration(labelText: 'Ras'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ras wajib diisi' : null,
                )),
              ]),
              const SizedBox(height: 14),

              // Jenis Kelamin & Kandang
              Row(children: [
                Expanded(child: _buildDropdown('Jenis Kelamin', _sexOptions, _sex, (v) => setState(() => _sex = v!))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _penCtrl,
                  decoration: const InputDecoration(labelText: 'Kandang'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Kandang wajib diisi' : null,
                )),
              ]),
              const SizedBox(height: 14),

              // Tanggal Lahir
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF3F7F5), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF55705D)),
                    const SizedBox(width: 8),
                    Text('Tanggal Lahir: ${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF163321))),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Status Kesehatan
              _buildDropdown('Status Kesehatan', _statusOptions, _healthStatus, (v) => setState(() => _healthStatus = v!)),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Ternak'),
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
      value: value,
      decoration: InputDecoration(labelText: label),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }
}
