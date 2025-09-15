// lib/screens/add_food_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import '../models/food_item.dart';
import './create_food_screen.dart';
import './food_detail_screen.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> with SingleTickerProviderStateMixin {
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = ""; // Wird in didChangeDependencies initialisiert
  final _searchController = TextEditingController();

  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  List<FoodItem> _recentFoodItems = [];
  bool _isLoadingRecent = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
    _loadRecentItems();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialisiere Texte, die den Kontext benötigen, hier
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
    setState(() { _isLoadingSearch = true; });
    
    final results = await ProductDatabaseHelper.instance.searchProducts(enteredKeyword);
    
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateFoodScreen()),
    ).then((_) {
      _searchController.clear();
      _runFilter('');
      _loadFavorites();
      _loadRecentItems();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() { _isLoadingFavorites = true; });
    final results = await ProductDatabaseHelper.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteFoodItems = results;
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _loadRecentItems() async {
    setState(() { _isLoadingRecent = true; });
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.addFoodOption),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          tabs: [
            Tab(icon: const Icon(Icons.search), text: l10n.tabSearch),
            Tab(icon: const Icon(Icons.eco), text: l10n.tabBaseFoods),
            Tab(icon: const Icon(Icons.history), text: l10n.tabRecent),
            Tab(icon: const Icon(Icons.favorite), text: l10n.tabFavorites),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(l10n),
          _buildBaseFoodsTab(l10n),
          _buildRecentTab(l10n),
          _buildFavoritesTab(l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndCreateFood,
        label: Text(l10n.fabCreateOwnFood),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
  
  Widget _buildSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.7), 
              borderRadius: BorderRadius.circular(20)
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(0),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
                prefixIconConstraints: const BoxConstraints(maxHeight: 20, minWidth: 25),
                border: InputBorder.none,
                hintText: l10n.searchHintText,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant), onPressed: () { _searchController.clear(); _runFilter(''); }) : null
              )
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                    ? ListView.builder(itemCount: _foundFoodItems.length, itemBuilder: (context, index) => _buildFoodListItem(_foundFoodItems[index]))
                    : Center(child: Text(_searchInitialText, style: textTheme.titleMedium)),
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
    if (_isLoadingFavorites) return const Center(child: CircularProgressIndicator());
    if (_favoriteFoodItems.isEmpty) {
        // KORREKTUR: Theme-konformer Stil
        return Center(child: Text(l10n.favoritesEmptyState, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))));
    }
    return Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: _favoriteFoodItems.length, itemBuilder: (context, index) => _buildFoodListItem(_favoriteFoodItems[index]))), if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off)) const OffAttributionWidget()]);
  }

  Widget _buildRecentTab(AppLocalizations l10n) {
    if (_isLoadingRecent) return const Center(child: CircularProgressIndicator());
    if (_recentFoodItems.isEmpty) {
        // KORREKTUR: Theme-konformer Stil
        return Center(child: Text(l10n.recentEmptyState, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))));
    }
    return Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: _recentFoodItems.length, itemBuilder: (context, index) => _buildFoodListItem(_recentFoodItems[index]))), if (_recentFoodItems.any((item) => item.source == FoodItemSource.off)) const OffAttributionWidget()]);
  }

  Widget _buildFoodListItem(FoodItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    IconData sourceIcon;
    switch(item.source) {
      case FoodItemSource.base: sourceIcon = Icons.star; break;
      case FoodItemSource.off: case FoodItemSource.user: sourceIcon = Icons.inventory_2; break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        // KORREKTUR: Fallback für leeren Namen und lokalisierter Untertitel
        title: Text(item.name.isNotEmpty ? item.name : l10n.unknown, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(l10n.foodItemSubtitle(item.brand.isNotEmpty ? item.brand : l10n.noBrand, item.calories)),
        trailing: IconButton(
          icon: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 28),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FoodDetailScreen(foodItem: item))).then((_) { 
          _loadFavorites();
          _loadRecentItems();
        }),
      ),
    );
  }
}

  

