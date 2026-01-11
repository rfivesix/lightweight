// lib/data/product_database_helper.dart

import 'package:drift/drift.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/drift_database.dart' as db;
import 'package:lightweight/data/drift_database.dart';
import 'package:lightweight/models/food_item.dart';

class ProductDatabaseHelper {
  static final ProductDatabaseHelper instance = ProductDatabaseHelper._init();

  ProductDatabaseHelper._init();

  // Zugriff auf die zentrale Drift-Instanz
  Future<db.AppDatabase> get database async => DatabaseHelper.instance.database;

  // --- MAPPING HELPER ---

  FoodItem _mapRowToModel(db.Product row) {
    FoodItemSource source;
    switch (row.source) {
      case 'base':
        source = FoodItemSource.base;
        break;
      case 'off':
        source = FoodItemSource.off;
        break;
      default:
        source = FoodItemSource.user;
    }

    return FoodItem(
      barcode: row.barcode,
      name: row.name,
      // nameDe/En werden im aktuellen Schema nicht gespeichert,
      // daher Fallback auf name oder leere Strings, falls Model das verlangt
      nameDe: row.name,
      nameEn: row.name,
      brand: row.brand ?? '',
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      source: source,
      sugar: row.sugar,
      fiber: row.fiber,
      salt: row.salt,
      // Sodium ist nicht im Drift Schema, wir berechnen es grob aus Salz oder lassen es null
      sodium: row.salt != null ? row.salt! / 2.5 : null,
      // Kj ist nicht im Schema, berechnen:
      kj: (row.calories * 4.184),
      // Calcium ist nicht im Schema:
      calcium: null,
      isLiquid: row.isLiquid,
      caffeineMgPer100ml: row.caffeine,
    );
  }

  db.ProductsCompanion _mapModelToCompanion(FoodItem item) {
    return db.ProductsCompanion(
      barcode: Value(item.barcode),
      name: Value(item.name),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      isLiquid: Value(item.isLiquid ?? false),
      source: Value(_sourceToString(item.source)),
    );
  }

  String _sourceToString(FoodItemSource source) {
    switch (source) {
      case FoodItemSource.base:
        return 'base';
      case FoodItemSource.off:
        return 'off';
      case FoodItemSource.user:
        return 'user';
    }
  }

  // --- PUBLIC API ---

