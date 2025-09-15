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
      print("KRITISCHER FEHLER: Die Haupt-Produktdatenbank konnte nicht geladen werden: $e");
    }

    try {
      _baseDatabase = await _initDB('vita_base_foods.db');
    } catch (e) {
      print("INFO: Die optionale Grundnahrungsmittel-DB wurde nicht gefunden. Das ist normal, wenn sie noch nicht hinzugefügt wurde. Fehler: $e");
    }

    _isInitializing = false;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    final exists = await databaseExists(path);

    if (!exists) {
      print("Datenbank '$fileName' existiert nicht, kopiere sie aus den Assets...");
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets/db', fileName));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print("Datenbank '$fileName' erfolgreich kopiert.");
      } catch (e) {
        print("Fehler beim Kopieren der Datenbank '$fileName': $e");
        if (await File(path).exists()) await File(path).delete();
        throw Exception("Konnte Datenbank '$fileName' nicht aus den Assets laden.");
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
    final List<FoodItem> combinedResults = [];
    
    if (_baseDatabase != null) {
      final List<Map<String, dynamic>> baseMaps = await _baseDatabase!.query('products', where: 'name LIKE ?', whereArgs: ['%$query%'], limit: 25);
      combinedResults.addAll(baseMaps.map((map) => FoodItem.fromMap(map, source: FoodItemSource.base)));
    }
    
    // Die Haupt-DB muss existieren, sonst stürzt die App hier ab, was korrekt ist.
    if (_offDatabase != null) {
      final List<Map<String, dynamic>> offMaps = await _offDatabase!.query('products', where: 'name LIKE ? OR brand LIKE ?', whereArgs: ['%$query%', '%$query%'], limit: 50);
      combinedResults.addAll(offMaps.map((map) => FoodItem.fromMap(map, source: FoodItemSource.off)));
    }
    
    final uniqueResults = <String, FoodItem>{};
    for (var item in combinedResults) {
      uniqueResults.putIfAbsent(item.barcode, () => item);
    }
    return uniqueResults.values.toList();
  }

  Future<FoodItem?> getProductByBarcode(String barcode) async {
    await _ensureDatabasesInitialized();
    
    if (_baseDatabase != null) {
      final List<Map<String, dynamic>> baseMaps = await _baseDatabase!.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
      if (baseMaps.isNotEmpty) return FoodItem.fromMap(baseMaps.first, source: FoodItemSource.base);
    }
    
    if (_offDatabase != null) {
      final List<Map<String, dynamic>> offMaps = await _offDatabase!.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
      if (offMaps.isNotEmpty) return FoodItem.fromMap(offMaps.first, source: FoodItemSource.off);
    }
    
    return null;
  }

  Future<void> insertProduct(FoodItem item) async {
    await _ensureDatabasesInitialized();
    if (_offDatabase == null) return;
    await _offDatabase!.insert('products', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final favoriteBarcodes = await DatabaseHelper.instance.getFavoriteBarcodes();
    return await _getProductsByBarcodes(favoriteBarcodes);
  }

  Future<List<FoodItem>> getRecentProducts() async {
    final recentBarcodes = await DatabaseHelper.instance.getRecentlyUsedBarcodes();
    return await _getProductsByBarcodes(recentBarcodes);
  }
}