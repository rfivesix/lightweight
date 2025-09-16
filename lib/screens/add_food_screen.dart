// lib/screens/add_food_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/screens/create_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // KORREKTUR 1: AppBar entfernt, Titel und TabBar direkt in die ListView
      // KORREKTUR 2: Den grauen Balken entfernen, indem wir einen leeren AppBar verwenden.
      appBar: AppBar(
        toolbarHeight: 0, // AppBar komplett "unsichtbar" machen
        elevation: 0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent, // Schattenfarbe explizit transparent
        surfaceTintColor:
            Colors.transparent, // Surface tint color auch transparent
        bottomOpacity: 0, // Bottom-Border-Opazität auf 0
        forceMaterialTransparency: true, // Erzwingt Transparenz
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
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: ElevatedButton.icon(
          onPressed: _navigateAndCreateFood,
          icon: const Icon(Icons.add),
          label: Text(l10n.fabCreateOwnFood),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
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
          horizontal: 16.0, vertical: 0), // Vertikalen Padding auf 0 setzen
      child: Column(
        children: [
          TextField(
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

  // PLATZHALTER FÜR DEN NEUEN TAB
  Widget _buildBaseFoodsTab(AppLocalizations l10n) {
    // Hier wird später die Logik zum Anzeigen der Kategorien (Obst, Gemüse etc.) implementiert
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.baseFoodsEmptyState,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites)
      return const Center(child: CircularProgressIndicator());
    if (_favoriteFoodItems.isEmpty) {
      // KORREKTUR: Theme-konformer Stil
      return Center(
          child: Text(l10n.favoritesEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))));
    }
    return Column(children: [
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _favoriteFoodItems.length,
              itemBuilder: (context, index) =>
                  _buildFoodListItem(_favoriteFoodItems[index]))),
      if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
        const OffAttributionWidget()
    ]);
  }

  Widget _buildRecentTab(AppLocalizations l10n) {
    if (_isLoadingRecent)
      return const Center(child: CircularProgressIndicator());
    if (_recentFoodItems.isEmpty) {
      // KORREKTUR: Theme-konformer Stil
      return Center(
          child: Text(l10n.recentEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))));
    }
    return Column(children: [
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _recentFoodItems.length,
              itemBuilder: (context, index) =>
                  _buildFoodListItem(_recentFoodItems[index]))),
      if (_recentFoodItems.any((item) => item.source == FoodItemSource.off))
        const OffAttributionWidget()
    ]);
  }

  // KORREKTUR 5: _buildFoodListItem verwendet jetzt SummaryCard
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
        onTap: () => Navigator.of(context)
            .pop(item), // KORREKTUR: Direkt Pop, da wir hier nur auswählen
      ),
    );
  }
}