  Future<void> insertProduct(FoodItem item) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.products).insert(
          _mapModelToCompanion(item),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> updateProduct(FoodItem item) async {
    // In Drift ist insertOrReplace (siehe oben) oft ausreichend,
    // aber hier explizit Update:
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.products)
          ..where((tbl) => tbl.barcode.equals(item.barcode)))
        .write(_mapModelToCompanion(item));
  }

  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) async {
    if (barcodes.isEmpty) return [];
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.products)
          ..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();

    return rows.map(_mapRowToModel).toList();
  }

  Future<List<FoodItem>> getRecentProducts() async {
    final recentBarcodes =
        await DatabaseHelper.instance.getRecentlyUsedBarcodes();
    return await getProductsByBarcodes(recentBarcodes);
  }

  // === Grundnahrungsmittel (Base Foods) ===
  Future<List<Map<String, dynamic>>> getBaseCategories() async {
    final db = await database;

    // Wir fragen jetzt die echte 'food_categories' Tabelle ab
    // Sortiert nach 'key' (oder wie du magst)
    final rows = await (db.select(db.foodCategories)
          ..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .get();

    return rows.map((row) {
      return {
        'key': row.key,
        'name_de': row.nameDe, // Echter Name aus DB
        'name_en': row.nameEn, // Echter Name aus DB
        'emoji': row.emoji, // Echter Emoji aus DB! 🍎
      };
    }).toList();
  }

  // --- 2. BASE-FOODS LADEN (Katalog & Base-Suche) ---
  // FIX: categoryKey ist jetzt optional (String?)
  Future<List<FoodItem>> getBaseFoods({
    String? categoryKey, // <--- NICHT MEHR REQUIRED
    int limit = 100,
    String? search,
  }) async {
    final db = await database;

    var query = db.select(db.products)
      ..where((t) => t.source.equals('base'))
      ..limit(limit);

    // Nur filtern, wenn eine Kategorie angegeben ist
    if (categoryKey != null) {
      query = query..where((t) => t.category.equals(categoryKey));
    }

    if (search != null && search.isNotEmpty) {
      query = query..where((t) => t.name.like('%$search%'));
    }

    final rows = await query.get();
    return rows.map((row) => _mapRowToFoodItem(row)).toList();
  }
// --- 3. GLOBALE SUCHE (Base + OFF + User) ---
  Future<List<FoodItem>> searchProducts(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty) return [];
    final db = await database;
    const int limit = 50;

    // 1. Priorisierte Suche: Eigene Lebensmittel (user) & Grundnahrungsmittel (base)
    // Diese sind am wichtigsten und sollen immer oben stehen.
    final priorityRows = await (db.select(db.products)
          ..where((t) =>
              (t.name.like('%$term%') | t.brand.like('%$term%')) &
              t.source.isIn(['user', 'base']))
          ..orderBy([
            // Kürzere Namen zuerst (Exakte Treffer nach oben)
            (t) => OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();

    final List<FoodItem> results = priorityRows.map(_mapRowToFoodItem).toList();

    // 2. Auffüllen mit Open Food Facts (off), falls noch Platz in der Liste ist
    if (results.length < limit) {
      final int remaining = limit - results.length;
      final offRows = await (db.select(db.products)
            ..where((t) =>
                (t.name.like('%$term%') | t.brand.like('%$term%')) &
                t.source.equals('off'))
            ..orderBy([
              (t) => OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
            ])
            ..limit(remaining))
          .get();

      results.addAll(offRows.map(_mapRowToFoodItem));
    }

    return results;
  }

  // --- 4. SCANNER ---
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final db = await database;
    final row = await (db.select(db.products)
          ..where((t) => t.barcode.equals(barcode))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapRowToFoodItem(row);
  }

  // --- 5. FAVORITEN ---
  Future<List<FoodItem>> getFavoriteProducts() async {
    final db = await database;

    // Join Products mit Favorites
    final query = db.select(db.products).join([
      innerJoin(
          db.favorites, db.favorites.barcode.equalsExp(db.products.barcode))
    ]);

    final result = await query.get();

    return result.map((row) {
      final product = row.readTable(db.products);
      return _mapRowToFoodItem(product);
    }).toList();
  }

  // --- HELPER ---
  FoodItem _mapRowToFoodItem(Product row) {
    return FoodItem(
        barcode: row.barcode,
        name: row.name,
        brand: row.brand ?? '',
        calories: row.calories,
        protein: row.protein,
        carbs: row.carbs,
        fat: row.fat,
        sugar: row.sugar,
        fiber: row.fiber,
        salt: row.salt,
        isLiquid: row.isLiquid,
        source: _mapSource(row.source),
        category: row.category);
  }

  FoodItemSource _mapSource(String sourceString) {
    switch (sourceString) {
      case 'base':
        return FoodItemSource.base;
      case 'off':
        return FoodItemSource.off;
      case 'user':
        return FoodItemSource.user;
      default:
        return FoodItemSource.off;
    }
  }

  // === Legacy / Compatibility Getter ===

  // Für den BackupManager, falls er direkten Zugriff benötigt (deprecated).
  // Da wir jetzt alles in EINER DB haben, ist das Konzept einer separaten "offDatabase" hinfällig.
  // Wir geben null zurück, da der BackupManager im neuen Code Drift nutzen sollte.
  Future<dynamic> get offDatabase async {
    return null;
  }

  Future<String> getBaseDbPath() async {
    // Dummy-Pfad, da wir keine separate Datei mehr nutzen
    return '';
  }
}
