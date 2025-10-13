import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DbService {
  static Database? _db;
  static final DbService I = DbService._();
  DbService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'vita_training.db');

    // Falls Datei noch nicht existiert: aus Assets kopieren
    if (!await File(dbPath).exists()) {
      final bytes = await rootBundle.load('assets/db/vita_training.db');
      await File(dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    // readOnly ist optional – wenn du später migrieren willst, weglassen.
    return openDatabase(dbPath, readOnly: true);
  }
}
