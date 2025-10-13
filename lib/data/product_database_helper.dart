// lib/data/product_database_helper.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';
import './database_helper.dart';

class ProductDatabaseHelper {
  static final ProductDatabaseHelper instance = ProductDatabaseHelper._init();
  ProductDatabaseHelper._init();

  static Database? _offDatabase;
  static Database? _baseDatabase;

  // Ein einfacher Sperrmechanismus, um doppelte Initialisierung zu verhindern.
  static bool _isInitializing = false;
  // --- NEU: kleine Helpers ganz oben in der Klasse ---
  bool _isOpen(Database? db) => db != null && db.isOpen;

  Future<void> _ensureDatabasesAlive() async {
    if (_offDatabase != null && !_offDatabase!.isOpen) {
      _offDatabase = await _initDB('vita_prep_de.db');
    }
    if (_baseDatabase != null && !_baseDatabase!.isOpen) {
      _baseDatabase = await _initDB('vita_base_foods.db');
    }
  }

  Future<void> reloadBaseDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vita_base_foods.db');
    try {
      await _baseDatabase?.close();
    } catch (_) {}
    _baseDatabase = await openDatabase(path);
  }

  // Stellt sicher, dass die Datenbanken geladen sind, bevor eine Abfrage erfolgt.
  Future<void> _ensureDatabasesInitialized() async {
    // Wenn die DBs schon da sind, ist alles gut.
    if (_offDatabase != null) {
      return;
    }

    // Wenn die Initialisierung bereits läuft, warte kurz.
    // Dies ist eine einfache Absicherung, keine komplexe Sperre.
    if (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
      return _ensureDatabasesInitialized();
    }

    _isInitializing = true;

    // EINFACHE, SEQUENZIELLE INITIALISIERUNG - KEIN Future.wait
    try {
      _offDatabase = await _initDB('vita_prep_de.db');
    } catch (e) {
      print(
        "KRITISCHER FEHLER: Die Haupt-Produktdatenbank konnte nicht geladen werden: $e",
      );
    }

    try {
      _baseDatabase = await _initDB('vita_base_foods.db');
    } catch (e) {
      print(
        "INFO: Die optionale Grundnahrungsmittel-DB wurde nicht gefunden. Das ist normal, wenn sie noch nicht hinzugefügt wurde. Fehler: $e",
      );
    }

    _isInitializing = false;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    final exists = await databaseExists(path);

    if (!exists) {
      print(
        "Datenbank '$fileName' existiert nicht, kopiere sie aus den Assets...",
      );
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets/db', fileName));
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print("Datenbank '$fileName' erfolgreich kopiert.");
      } catch (e) {
        print("Fehler beim Kopieren der Datenbank '$fileName': $e");
        if (await File(path).exists()) await File(path).delete();
        throw Exception(
          "Konnte Datenbank '$fileName' nicht aus den Assets laden.",
        );
      }
    } else {
      print("Bestehende Datenbank '$fileName' gefunden.");
    }
    return await openDatabase(path);
  }

  // ÖFFENTLICHER GETTER FÜR DEN BACKUP-MANAGER
  Future<Database?> get offDatabase async {
    await _ensureDatabasesInitialized();
    return _offDatabase;
  }

  Future<List<FoodItem>> searchProducts(String query) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    final List<FoodItem> combinedResults = [];

    if (_baseDatabase != null) {
      final List<Map<String, dynamic>> baseMaps = await _baseDatabase!.query(
        'products',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        limit: 25,
      );
      combinedResults.addAll(
        baseMaps.map(
          (map) => FoodItem.fromMap(map, source: FoodItemSource.base),
        ),
      );
    }

    // Die Haupt-DB muss existieren, sonst stürzt die App hier ab, was korrekt ist.
    if (_offDatabase != null) {
      final List<Map<String, dynamic>> offMaps = await _offDatabase!.query(
        'products',
        where: 'name LIKE ? OR brand LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 50,
      );
      combinedResults.addAll(
        offMaps.map((map) => FoodItem.fromMap(map, source: FoodItemSource.off)),
      );
    }

    final uniqueResults = <String, FoodItem>{};
    for (var item in combinedResults) {
      uniqueResults.putIfAbsent(item.barcode, () => item);
    }
    return uniqueResults.values.toList();
  }

  Future<FoodItem?> getProductByBarcode(String barcode) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();

    // Lokaler Helper mit anderem Namen als das Keyword "try"
    Future<FoodItem?> attempt() async {
      if (_baseDatabase != null) {
        final baseMaps = await _baseDatabase!.query(
          'products',
          where: 'barcode = ?',
          whereArgs: [barcode],
          limit: 1,
        );
        if (baseMaps.isNotEmpty) {
          return FoodItem.fromMap(baseMaps.first, source: FoodItemSource.base);
        }
      }

      if (_offDatabase != null) {
        final offMaps = await _offDatabase!.query(
          'products',
          where: 'barcode = ?',
          whereArgs: [barcode],
          limit: 1,
        );
        if (offMaps.isNotEmpty) {
          return FoodItem.fromMap(offMaps.first, source: FoodItemSource.off);
        }
      }

      return null;
    }

    try {
      return await attempt();
    } on DatabaseException catch (e) {
      // Falls eine der DBs zwischenzeitlich geschlossen wurde → wiederbeleben & einmalig erneut versuchen
      final msg = e.toString().toLowerCase();
      if (msg.contains('database_closed') ||
          msg.contains('attempt to reopen')) {
        await _ensureDatabasesAlive();
        return await attempt();
      }
      rethrow;
    }
  }

  Future<void> insertProduct(FoodItem item) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    if (_offDatabase == null) return;
    await _offDatabase!.insert(
      'products',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FoodItem>> _getProductsByBarcodes(List<String> barcodes) async {
    if (barcodes.isEmpty) return [];
    final results = <FoodItem>[];
    for (final barcode in barcodes) {
      final product = await getProductByBarcode(barcode);
      if (product != null) results.add(product);
    }
    return results;
  }

  Future<List<FoodItem>> getFavoriteProducts() async {
    final favoriteBarcodes = await DatabaseHelper.instance
        .getFavoriteBarcodes();
    return await _getProductsByBarcodes(favoriteBarcodes);
  }

  Future<List<FoodItem>> getRecentProducts() async {
    final recentBarcodes = await DatabaseHelper.instance
        .getRecentlyUsedBarcodes();
    return await _getProductsByBarcodes(recentBarcodes);
  }

  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) async {
    if (barcodes.isEmpty) return [];
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();

    final db = _offDatabase;
    if (db == null) return [];

    // Erstellt eine Kette von '?' für die IN-Klausel
    final placeholders = List.filled(barcodes.length, '?').join(',');
    final maps = await db.query(
      'products',
      where: 'barcode IN ($placeholders)',
      whereArgs: barcodes,
    );
    return maps
        .map((map) => FoodItem.fromMap(map, source: FoodItemSource.off))
        .toList();
  }

  Future<void> updateProduct(FoodItem item) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    if (_offDatabase == null) return;
    await _offDatabase!.update(
      'products',
      item.toMap(),
      where: 'barcode = ?',
      whereArgs: [item.barcode],
    );
  }

  // === NEU: Grundnahrungsmittel lesen (optional mit Kategorie) ===
  Future<List<FoodItem>> getBaseFoods({
    String? categoryKey,
    int limit = 200,
    int offset = 0,
    String? search,
  }) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    if (_baseDatabase == null) return [];

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (categoryKey != null && categoryKey.isNotEmpty) {
      whereParts.add('category_key = ?');
      whereArgs.add(categoryKey);
    }

    if (search != null && search.trim().isNotEmpty) {
      // Suche über name/name_de/name_en
      whereParts.add('(name LIKE ? OR name_de LIKE ? OR name_en LIKE ?)');
      final q = '%${search.trim()}%';
      whereArgs.addAll([q, q, q]);
    }

    final rows = await _baseDatabase!.query(
      'products',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name COLLATE NOCASE',
      limit: limit,
      offset: offset,
    );

    return rows
        .map((m) => FoodItem.fromMap(m, source: FoodItemSource.base))
        .toList();
  }

  // === NEU: Kategorien (für späteren Filter / Anzeige) ===
  Future<List<Map<String, dynamic>>> getBaseCategories() async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    if (_baseDatabase == null) return [];
    return _baseDatabase!.query(
      'categories',
      columns: ['key', 'name_de', 'name_en', 'emoji'],
      orderBy: 'name_de COLLATE NOCASE',
    );
  }

  // === DEV: Felder eines Basis-Eintrags aktualisieren (barcode bleibt) ===
  Future<void> updateBaseProductFields({
    required String barcode,
    required Map<String, Object?> fields, // nur Spalten, die du ändern willst
  }) async {
    await _ensureDatabasesInitialized();
    await _ensureDatabasesAlive();
    if (_baseDatabase == null) {
      throw Exception('Basis-DB nicht geladen');
    }
    if (fields.isEmpty) return;

    // Safety: Barcode niemals überschreiben
    final safe = Map<String, Object?>.from(fields)..remove('barcode');

    await _baseDatabase!.update(
      'products',
      safe,
      where: 'barcode = ?',
      whereArgs: [barcode],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // === DEV: Pfad der Basis-DB ermitteln (für Export/Share) ===
  Future<String> getBaseDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'vita_base_foods.db');
  }
}
