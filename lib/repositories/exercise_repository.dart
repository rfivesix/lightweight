import 'package:lightweight/models/exercise.dart';
// VON DIESEM IMPORT WECHSELN:
// import 'package:lightweight/services/db_service.dart';
// ZU DIESEM IMPORT:
import 'package:lightweight/data/workout_database_helper.dart';

class ExerciseRepository {
  // ÄNDERE DIESE ZEILE:
  final _db = WorkoutDatabaseHelper.instance.database;

  Future<List<Exercise>> getAll({int limit = 200, int offset = 0}) async {
    final db = await _db;
    // Der Rest der Datei bleibt unverändert...
    final rows = await db.query(
      'exercises_flat',
      columns: [
        'id',
        'name_de',
        'name_en',
        'description_de',
        'description_en',
        'category_name',
        'image_path',
        'primaryMuscles_json_de',
        'primaryMuscles_json_en',
        'secondaryMuscles_json_de',
        'secondaryMuscles_json_en',
        'primaryMuscles',
        'secondaryMuscles',
      ],
      orderBy: 'name_en COLLATE NOCASE',
      limit: limit,
      offset: offset,
    );
    return rows.map((m) => Exercise.fromMap(m)).toList(growable: false);
  }

  Future<Exercise?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'exercises_flat',
      columns: [
        'id',
        'name_de',
        'name_en',
        'description_de',
        'description_en',
        'category_name',
        'image_path',
        'primaryMuscles_json_de',
        'primaryMuscles_json_en',
        'secondaryMuscles_json_de',
        'secondaryMuscles_json_en',
        'primaryMuscles',
        'secondaryMuscles',
      ],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }
}
