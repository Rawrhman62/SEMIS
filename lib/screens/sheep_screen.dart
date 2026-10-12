import 'package:flutter/material.dart';
import '../data/sample_data.dart';

class SheepScreen extends StatefulWidget {
  const SheepScreen({super.key});

  @override
  State<SheepScreen> createState() => _SheepScreenState();
}

class _SheepScreenState extends State<SheepScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = sampleSheep.where((s) =>
      s.name.toLowerCase().contains(_query.toLowerCase()) ||
      s.id.toLowerCase().contains(_query.toLowerCase()) ||
      s.breed.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Data Domba', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF163321))),
          const SizedBox(height: 5),
          const Text('Kelola identitas ternak', style: TextStyle(color: Color(0xFF718276))),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama, ID, atau ras...'),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text('${filtered.length} domba terdaftar', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48604E)))),
            FilledButton.icon(
              onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Tambah domba'),
                content: const Text('Form penyimpanan domba dapat dihubungkan ke SQLite pada tahap berikutnya.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
              )),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ]),
          const SizedBox(height: 12),
          ...filtered.map((sheep) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE4ECE4))),
            child: Column(children: [
              Row(children: [
                Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.pets_rounded, color: Color(0xFF14532D), size: 29)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sheep.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 3),
                  Text('${sheep.id} • ${sheep.breed}', style: const TextStyle(color: Color(0xFF718276), fontSize: 12)),
                ])),
                IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail ${sheep.name}'))), icon: const Icon(Icons.chevron_right_rounded)),
              ]),
              const Divider(height: 24),
              Row(children: [
                _InfoChip(icon: Icons.wc_rounded, text: sheep.sex),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.calendar_month_outlined, text: '${sheep.ageMonths} bulan'),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.home_work_outlined, text: sheep.pen),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Kondisi', style: TextStyle(color: Color(0xFF718276), fontSize: 12)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: sheep.status == 'Sehat' ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(20)), child: Text(sheep.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sheep.status == 'Sehat' ? const Color(0xFF166534) : const Color(0xFF9A3412)))),
              ]),
            ]),
          )),
        ],
      ),
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
