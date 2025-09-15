import 'package:flutter/material.dart';
import 'package:lightweight/constants/colors.dart';
import 'package:lightweight/data/product_database_helper.dart'; 
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import '../models/food_item.dart';
import './create_food_screen.dart';
import './food_detail_screen.dart';

class FoodExplorerScreen extends StatefulWidget {
  const FoodExplorerScreen({super.key});

  @override
  State<FoodExplorerScreen> createState() => _FoodExplorerScreenState();
}

class _FoodExplorerScreenState extends State<FoodExplorerScreen> with SingleTickerProviderStateMixin {
  // Such-Logik
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = "Bitte gib einen Suchbegriff ein.";
  final _searchController = TextEditingController();

  // Favoriten-Logik
  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
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
      setState(() { _foundFoodItems = []; _searchInitialText = l10n.searchInitialHint; });
      return;
    }
    setState(() { _isLoadingSearch = true; });
    final results = await ProductDatabaseHelper.instance.searchProducts(enteredKeyword);
    if (mounted) {
      setState(() {
        _foundFoodItems = results;
        _isLoadingSearch = false;
        if (results.isEmpty) { _searchInitialText = l10n.searchNoResults;}
      });
    }
  }

  void _navigateAndCreateFood() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateFoodScreen()),
    ).then((_) {
      _searchController.clear();
      _runFilter('');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Lebensmittel-Explorer"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          tabs: [
            Tab(icon: const Icon(Icons.search), text: l10n.tabSearch),
            Tab(icon: const Icon(Icons.favorite), text: l10n.tabFavorites),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(l10n),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
            child: TextField(controller: _searchController, onChanged: (value) => _runFilter(value), decoration: InputDecoration(contentPadding: const EdgeInsets.all(0), prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20), prefixIconConstraints: const BoxConstraints(maxHeight: 20, minWidth: 25), border: InputBorder.none, hintText: l10n.searchHintText, hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant), onPressed: () { _searchController.clear(); _runFilter(''); }) : null)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                    ? ListView.builder(itemCount: _foundFoodItems.length, itemBuilder: (context, index) => _buildFoodListItem(_foundFoodItems[index]))
                    : Center(child: Text(_searchInitialText, style: const TextStyle(fontSize: 18))),
          ),
          if (_foundFoodItems.isNotEmpty) const OffAttributionWidget(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites) return const Center(child: CircularProgressIndicator());
    if (_favoriteFoodItems.isEmpty) return Center(child: Text(l10n.favoritesEmptyState, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey)));
    return Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: _favoriteFoodItems.length, itemBuilder: (context, index) => _buildFoodListItem(_favoriteFoodItems[index]))), const OffAttributionWidget()]);
  }

  Widget _buildFoodListItem(FoodItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.brand.isNotEmpty ? item.brand : "Keine Marke"} - ${item.calories} kcal / 100g'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FoodDetailScreen(foodItem: item))).then((_) => _loadFavorites()),
      ),
    );
  }
}