import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/livestock.dart';
import '../models/records.dart';
import '../services/database_helper.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  List<Livestock> _allSheep = [];
  List<BreedingRecord> _breedingRecords = [];
  Livestock? _selectedSheep;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sheep = await DatabaseHelper.instance.getAllLivestock();
    final records = await DatabaseHelper.instance.getAllBreedingRecords();

    Livestock? current;
    if (sheep.isNotEmpty) {
      if (_selectedSheep != null && sheep.any((s) => s.id == _selectedSheep!.id)) {
        current = sheep.firstWhere((s) => s.id == _selectedSheep!.id);
      } else {
        current = sheep.where((s) => s.sireId != null || s.damId != null).firstOrNull ?? sheep.first;
      }
    }

    if (mounted) {
      setState(() {
        _allSheep = sheep;
        _breedingRecords = records;
        _selectedSheep = current;
        _isLoading = false;
      });
    }
  }

  void _showAddBreedingDialog() {
    final males = _allSheep.where((s) => s.sex == 'Jantan').toList();
    final females = _allSheep.where((s) => s.sex == 'Betina').toList();

    if (males.isEmpty || females.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibutuhkan minimal 1 pejantan dan 1 betina untuk mencatat perkawinan.')),
      );
      return;
    }

    String selectedSire = males.first.id;
    String selectedDam = females.first.id;
    DateTime matingDate = DateTime.now();
    DateTime expectedBirth = matingDate.add(const Duration(days: 150));
    String status = 'Kawin';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Catat Perkawinan Domba (FR-13)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSire,
                  decoration: const InputDecoration(labelText: 'Pejantan (Sire) *'),
                  items: males.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.id})', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedSire = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDam,
                  decoration: const InputDecoration(labelText: 'Induk Betina (Dam) *'),
                  items: females.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.name} (${f.id})', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedDam = v!),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF3F7F5), borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: matingDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          matingDate = picked;
                          expectedBirth = picked.add(const Duration(days: 150));
                        });
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: Color(0xFF14532D), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal Kawin: ${matingDate.day}/${matingDate.month}/${matingDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Estimasi Lahir: ${expectedBirth.day}/${expectedBirth.month}/${expectedBirth.year}', style: const TextStyle(fontSize: 11, color: Color(0xFF718276))),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar_outlined, size: 18, color: Color(0xFF14532D)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status Pemuliaan'),
                  items: const [
                    DropdownMenuItem(value: 'Kawin', child: Text('Kawin (Baru Saja)')),
                    DropdownMenuItem(value: 'Bunting', child: Text('Bunting (Terkonfirmasi)')),
                    DropdownMenuItem(value: 'Melahirkan', child: Text('Melahirkan')),
                    DropdownMenuItem(value: 'Gagal', child: Text('Gagal / Tidak Bunting')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF14532D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final rec = BreedingRecord(
                  id: 'BRD-${const Uuid().v4().substring(0, 6).toUpperCase()}',
                  sireId: selectedSire,
                  damId: selectedDam,
                  matingDate: matingDate,
                  expectedBirthDate: expectedBirth,
                  status: status,
                  notes: notesCtrl.text.trim(),
                );
                await DatabaseHelper.instance.insertBreedingRecord(rec);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLineageDialog(Livestock sheep) {
    final males = _allSheep.where((s) => s.sex == 'Jantan' && s.id != sheep.id).toList();
    final females = _allSheep.where((s) => s.sex == 'Betina' && s.id != sheep.id).toList();

    String? sireId = sheep.sireId;
    String? damId = sheep.damId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Atur Silsilah: ${sheep.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: sireId,
                decoration: const InputDecoration(labelText: 'Pilih Ayah (Sire)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tidak Diketahui / Bebas')),
                  ...males.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.id})', style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => setDialogState(() => sireId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: damId,
                decoration: const InputDecoration(labelText: 'Pilih Ibu (Dam)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tidak Diketahui / Bebas')),
                  ...females.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.name} (${f.id})', style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => setDialogState(() => damId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF14532D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final updated = sheep.copyWith(sireId: sireId, damId: damId);
                await DatabaseHelper.instance.updateLivestock(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sheep = _selectedSheep;
    final sire = sheep != null ? _allSheep.where((s) => s.id == sheep.sireId).firstOrNull : null;
    final dam = sheep != null ? _allSheep.where((s) => s.id == sheep.damId).firstOrNull : null;

    final paternalGrandsire = sire != null ? _allSheep.where((s) => s.id == sire.sireId).firstOrNull : null;
    final paternalGranddam = sire != null ? _allSheep.where((s) => s.id == sire.damId).firstOrNull : null;

    final children = sheep != null
        ? _allSheep.where((s) => s.sireId == sheep.id || s.damId == sheep.id).toList()
        : <Livestock>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallMobile = screenWidth < 360;
        final hPad = isSmallMobile ? 14.0 : 20.0;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
              children: [
                const Text(
                  'Silsilah & Pemuliaan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF163321), letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                const Text('Garis keturunan dan catatan perkawinan ternak', style: TextStyle(color: Color(0xFF718276), fontSize: 12)),
                const SizedBox(height: 18),

                // Selector Domba Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4ECE4)),
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
                      const Row(
                        children: [
                          Icon(Icons.search_rounded, color: green, size: 18),
                          SizedBox(width: 8),
                          Text('Pilih Domba untuk Ditelusuri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF163321))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FAF7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4ECE4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSheep?.id,
                            isExpanded: true,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF163321)),
                            items: _allSheep.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.id} • ${s.sex})'))).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                setState(() {
                                  _selectedSheep = _allSheep.firstWhere((s) => s.id == id);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Bagan Silsilah
                if (sheep != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pohon Silsilah (Pedigree)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
                      TextButton.icon(
                        onPressed: () => _showEditLineageDialog(sheep),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Atur Induk', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Kartu Domba Fokus (Anak)
                  _LineageHeroCard(
                    name: sheep.name,
                    id: sheep.id,
                    role: 'Domba Fokus (${sheep.sex})',
                    breed: sheep.breed,
                    pen: sheep.pen,
                  ),

                  // Connector Stem
                  Center(
                    child: Container(
                      width: 2,
                      height: 18,
                      color: const Color(0xFF86EFAC),
                    ),
                  ),

                  // Ayah & Ibu
                  Row(
                    children: [
                      Expanded(
                        child: _ParentBox(
                          name: sire?.name ?? (sheep.sireId ?? 'Tidak Diketahui'),
                          role: 'Ayah (Sire ♂)',
                          breed: sire?.breed,
                          color: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFFBFDBFE),
                          iconColor: const Color(0xFF1D4ED8),
                          isKnown: sire != null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ParentBox(
                          name: dam?.name ?? (sheep.damId ?? 'Tidak Diketahui'),
                          role: 'Ibu (Dam ♀)',
                          breed: dam?.breed,
                          color: const Color(0xFFFFF1F2),
                          borderColor: const Color(0xFFFECDD3),
                          iconColor: const Color(0xFFE11D48),
                          isKnown: dam != null,
                        ),
                      ),
                    ],
                  ),

                  // Kakek & Nenek jika ada
                  if (paternalGrandsire != null || paternalGranddam != null) ...[
                    const SizedBox(height: 10),
                    Center(child: Container(width: 2, height: 16, color: const Color(0xFFCBD5E1))),
                    Row(
                      children: [
                        Expanded(
                          child: _ParentBox(
                            name: paternalGrandsire?.name ?? '-',
                            role: 'Kakek (dari Ayah)',
                            breed: paternalGrandsire?.breed,
                            color: const Color(0xFFF8FAFC),
                            borderColor: const Color(0xFFE2E8F0),
                            iconColor: const Color(0xFF64748B),
                            isKnown: paternalGrandsire != null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ParentBox(
                            name: paternalGranddam?.name ?? '-',
                            role: 'Nenek (dari Ayah)',
                            breed: paternalGranddam?.breed,
                            color: const Color(0xFFF8FAFC),
                            borderColor: const Color(0xFFE2E8F0),
                            iconColor: const Color(0xFF64748B),
                            isKnown: paternalGranddam != null,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Keturunan (Children) Chips
                  const SizedBox(height: 20),
                  Text(
                    'Keturunan dari ${sheep.name} (${children.length} ekor)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF163321)),
                  ),
                  const SizedBox(height: 8),
                  if (children.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4ECE4))),
                      child: const Center(
                        child: Text('Belum ada anakan yang terdaftar dari domba ini.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: children.map((c) => ActionChip(
                        avatar: const Icon(Icons.pets, size: 14, color: green),
                        label: Text('${c.name} (${c.id} • ${c.sex})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDCFCE7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onPressed: () {
                          setState(() => _selectedSheep = c);
                        },
                      )).toList(),
                    ),
                ],

                const SizedBox(height: 26),

                // Riwayat Perkembangbiakan (FR-13)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Riwayat Perkawinan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
                    FilledButton.icon(
                      onPressed: _showAddBreedingDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Catat Baru'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_breedingRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('Belum ada catatan perkawinan.', style: TextStyle(color: Color(0xFF718276)))),
                  )
                else
                  ..._breedingRecords.map((br) {
                    final sName = _allSheep.where((s) => s.id == br.sireId).firstOrNull?.name ?? br.sireId;
                    final dName = _allSheep.where((s) => s.id == br.damId).firstOrNull?.name ?? br.damId;

                    Color statusColor;
                    if (br.status == 'Melahirkan') {
                      statusColor = const Color(0xFF16A34A);
                    } else if (br.status == 'Bunting') {
                      statusColor = const Color(0xFFD97706);
                    } else if (br.status == 'Gagal') {
                      statusColor = const Color(0xFFDC2626);
                    } else {
                      statusColor = const Color(0xFF2563EB);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4ECE4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$sName (♂)  ×  $dName (♀)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF163321)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(br.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kawin: ${br.matingDate.day}/${br.matingDate.month}/${br.matingDate.year} • Estimasi Lahir: ${br.expectedBirthDate.day}/${br.expectedBirthDate.month}/${br.expectedBirthDate.year}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          if (br.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Catatan: ${br.notes}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LineageHeroCard extends StatelessWidget {
  final String name;
  final String id;
  final String role;
  final String breed;
  final String pen;

  const _LineageHeroCard({
    required this.name,
    required this.id,
    required this.role,
    required this.breed,
    required this.pen,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pets_rounded, color: green, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: green, fontSize: 18)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Text(id, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: green)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$breed • $pen', style: TextStyle(color: green.withValues(alpha: .85), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(10)),
            child: const Text('Fokus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _ParentBox extends StatelessWidget {
  final String name;
  final String role;
  final String? breed;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final bool isKnown;

  const _ParentBox({
    required this.name,
    required this.role,
    this.breed,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    this.isKnown = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isKnown ? color : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isKnown ? borderColor : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: isKnown ? iconColor : const Color(0xFF94A3B8), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isKnown ? iconColor : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isKnown ? const Color(0xFF163321) : const Color(0xFF94A3B8)),
          ),
          if (breed != null && breed!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(breed!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF718276))),
          ],
        ],
      ),
    );
  }
}
