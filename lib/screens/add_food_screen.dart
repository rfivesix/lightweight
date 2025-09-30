// lib/screens/add_food_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/screens/create_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/screens/scanner_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 Tabs
    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
    _loadRecentItems();
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

    final results =
        await ProductDatabaseHelper.instance.searchProducts(enteredKeyword);

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
        .push(
      MaterialPageRoute(builder: (context) => const CreateFoodScreen()),
    )
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // KORREKTUR 1: AppBar entfernt, Titel und TabBar direkt in die ListView
      // KORREKTUR 2: Den grauen Balken entfernen, indem wir einen leeren AppBar verwenden.
      appBar: AppBar(
        automaticallyImplyLeading: true, // ← shows the back chevron
        title: Text(
          l10n.addFoodTitle, // or whatever your l10n key is
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false, // Verteilt Tabs gleichmäßig
                  indicator: const BoxDecoration(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  // KORREKTUR: labelPadding: EdgeInsets.zero, für volle Breite der Tab-Labels
                  labelPadding: EdgeInsets.zero, // Wichtig für exaktes Layout
                  labelColor: isLightMode ? Colors.black : Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.0),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.0),
                  tabs: [
                    Tab(text: l10n.tabSearch),
                    Tab(text: l10n.tabBaseFoods),
                    Tab(text: l10n.tabRecent),
                    Tab(text: l10n.tabFavorites),
                  ],
                ),
              ],
            ),
          ),
          // KORREKTUR 3: Padding im TabBarView entfernen, um den Inhalt zum Rand zu bringen
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(l10n),
                _buildBaseFoodsTab(l10n),
                _buildRecentTab(l10n),
                _buildFavoritesTab(l10n),
              ],
            ),
          ),
        ],
      ),
      // KORRIGIERT: label hinzugefügt
      floatingActionButton: GlassFab(
          label: l10n.fabCreateOwnFood, onPressed: _navigateAndCreateFood),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      // KORREKTUR 4: Horizontaler Padding hier angepasst, um das Abschneiden zu verhindern
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 0), // Vertikalen Padding auf 0 setzen
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
                        prefixIcon: Icon(Icons.search,
                            color: colorScheme.onSurfaceVariant, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  _searchController.clear();
                                  _runFilter('');
                                })
                            : null)),
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
                            _buildFoodListItem(_foundFoodItems[index]))
                    : Center(
                        child: Text(_searchInitialText,
                            style: textTheme.titleMedium)),
          ),
          if (_foundFoodItems.any((item) => item.source == FoodItemSource.off))
            const OffAttributionWidget(),
        ],
      ),
    );
  }

  Widget _buildBaseFoodsTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: DesignConstants.spacingL),
          Text(
            l10n.comingSoon,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.baseFoodsEmptyState,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
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
              Icon(Icons.favorite_border,
                  size: 80, color: Colors.grey.shade400),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: [
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _favoriteFoodItems.length,
              itemBuilder: (context, index) =>
                  _buildFoodListItem(_favoriteFoodItems[index]))),
      if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
        const OffAttributionWidget()
    ]);
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
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: [
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _recentFoodItems.length,
              itemBuilder: (context, index) =>
                  _buildFoodListItem(_recentFoodItems[index]))),
      if (_recentFoodItems.any((item) => item.source == FoodItemSource.off))
        const OffAttributionWidget()
    ]);
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
      // KORREKTUR: Jetzt mit SummaryCard
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        title: Text(item.name.isNotEmpty ? item.name : l10n.unknown,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(l10n.foodItemSubtitle(
            item.brand.isNotEmpty ? item.brand : l10n.noBrand, item.calories)),
        trailing: IconButton(
          icon: Icon(Icons.add_circle_outline,
              color: colorScheme.primary, size: 28),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () {
          // KORREKTUR HIER: Navigiere zum Detail-Screen anstatt zu poppen.
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(foodItem: item),
            ),
          )
              .then((_) {
            // Lade die Listen neu, falls sich Favoriten geändert haben.
            _loadFavorites();
            _loadRecentItems();
          });
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
      final foodItem =
          await ProductDatabaseHelper.instance.getProductByBarcode(barcode);

      // Wenn das Produkt gefunden wurde...
      if (foodItem != null) {
        // ...schließe den AddFoodScreen und gib das gefundene Item zurück.
        Navigator.of(context).pop(foodItem);
      } else {
        // Wenn nicht, zeige eine kurze Info-Nachricht.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.snackbarBarcodeNotFound(barcode)),
          ));
        }
      }
    }
  }
}
