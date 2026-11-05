import 'dart:convert';

enum SyncStatus { pending, synced }

/// Model data hewan ternak dengan dukungan offline-first (US-02).
class Livestock {
  final String id;
  final String name;
  final String species; // Jenis hewan
  final String breed;
  final String sex;
  final DateTime birthDate;
  final String healthStatus; // Sehat / Sakit / Pantau
  final String pen; // Kandang
  final SyncStatus statusSync;
  final DateTime updatedAt;
  final bool isDeleted; // Soft delete flag

  const Livestock({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.healthStatus,
    required this.pen,
    this.statusSync = SyncStatus.pending,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Livestock copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    String? sex,
    DateTime? birthDate,
    String? healthStatus,
    String? pen,
    SyncStatus? statusSync,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Livestock(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      healthStatus: healthStatus ?? this.healthStatus,
      pen: pen ?? this.pen,
      statusSync: statusSync ?? this.statusSync,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'birth_date': birthDate.toIso8601String(),
      'health_status': healthStatus,
      'pen': pen,
      'status_sync': statusSync.name,
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Livestock.fromMap(Map<String, dynamic> map) {
    return Livestock(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String,
      sex: map['sex'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      healthStatus: map['health_status'] as String,
      pen: map['pen'] as String,
      statusSync: (map['status_sync'] as String?) == 'synced'
          ? SyncStatus.synced
          : SyncStatus.pending,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  /// Serialisasi ke JSON untuk dikirim ke Google Drive.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'sex': sex,
        'birth_date': birthDate.toIso8601String(),
        'health_status': healthStatus,
        'pen': pen,
        'status_sync': statusSync.name,
        'updated_at': updatedAt.toIso8601String(),
        'is_deleted': isDeleted,
      };

  static Livestock fromJson(Map<String, dynamic> json) => Livestock(
        id: json['id'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        breed: json['breed'] as String,
        sex: json['sex'] as String,
        birthDate: DateTime.parse(json['birth_date'] as String),
        healthStatus: json['health_status'] as String,
        pen: json['pen'] as String,
        statusSync: (json['status_sync'] as String?) == 'synced'
            ? SyncStatus.synced
            : SyncStatus.pending,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isDeleted: json['is_deleted'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
}
