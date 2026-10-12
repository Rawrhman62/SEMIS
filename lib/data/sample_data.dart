class Sheep {
  final String id;
  final String name;
  final String sex;
  final int ageMonths;
  final String breed;
  final String pen;
  final String status;

  const Sheep({
    required this.id,
    required this.name,
    required this.sex,
    required this.ageMonths,
    required this.breed,
    required this.pen,
    required this.status,
  });
}

const sampleSheep = <Sheep>[
  Sheep(id: 'SM-001', name: 'Bimo', sex: 'Jantan', ageMonths: 18, breed: 'Domba Garut', pen: 'Kandang A', status: 'Sehat'),
  Sheep(id: 'SM-002', name: 'Luna', sex: 'Betina', ageMonths: 14, breed: 'Domba Garut', pen: 'Kandang A', status: 'Sehat'),
  Sheep(id: 'SM-003', name: 'Moka', sex: 'Betina', ageMonths: 11, breed: 'Texel', pen: 'Kandang B', status: 'Pantau'),
  Sheep(id: 'SM-004', name: 'Raja', sex: 'Jantan', ageMonths: 22, breed: 'Dorper', pen: 'Kandang C', status: 'Sehat'),
];
