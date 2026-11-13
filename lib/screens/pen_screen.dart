import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/livestock.dart';
import '../models/records.dart';
import '../services/database_helper.dart';

class PenScreen extends StatefulWidget {
  const PenScreen({super.key});

  @override
  State<PenScreen> createState() => _PenScreenState();
}

class _PenScreenState extends State<PenScreen> {
  List<Pen> _pens = [];
  Map<String, List<Livestock>> _sheepByPen = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pens = await DatabaseHelper.instance.getAllPens();
    final allSheep = await DatabaseHelper.instance.getAllLivestock();

    final Map<String, List<Livestock>> grouped = {};
    for (final p in pens) {
      grouped[p.name] = allSheep.where((s) => s.pen == p.name).toList();
    }

    if (mounted) {
      setState(() {
        _pens = pens;
        _sheepByPen = grouped;
        _isLoading = false;
      });
    }
  }

  void _showPenForm([Pen? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capCtrl = TextEditingController(text: existing?.capacity.toString() ?? '10');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(existing == null ? 'Tambah Kandang' : 'Edit Kandang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kandang *', hintText: 'misal: Kandang D'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kandang wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kapasitas Maksimal (ekor) *'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Masukkan kapasitas minimal 1';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasi / Blok', hintText: 'misal: Blok Timur'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Catatan / Peruntukan'),
                ),
              ],
            ),
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
              if (!formKey.currentState!.validate()) return;
              final pen = Pen(
                id: existing?.id ?? 'PEN-${const Uuid().v4().substring(0, 6).toUpperCase()}',
                name: nameCtrl.text.trim(),
                capacity: int.parse(capCtrl.text.trim()),
                location: locCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );

              if (existing == null) {
                await DatabaseHelper.instance.insertPen(pen);
              } else {
                await DatabaseHelper.instance.updatePen(pen);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePen(Pen pen) async {
    final count = _sheepByPen[pen.name]?.length ?? 0;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat menghapus ${pen.name} karena masih berisi $count domba. Pindahkan domba terlebih dahulu.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kandang'),
        content: Text('Apakah Anda yakin ingin menghapus "${pen.name}"?'),
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
      await DatabaseHelper.instance.deletePen(pen.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pen.name} berhasil dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data Kandang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF163321), letterSpacing: 0.3)),
                        SizedBox(height: 2),
                        Text('Kapasitas dan rasio keterisian ternak', style: TextStyle(color: Color(0xFF718276), fontSize: 12)),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _showPenForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (_pens.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE4ECE4))),
                    child: const Column(
                      children: [
                        Icon(Icons.home_work_outlined, size: 56, color: Color(0xFF829087)),
                        SizedBox(height: 12),
                        Text('Belum ada data kandang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Tekan tombol tambah di atas untuk mendaftarkan kandang.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF718276))),
                      ],
                    ),
                  )
                else
                  ..._pens.map((pen) {
                    final occupants = _sheepByPen[pen.name] ?? [];
                    final ratio = pen.capacity > 0 ? (occupants.length / pen.capacity) : 0.0;
                    final isFull = occupants.length >= pen.capacity;
                    final percent = (ratio * 100).toInt();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE4ECE4), width: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isFull ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: isFull ? const Color(0xFFDC2626) : green,
                            size: 22,
                          ),
                        ),
                        title: Text(pen.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF163321))),
                        subtitle: Text('${pen.location.isNotEmpty ? pen.location : 'Blok Umum'} • $percent% Terisi (${occupants.length}/${pen.capacity})', style: const TextStyle(fontSize: 11, color: Color(0xFF718276))),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              _showPenForm(pen);
                            } else if (v == 'delete') {
                              _deletePen(pen);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Color(0xFFDC2626)))])),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    color: isFull ? const Color(0xFFDC2626) : (ratio > 0.8 ? const Color(0xFFF59E0B) : green),
                                  ),
                                ),
                                if (pen.notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Catatan: ${pen.notes}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Daftar Domba Penghuni:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                                    Text('${occupants.length} Ekor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: green)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (occupants.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('Kandang ini masih kosong.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: occupants.map((s) => Chip(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      avatar: const Icon(Icons.pets, size: 13, color: Color(0xFF14532D)),
                                      label: Text('${s.name} (${s.id})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    )).toList(),
                                  ),
                              ],
                            ),
                          ),
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
