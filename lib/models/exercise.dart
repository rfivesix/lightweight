// lib/models/exercise.dart
import 'dart:convert' show jsonDecode, jsonEncode;

class Exercise {
  final int? id; // optional für neu angelegte Datensätze
  final String nameDe;
  final String nameEn;
  final String descriptionDe;
  final String descriptionEn;
  final String categoryName;
  final String? imagePath;

  /// sauber getrennt
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  const Exercise({
    this.id,
    required this.nameDe,
    required this.nameEn,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.categoryName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.imagePath,
  });

  // ---------- Parsing helpers ----------
  static List<String> _parseMuscleList(dynamic raw) {
    if (raw == null) return const [];
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];

    // JSON-Array?
    if (s.startsWith('[')) {
      try {
        final data = jsonDecode(s);
        if (data is List) {
          return data
              .map((e) => (e ?? '').toString().trim())
              .where((e) => e.isNotEmpty)
              .cast<String>()
              .toList(growable: false);
        }
      } catch (_) {
        // fällt auf CSV zurück
      }
    }

    // CSV (GROUP_CONCAT)
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  // ---------- Factory: DB -> Model ----------
  factory Exercise.fromMap(Map<String, Object?> m) {
    final primRaw = m['primaryMuscles_json_de'] ??
        m['primaryMuscles_json_en'] ??
        m['primaryMuscles'];
    final secRaw = m['secondaryMuscles_json_de'] ??
        m['secondaryMuscles_json_en'] ??
        m['secondaryMuscles'];

    return Exercise(
      id: (m['id'] is num) ? (m['id'] as num).toInt() : m['id'] as int?,
      nameDe: (m['name_de'] ?? '') as String,
      nameEn: (m['name_en'] ?? '') as String,
      descriptionDe: (m['description_de'] ?? '') as String,
      descriptionEn: (m['description_en'] ?? '') as String,
      categoryName: (m['category_name'] ?? '') as String,
      imagePath: m['image_path'] as String?,
      primaryMuscles: _parseMuscleList(primRaw),
      secondaryMuscles: _parseMuscleList(secRaw),
    );
  }

  // ---------- Model -> DB (für Inserts/Updates) ----------
  //
  // Achtung: Wir serialisieren Muskulatur als CSV, weil dein Insert
  // in workout_database_helper aktuell CSV erwartet.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name_de': nameDe,
      'name_en': nameEn,
      'description_de': descriptionDe,
      'description_en': descriptionEn,
      'category_name': categoryName,
      'image_path': imagePath,
      'primaryMuscles': jsonEncode(primaryMuscles),
      'secondaryMuscles': jsonEncode(secondaryMuscles),
    };
  }

  // ---------- convenient ----------
  Exercise copyWith({
    int? id,
    String? nameDe,
    String? nameEn,
    String? descriptionDe,
    String? descriptionEn,
    String? categoryName,
    String? imagePath,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
  }) {
    return Exercise(
      id: id ?? this.id,
      nameDe: nameDe ?? this.nameDe,
      nameEn: nameEn ?? this.nameEn,
      descriptionDe: descriptionDe ?? this.descriptionDe,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    );
  }

  // Optional hilfreich im UI:
  String getLocalizedName(context) => nameDe.isNotEmpty ? nameDe : nameEn;
  String getLocalizedDescription(context) =>
      descriptionDe.isNotEmpty ? descriptionDe : descriptionEn;
}
