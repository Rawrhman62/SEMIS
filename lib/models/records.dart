class HealthRecord {
  final String id;
  final String livestockId;
  final DateTime date;
  final String condition;
  final String diagnosis;
  final String treatment;
  final String notes;

  const HealthRecord({
    required this.id,
    required this.livestockId,
    required this.date,
    required this.condition,
    required this.diagnosis,
    required this.treatment,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'livestock_id': livestockId,
        'date': date.toIso8601String(),
        'condition': condition,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'notes': notes,
      };

  factory HealthRecord.fromMap(Map<String, dynamic> map) => HealthRecord(
        id: map['id'] as String,
        livestockId: map['livestock_id'] as String,
        date: DateTime.parse(map['date'] as String),
        condition: map['condition'] as String? ?? 'Sehat',
        diagnosis: map['diagnosis'] as String? ?? '-',
        treatment: map['treatment'] as String? ?? '-',
        notes: map['notes'] as String? ?? '',
      );
}

class GrowthRecord {
  final String id;
  final String livestockId;
  final DateTime date;
  final double weight;
  final double? height;
  final String notes;

  const GrowthRecord({
    required this.id,
    required this.livestockId,
    required this.date,
    required this.weight,
    this.height,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'livestock_id': livestockId,
        'date': date.toIso8601String(),
        'weight': weight,
        'height': height,
        'notes': notes,
      };

  factory GrowthRecord.fromMap(Map<String, dynamic> map) => GrowthRecord(
        id: map['id'] as String,
        livestockId: map['livestock_id'] as String,
        date: DateTime.parse(map['date'] as String),
        weight: (map['weight'] as num).toDouble(),
        height: (map['height'] as num?)?.toDouble(),
        notes: map['notes'] as String? ?? '',
      );
}

class Pen {
  final String id;
  final String name;
  final int capacity;
  final String location;
  final String notes;

  const Pen({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'location': location,
        'notes': notes,
      };

  factory Pen.fromMap(Map<String, dynamic> map) => Pen(
        id: map['id'] as String,
        name: map['name'] as String,
        capacity: map['capacity'] as int? ?? 10,
        location: map['location'] as String? ?? 'Blok Utama',
        notes: map['notes'] as String? ?? '',
      );
}

class BreedingRecord {
  final String id;
  final String sireId;
  final String damId;
  final DateTime matingDate;
  final DateTime expectedBirthDate;
  final DateTime? actualBirthDate;
  final String status; // 'Kawin', 'Bunting', 'Melahirkan', 'Gagal'
  final int offspringCount;
  final String notes;

  const BreedingRecord({
    required this.id,
    required this.sireId,
    required this.damId,
    required this.matingDate,
    required this.expectedBirthDate,
    this.actualBirthDate,
    required this.status,
    this.offspringCount = 0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sire_id': sireId,
        'dam_id': damId,
        'mating_date': matingDate.toIso8601String(),
        'expected_birth_date': expectedBirthDate.toIso8601String(),
        'actual_birth_date': actualBirthDate?.toIso8601String(),
        'status': status,
        'offspring_count': offspringCount,
        'notes': notes,
      };

  factory BreedingRecord.fromMap(Map<String, dynamic> map) => BreedingRecord(
        id: map['id'] as String,
        sireId: map['sire_id'] as String,
        damId: map['dam_id'] as String,
        matingDate: DateTime.parse(map['mating_date'] as String),
        expectedBirthDate: DateTime.parse(map['expected_birth_date'] as String),
        actualBirthDate: map['actual_birth_date'] != null
            ? DateTime.parse(map['actual_birth_date'] as String)
            : null,
        status: map['status'] as String? ?? 'Kawin',
        offspringCount: map['offspring_count'] as int? ?? 0,
        notes: map['notes'] as String? ?? '',
      );
}

class UserAccount {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin' / 'Peternak'
  final bool isActive;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'is_active': isActive ? 1 : 0,
      };

  factory UserAccount.fromMap(Map<String, dynamic> map) => UserAccount(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        role: map['role'] as String? ?? 'Peternak',
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );
}
