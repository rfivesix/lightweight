// lib/screens/add_food_screen.dart (Final & De-Materialisiert)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/screens/create_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/screens/meal_screen.dart';
import 'package:lightweight/screens/scanner_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';

// lib/screens/add_food_screen.dart

class AddFoodScreen extends StatefulWidget {
  final int initialTab;
  const AddFoodScreen({super.key, this.initialTab = 0});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = "";
  final _searchController = TextEditingController();

  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  List<FoodItem> _recentFoodItems = [];
  bool _isLoadingRecent = true;

  late TabController _tabController;
  final TextEditingController _baseSearchCtrl = TextEditingController();
  String _baseSearch = '';
  Timer? _baseSearchDebounce;

  List<Map<String, dynamic>> _baseCategories = [];
  final Map<String, List<FoodItem>> _catItems = {}; // key -> Produkte
  final Set<String> _loadingCats = {}; // ladeanzeige je Kategorie
  // Meals
  List<Map<String, dynamic>> _meals = [];
  final Map<int, List<Map<String, dynamic>>> _mealItemsCache = {};
  bool _isLoadingMeals = true;
  int _currentTab = 0; // 0=Katalog, 1=Zuletzt, 2=Favoriten, 3=Mahlzeiten
  bool _suspendFab = false;

  Future<void> _loadMeals() async {
    setState(() => _isLoadingMeals = true);
    final rows = await DatabaseHelper.instance.getMeals();
    setState(() {
      _meals = rows;
      _isLoadingMeals = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getMealItems(int mealId) async {
    if (_mealItemsCache.containsKey(mealId)) return _mealItemsCache[mealId]!;
    final rows = await DatabaseHelper.instance.getMealItems(mealId);
    _mealItemsCache[mealId] = rows;
    return rows;
  }

  Future<void> _loadBaseCategories() async {
    _baseCategories = await ProductDatabaseHelper.instance.getBaseCategories();
    if (mounted) setState(() {});
  }

  Future<void> _loadCategoryItems(String key) async {
    if (_catItems.containsKey(key) || _loadingCats.contains(key)) return;
    _loadingCats.add(key);
    if (mounted) setState(() {});
    final items = await ProductDatabaseHelper.instance.getBaseFoods(
      categoryKey: key,
      limit: 500, // großzügig – DB ist lokal
    );
    _catItems[key] = items;
    _loadingCats.remove(key);
    if (mounted) setState(() {});
  }

  void _onBaseSearchChanged(String v) {
    _baseSearchDebounce?.cancel();
    _baseSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _baseSearch = v.trim());
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _currentTab = _tabController.index;
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });

    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
    _loadRecentItems();
    _baseSearchCtrl.addListener(
      () => _onBaseSearchChanged(_baseSearchCtrl.text),
    );
    _loadBaseCategories();
    _loadMeals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_searchInitialText.isEmpty) {
      _searchInitialText = AppLocalizations.of(context)!.searchInitialHint;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _baseSearchDebounce?.cancel();
    _baseSearchCtrl.dispose();
    super.dispose();
  }

  void _runFilter(String enteredKeyword) async {
    final l10n = AppLocalizations.of(context)!;
    if (enteredKeyword.isEmpty) {
      setState(() {
        _foundFoodItems = [];
        _searchInitialText = l10n.searchInitialHint;
      });
      return;
    }
    setState(() {
      _isLoadingSearch = true;
    });

    final results = await ProductDatabaseHelper.instance.searchProducts(
      enteredKeyword,
    );

    if (mounted) {
      setState(() {
        _foundFoodItems = results;
        _isLoadingSearch = false;
        if (results.isEmpty) {
          _searchInitialText = l10n.searchNoResults;
        }
      });
    }
  }

