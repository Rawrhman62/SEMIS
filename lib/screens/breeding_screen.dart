import 'package:flutter/material.dart';

class BreedingScreen extends StatelessWidget {
  const BreedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Silsilah & Pemuliaan', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF163321))),
          const SizedBox(height: 5),
          const Text('Riwayat keturunan dan pasangan', style: TextStyle(color: Color(0xFF718276))),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF14532D), borderRadius: BorderRadius.circular(24)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.account_tree_rounded, color: Color(0xFFBBF7D0), size: 34),
              SizedBox(height: 15),
              Text('Pohon Silsilah', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('Lihat hubungan induk dan keturunan domba.', style: TextStyle(color: Colors.white70, height: 1.35)),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('Contoh silsilah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
          const SizedBox(height: 14),
          const _LineageCard(name: 'Bimo', id: 'SM-001', role: 'Anak', color: Color(0xFFDCFCE7), iconColor: Color(0xFF14532D)),
          Padding(padding: const EdgeInsets.only(left: 37), child: Container(width: 2, height: 22, color: const Color(0xFF86EFAC))),
          Row(children: [
            Expanded(child: _ParentCard(name: 'Garuda', role: 'Ayah')),
            const SizedBox(width: 12),
            Expanded(child: _ParentCard(name: 'Melati', role: 'Ibu')),
          ]),
          const SizedBox(height: 24),
          const Text('Rekomendasi pemuliaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE4ECE4))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(backgroundColor: Color(0xFFDBEAFE), child: Icon(Icons.lightbulb_outline, color: Color(0xFF1D4ED8))),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Periksa hubungan kekerabatan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF163321))),
                SizedBox(height: 5),
                Text('Pastikan calon pasangan tidak memiliki hubungan darah dekat sebelum perkawinan.', style: TextStyle(color: Color(0xFF718276), height: 1.35, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur pencatatan perkawinan masih berupa prototipe.'))),
            icon: const Icon(Icons.add),
            label: const Text('Catat perkawinan'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF14532D), padding: const EdgeInsets.all(15), side: const BorderSide(color: Color(0xFF86EFAC))),
          ),
        ],
      ),
    );
  }
}

class _LineageCard extends StatelessWidget {
  final String name, id, role;
  final Color color, iconColor;
  const _LineageCard({required this.name, required this.id, required this.role, required this.color, required this.iconColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(Icons.pets_rounded, color: iconColor, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: iconColor, fontSize: 16)),
        Text(id, style: TextStyle(color: iconColor.withOpacity(.8), fontSize: 12)),
      ])),
      Text(role, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );
}

class _ParentCard extends StatelessWidget {
  final String name, role;
  const _ParentCard({required this.name, required this.role});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4ECE4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.pets_outlined, color: Color(0xFF14532D)),
      const SizedBox(height: 8),
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF163321))),
      Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF718276))),
    ]),
  );
}