  void _navigateAndCreateFood() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreateFoodScreen()))
        .then((_) {
      _searchController.clear();
      _runFilter('');
      _loadFavorites();
      _loadRecentItems();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
    });
    final results = await ProductDatabaseHelper.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteFoodItems = results;
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _loadRecentItems() async {
    setState(() {
      _isLoadingRecent = true;
    });
    final results = await ProductDatabaseHelper.instance.getRecentProducts();
    if (mounted) {
      setState(() {
        _recentFoodItems = results;
        _isLoadingRecent = false;
      });
    }
  }

  Future<void> _createMealAndOpenEditor(AppLocalizations l10n) async {
    // Solider Default-Name (nicht leer wegen NOT NULL in DB)
    final defaultName = l10n.mealTypeLabel; // z.B. "Mahlzeit" / "Meal"
    final newMealId = await DatabaseHelper.instance.insertMeal(
      name: defaultName,
      notes: '',
    );

    final meal = {'id': newMealId, 'name': defaultName, 'notes': ''};

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealScreen(meal: meal, startInEdit: true),
      ),
    );

    // Nach Rückkehr Liste aktualisieren
    await _loadMeals();

    // (Optionaler Feinschliff)
    // Wenn Nutzer abbricht und nichts geändert hat: Platzhalter wieder entfernen.
    try {
      final items = await DatabaseHelper.instance.getMealItems(newMealId);
      // Falls noch mit Defaultnamen und ohne Zutaten → löschen
      final created = _meals.firstWhere((m) => m['id'] == newMealId);
      if ((created['name'] as String) == defaultName && items.isEmpty) {
        await DatabaseHelper.instance.deleteMeal(newMealId);
        await _loadMeals();
      }
    } catch (_) {
      /* egal, Cleanup ist optional */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    // FAB-Konfiguration je Tab
    VoidCallback? fabOnPressed;
    String fabLabel;
    if (_suspendFab) {
      fabOnPressed = null;
      fabLabel = '';
    } else if (_currentTab == 3) {
      // Mahlzeiten-Tab
      fabLabel = l10n.mealsCreate;
      fabOnPressed = () => _createMealAndOpenEditor(l10n);
    } else {
      // Alle anderen Tabs
      fabLabel = l10n.fabCreateOwnFood;
      fabOnPressed = _navigateAndCreateFood;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.addFoodTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: const BoxDecoration(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelPadding: EdgeInsets.zero,
                  labelColor: isLightMode ? Colors.black : Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: [
                    Tab(text: l10n.tabCatalogSearch),
                    Tab(text: l10n.tabRecent),
                    Tab(text: l10n.tabFavorites),
                    Tab(text: l10n.tabMeals),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogSearchTab(l10n),
                _buildRecentTab(l10n),
                _buildFavoritesTab(l10n),
                _buildMealsTab(l10n),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _suspendFab
          ? null
          : GlassFab(
              label: fabLabel,
              onPressed: fabOnPressed ?? () {}, // ✅ Fallback: immer non-null
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      // KORREKTUR 4: Horizontaler Padding hier angepasst, um das Abschneiden zu verhindern
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 0,
      ), // Vertikalen Padding auf 0 setzen
      child: Column(
        children: [
          Row(
            children: [
              // Die Suchleiste füllt jetzt den verfügbaren Platz
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _runFilter(value),
                  decoration: InputDecoration(
                    hintText: l10n.searchHintText,
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _runFilter('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8), // Kleiner Abstand
              // Der neue Scanner-Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                onPressed: _scanBarcodeAndPop, // Ruft die neue Methode auf
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                    ? ListView.builder(
                        itemCount: _foundFoodItems.length,
                        itemBuilder: (context, index) =>
                            _buildFoodListItem(_foundFoodItems[index]),
                      )
                    : Center(
                        child: Text(
                          _searchInitialText,
                          style: textTheme.titleMedium,
                        ),
                      ),
          ),
          if (_foundFoodItems.any((item) => item.source == FoodItemSource.off))
            const OffAttributionWidget(),
        ],
      ),
    );
  }

  Widget _buildBaseFoodsTab(AppLocalizations l10n) {
    // Kopf: Suche
    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _baseSearchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Suche Grundnahrungsmittel', //l10n.searchBaseFoodHintText
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );

    // Modus 1: mit Suchbegriff → Trefferliste
    if (_baseSearch.isNotEmpty) {
      return Column(
        children: [
          searchField,
          Expanded(
            child: FutureBuilder<List<FoodItem>>(
              future: ProductDatabaseHelper.instance.getBaseFoods(
                search: _baseSearch,
                limit: 200,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Keine Treffer.'));
                }
                return ListView.builder(
                  padding: DesignConstants.cardPadding,
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildFoodListItem(items[i]),
                );
              },
            ),
          ),
        ],
      );
    }

    // Modus 2: kein Suchbegriff → Kategorien mit Emoji (Accordion)
    return Column(
      children: [
        searchField,
        if (_baseCategories.isEmpty)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _catItems.clear();
              await _loadBaseCategories();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _baseCategories.length,
              itemBuilder: (context, idx) {
                final cat = _baseCategories[idx];
                final key = cat['key'] as String;
                final emoji = (cat['emoji'] as String?)?.trim();
                final title =
                    (cat['name_de'] as String?)?.trim().isNotEmpty == true
                        ? cat['name_de'] as String
                        : (cat['name_en'] as String? ?? key);

                final loading = _loadingCats.contains(key);
                final items = _catItems[key];

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Text(
                      emoji?.isNotEmpty == true ? emoji! : '🗂️',
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(title),
                    initiallyExpanded: false,
                    onExpansionChanged: (expanded) {
                      if (expanded) _loadCategoryItems(key);
                    },
                    children: [
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (items == null || items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: Text('Keine Einträge')),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: DesignConstants.cardPadding.copyWith(top: 0),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _buildFoodListItem(items[i]),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteFoodItems.isEmpty) {
      // NEUER, AUFGEWERTETER EMPTY STATE
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.noFavorites,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.favoritesEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _favoriteFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_favoriteFoodItems[index]),
          ),
        ),
        if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
      ],
    );
  }

  Widget _buildRecentTab(AppLocalizations l10n) {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentFoodItems.isEmpty) {
      // NEUER, AUFGEWERTETER EMPTY STATE
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.nothingTrackedYet,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.recentEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _recentFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_recentFoodItems[index]),
          ),
        ),
        if (_recentFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
      ],
    );
  }

  Widget _buildFoodListItem(FoodItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    IconData sourceIcon;
    switch (item.source) {
      case FoodItemSource.base:
        sourceIcon = Icons.star;
        break;
      case FoodItemSource.off:
      case FoodItemSource.user:
        sourceIcon = Icons.inventory_2;
        break;
    }

    return SummaryCard(
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        // --- HIER IST DIE ÄNDERUNG ---
        title: Text(
          item.getLocalizedName(context).isNotEmpty
              ? item.getLocalizedName(context)
              : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // --- ENDE DER ÄNDERUNG ---
        subtitle: Text(
          l10n.foodItemSubtitle(
            item.brand.isNotEmpty ? item.brand : l10n.noBrand,
            item.calories,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: colorScheme.primary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(foodItem: item),
            ),
          );

          if (result is FoodItem) {
            Navigator.of(context).pop(result);
          } else {
            _loadFavorites();
            _loadRecentItems();
          }
        },
      ),
    );
  }

  // FÜGE DIESE NEUE METHODE HINZU
  void _scanBarcodeAndPop() async {
    final l10n = AppLocalizations.of(context)!;
    // Öffne den Scanner und warte auf einen Barcode (String) als Ergebnis
    final String? barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    // Wenn ein Barcode zurückgegeben wurde und der Screen noch existiert...
    if (barcode != null && mounted) {
      // ...suche das Produkt in der Datenbank.
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        barcode,
      );

      // Wenn das Produkt gefunden wurde...
      if (foodItem != null) {
        // ...schließe den AddFoodScreen und gib das gefundene Item zurück.
        Navigator.of(context).pop(foodItem);
      } else {
        // Wenn nicht, zeige eine kurze Info-Nachricht.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.snackbarBarcodeNotFound(barcode))),
          );
        }
      }
    }
  }

  Widget _buildCatalogSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // UI: Suchleiste + Scanner-Button (wie in _buildSearchTab)
    final searchRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter, // nutzt deine bestehende Suche
              decoration: InputDecoration(
                hintText: l10n.searchHintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
            onPressed: _scanBarcodeAndPop,
          ),
        ],
      ),
    );

    // FALL A: Kein Query → Kategorien/Accordion aus Base-DB (deine vorhandene Logik)
    final String q = _searchController.text.trim();
    if (q.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 12),
          searchRow,
          const SizedBox(height: 8),
          if (_baseCategories.isEmpty)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _catItems.clear();
                await _loadBaseCategories();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _baseCategories.length,
                itemBuilder: (context, idx) {
                  final cat = _baseCategories[idx];
                  final key = cat['key'] as String;
                  final emoji = (cat['emoji'] as String?)?.trim();
                  final locale = Localizations.localeOf(context).languageCode;
                  final title = () {
                    final de = (cat['name_de'] as String?)?.trim();
                    final en = (cat['name_en'] as String?)?.trim();
                    if (locale == 'de') {
                      return (de?.isNotEmpty == true)
                          ? de!
                          : (en?.isNotEmpty == true ? en! : key);
                    } else {
                      return (en?.isNotEmpty == true)
                          ? en!
                          : (de?.isNotEmpty == true ? de! : key);
                    }
                  }();

                  final loading = _loadingCats.contains(key);
                  final items = _catItems[key];

                  return Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Text(
                        emoji?.isNotEmpty == true ? emoji! : '🗂️',
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(title),
                      initiallyExpanded: false,
                      onExpansionChanged: (expanded) {
                        if (expanded) _loadCategoryItems(key);
                      },
                      children: [
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (items == null || items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: Text(l10n.emptyCategory)),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: DesignConstants.cardPadding.copyWith(
                              top: 0,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _buildFoodListItem(items[i]),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // FALL B: Mit Query → zuerst Base-Items, dann OFF/User-Items (Priorisierung)
    final baseHits = _foundFoodItems
        .where((it) => it.source == FoodItemSource.base)
        .toList();
    final otherHits = _foundFoodItems
        .where((it) => it.source != FoodItemSource.base)
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        searchRow,
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingSearch
              ? const Center(child: CircularProgressIndicator())
              : (baseHits.isEmpty && otherHits.isEmpty)
                  ? Center(
                      child: Text(
                        l10n.searchNoResults,
                        style: textTheme.titleMedium,
                      ),
                    )
                  : ListView(
                      padding: DesignConstants.cardPadding,
                      children: [
                        if (baseHits.isNotEmpty) ...[
                          Text(
                            l10n.searchSectionBase,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...baseHits.map(_buildFoodListItem),
                          const SizedBox(height: DesignConstants.spacingL),
                        ],
                        if (otherHits.isNotEmpty) ...[
                          Text(
                            l10n.searchSectionOther,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...otherHits.map(_buildFoodListItem),
                        ],
                        if (otherHits
                            .any((i) => i.source == FoodItemSource.off))
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: OffAttributionWidget(),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildMealsTab(AppLocalizations l10n) {
    if (_isLoadingMeals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_meals.isEmpty) {
      // Empty State: kein Top-Button mehr – Erstellen läuft über den FAB
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.mealsEmptyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.mealsEmptyBody,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: ListView.builder(
        padding: DesignConstants.cardPadding,
        itemCount: _meals.length,
        itemBuilder: (_, i) {
          final meal = _meals[i];
          return _buildMealCard(meal, l10n); // enthält jetzt Swipe-Actions
        },
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, AppLocalizations l10n) {
    final color = Theme.of(context).colorScheme;

    Future<Map<String, num>> computeMealTotals(int mealId) async {
      final items = await _getMealItems(mealId);
      int kcal = 0;
      double c = 0, f = 0, p = 0;

      for (final it in items) {
        final bc = it['barcode'] as String;
        final qty = (it['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
        final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
        if (fi == null) continue;

        final factor = qty / 100.0;
        kcal += ((fi.calories ?? 0) * factor).round();
        c += (fi.carbs ?? 0) * factor;
        f += (fi.fat ?? 0) * factor;
        p += (fi.protein ?? 0) * factor;
      }
      return {'kcal': kcal, 'c': c, 'f': f, 'p': p};
    }

    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.restaurant, color: color.primary),
        title: Text(meal['name'] as String),
        subtitle: FutureBuilder<Map<String, num>>(
          future: computeMealTotals(meal['id'] as int),
          builder: (_, snap) {
            // Fallback: nur Anzahl Zutaten, falls noch lädt
            if (!snap.hasData) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getMealItems(meal['id'] as int),
                builder: (_, s2) {
                  final count = s2.data?.length ?? 0;
                  return Text('${l10n.mealIngredientsTitle}: $count');
                },
              );
            }
            final t = snap.data!;
            final c = (t['c'] ?? 0).toDouble();
            final f = (t['f'] ?? 0).toDouble();
            final p = (t['p'] ?? 0).toDouble();
            final kcal = (t['kcal'] ?? 0).toInt();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getMealItems(meal['id'] as int),
                  builder: (_, s2) {
                    final count = s2.data?.length ?? 0;
                    return Text('${l10n.mealIngredientsTitle}: $count');
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  '$kcal kcal   •   C ${c.toStringAsFixed(1)} g   •   F ${f.toStringAsFixed(1)} g   •   P ${p.toStringAsFixed(1)} g',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            );
          },
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.mealsAddToDiary,
              icon: Icon(Icons.add_circle_outline, color: color.primary),
              onPressed: () => _confirmAndLogMeal(meal, l10n),
            ),
            IconButton(
              tooltip: l10n.mealsEdit,
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Neuer Screen öffnen (View), direkt in Edit wechseln
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealScreen(meal: meal, startInEdit: true),
                  ),
                );
                await _loadMeals();
              },
            ),
            IconButton(
              tooltip: l10n.mealsDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteMeal(meal, l10n),
            ),
          ],
        ),
        onTap: () async {
          // Neuer Detail-Screen (View)
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => MealScreen(meal: meal)));
          await _loadMeals();
        },
      ),
    );
  }

  Future<void> _openMealEditor(
    AppLocalizations l10n, {
    Map<String, dynamic>? mealToEdit,
  }) async {
    final isEdit = mealToEdit != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? (mealToEdit['name'] as String? ?? '') : '',
    );
    final notesCtrl = TextEditingController(
      text: isEdit ? (mealToEdit['notes'] as String? ?? '') : '',
    );

    List<Map<String, dynamic>> items = isEdit
        ? List<Map<String, dynamic>>.from(
            await _getMealItems(mealToEdit['id'] as int),
          )
        : <Map<String, dynamic>>[];

    setState(() => _suspendFab = true);
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true, // <- wichtig: über allen Overlays
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            // verhindert Doppelklicks auf "Speichern"
            bool saving = false;
            Future<void> addIngredient() async {
              final picked = await _pickIngredient(l10n);
              if (picked == null) return;
              final (barcode, grams) = picked;

              // Produkt für den Namen (optional) laden
              final fi = await ProductDatabaseHelper.instance
                  .getProductByBarcode(barcode);
              final displayName =
                  (fi?.name.isNotEmpty ?? false) ? fi!.name : null;
              modalSetState(() {
                items.add({
                  'id': null,
                  'meal_id': mealToEdit?['id'],
                  'barcode': barcode,
                  'quantity_in_grams': grams,
                  'display_name': displayName, // nur Anzeige
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEdit ? l10n.mealsEdit : l10n.mealsCreate,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.mealNameLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(labelText: l10n.mealNotesLabel),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Live-Validierung: Name + mind. 1 Zutat
                      // (keine Listener nötig; wir lesen direkt unten aus nameCtrl/items)
                      // Hinweis: Keine UI-Änderung hier – nur Logik im Save-Handler.
                      // (enabled/disabled steuern wir über onPressed: null)
                      Text(
                        l10n.mealIngredientsTitle,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: addIngredient,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.mealAddIngredient),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              l10n.emptyCategory,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final it = items[i];
                              final barcode = it['barcode'] as String;

                              return FutureBuilder<FoodItem?>(
                                future: ProductDatabaseHelper.instance
                                    .getProductByBarcode(barcode),
                                builder: (_, snap) {
                                  final fi = snap.data;
                                  final displayName =
                                      (fi?.name.isNotEmpty ?? false)
                                          ? fi!.name
                                          : barcode;
                                  final isLiquid = (fi?.isLiquid == true);
                                  final unit = isLiquid ? 'ml' : 'g';
                                  final amount = it['quantity_in_grams'] ?? 0;

                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.drag_indicator,
                                      size: 18,
                                    ),
                                    title: Text(displayName),
                                    subtitle: Text('$amount $unit'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => modalSetState(
                                        () => items.removeAt(i),
                                      ), // <—
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          print("save button clicked");
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          try {
                            if (isEdit) {
                              final mealId = mealToEdit['id'] as int;
                              await DatabaseHelper.instance.updateMeal(
                                mealId,
                                name: name,
                                notes: notesCtrl.text.trim(),
                              );
                              await DatabaseHelper.instance.clearMealItems(
                                mealId,
                              );
                              for (final it in items) {
                                await DatabaseHelper.instance.addMealItem(
                                  mealId,
                                  barcode: it['barcode'] as String,
                                  grams: it['quantity_in_grams'] as int,
                                );
                              }
                            } else {
                              final mealId =
                                  await DatabaseHelper.instance.insertMeal(
                                name: name,
                                notes: notesCtrl.text.trim(),
                              );
                              for (final it in items) {
                                await DatabaseHelper.instance.addMealItem(
                                  mealId,
                                  barcode: it['barcode'] as String,
                                  grams: it['quantity_in_grams'] as int,
                                );
                              }
                            }
                            _mealItemsCache.clear();
                            await _loadMeals();
                            if (mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.mealSaved)),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${l10n.error}: $e')),
                              );
                            }
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() => _suspendFab = false);
  }

  Future<void> _deleteMeal(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.mealDeleteConfirmTitle),
            content: Text(l10n.mealDeleteConfirmBody(meal['name'] as String)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await DatabaseHelper.instance.deleteMeal(meal['id'] as int);
    _mealItemsCache.remove(meal['id'] as int);
    await _loadMeals();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealDeleted)));
    }
  }

  Future<(String, int)?> _pickIngredient(AppLocalizations l10n) async {
    final searchCtrl = TextEditingController();
    List<FoodItem> results = [];
    bool loading = false;

    return showDialog<(String, int)?>(
      context: context,
      builder: (ctx) {
        final qtyCtrl = TextEditingController(text: '100'); // default
        Future<void> runSearch(String q) async {
          if (q.trim().isEmpty) {
            results = [];
            (ctx as Element).markNeedsBuild();
            return;
          }
          loading = true;
          (ctx as Element).markNeedsBuild();
          results = await ProductDatabaseHelper.instance.searchProducts(
            q.trim(),
          );
          loading = false;
          (ctx).markNeedsBuild();
        }

        return AlertDialog(
          title: Text(l10n.mealAddIngredient),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchHintText,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: runSearch,
                ),
                const SizedBox(height: 8),
                if (loading) const LinearProgressIndicator(minHeight: 2),
                Flexible(
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.searchInitialHint),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final fi = results[i];
                            return ListTile(
                              dense: true,
                              title: Text(fi.name),
                              subtitle: Text(
                                fi.brand.isNotEmpty ? fi.brand : l10n.noBrand,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  // Nach Menge fragen
                                  final grams = await showDialog<int>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(
                                        l10n.mealIngredientAmountLabel,
                                      ),
                                      content: TextField(
                                        controller: qtyCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: false,
                                        ),
                                        decoration: const InputDecoration(
                                          suffixText: 'g/ml',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final val = int.tryParse(
                                              qtyCtrl.text.trim(),
                                            );
                                            Navigator.pop(context, val);
                                          },
                                          child: Text(l10n.add_button),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (grams != null && grams > 0 && mounted) {
                                    Navigator.of(ctx).pop((fi.barcode, grams));
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndLogMeal(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    final mealId = meal['id'] as int;
    final rawItems = List<Map<String, dynamic>>.from(
      await _getMealItems(mealId),
    );
    if (rawItems.isEmpty) return;

    // Produkte vorab laden (für Namen, isLiquid, Koffein)
    final Map<String, FoodItem?> products = {};
    for (final it in rawItems) {
      final bc = it['barcode'] as String;
      products[bc] = await ProductDatabaseHelper.instance.getProductByBarcode(
        bc,
      );
    }

    // Editierbare Mengen pro Zutat
    final Map<String, TextEditingController> qtyCtrls = {
      for (final it in rawItems)
        (it['barcode'] as String): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };

    // Interne Keys wie im Diary/Nutrition (WICHTIG: exakt diese Strings)
    const internalTypes = [
      'mealtypeBreakfast',
      'mealtypeLunch',
      'mealtypeDinner',
      'mealtypeSnack',
    ];
    String selectedMealType = internalTypes.first;

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };

    final ok = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, modalSetState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.mealsAddToDiary,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal['name'] as String,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      // Meal-Type Auswahl
                      DropdownButtonFormField<String>(
                        initialValue: selectedMealType,
                        decoration: InputDecoration(
                          labelText: l10n.mealTypeLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: internalTypes
                            .map(
                              (key) => DropdownMenuItem(
                                value: key,
                                child: Text(mealTypeLabel[key] ?? key),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            modalSetState(() => selectedMealType = v);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Zutatenliste mit editierbaren Mengen
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: rawItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final it = rawItems[i];
                            final bc = it['barcode'] as String;
                            final fi = products[bc];
                            final displayName = (fi?.name.isNotEmpty ?? false)
                                ? fi!.name
                                : bc; // Fallback Barcode, falls Name fehlt
                            final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 14),
                                  child: Icon(Icons.lunch_dining),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: qtyCtrls[bc],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText:
                                          displayName, // Name statt Barcode
                                      helperText: l10n.amountLabel,
                                      suffixText: unit,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(l10n.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ) ??
        false;

    if (!ok) return;

    // Speichern → pro Zutat ein FoodEntry (inkl. Wasser/Koffein falls zutreffend)
    final ts = DateTime.now();
    for (final it in rawItems) {
      final bc = it['barcode'] as String;
      final ctrl = qtyCtrls[bc]!;
      final qty =
          int.tryParse(ctrl.text.trim()) ?? (it['quantity_in_grams'] as int);

      // 1) FoodEntry (mit korrekt gesetztem Meal-Typ)
      await DatabaseHelper.instance.insertFoodEntry(
        FoodEntry(
          barcode: bc,
          timestamp: ts,
          quantityInGrams: qty,
          mealType: selectedMealType, // <- EXACT dieselben Keys wie im Diary
        ),
      );

      // 2) Wasser/Koffein automatisch buchen (bei Flüssigkeiten)
      final fi = products[bc];
      if (fi != null) {
        if (fi.isLiquid == true) {
          // await DatabaseHelper.instance.insertWaterEntry(qty, ts);
        }
        final c100 = fi.caffeineMgPer100ml;
        if (fi.isLiquid == true && c100 != null && c100 > 0) {
          await _logCaffeineDose(c100 * (qty / 100.0), ts);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealAddedToDiarySuccess)));
    }
  }

  Future<void> _logCaffeineDose(double doseMg, DateTime timestamp) async {
    if (doseMg <= 0) return;

    // Caffeine-Supplement suchen/anlegen
    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );

    final caffeineId = caffeine.id ??
        (await DatabaseHelper.instance.insertSupplement(caffeine)).id!;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        // source_food_entry_id: hier könnten wir verlinken, wenn wir die neue FoodEntry-ID hätten –
        // in diesem Flow buchen wir mehrere; Verlinkung kannst du später erweitern.
      ),
    );
  }
}
