// lib/screens/nutrition_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/meal_screen.dart';
import 'package:lightweight/screens/supplement_track_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/bottom_content_spacer.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionHubScreen extends StatefulWidget {
  const NutritionHubScreen({super.key});

  @override
  State<NutritionHubScreen> createState() => _NutritionHubScreenState();
}

class _NutritionHubScreenState extends State<NutritionHubScreen> {
  Future<Map<String, dynamic>>? _hubDataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lade die Daten nur beim ersten Mal.
    _hubDataFuture ??= _loadHubData();
  }

  Future<void> _refreshData() async {
    // Wird vom RefreshIndicator aufgerufen, um die Daten neu zu laden.
    setState(() {
      _hubDataFuture = _loadHubData();
    });
  }

  Future<Map<String, dynamic>> _loadHubData() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();

    final meals = await DatabaseHelper.instance.getMeals();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final recentEntries = await DatabaseHelper.instance.getEntriesForDateRange(
      sevenDaysAgo,
      today,
    );

    String recommendation;
    if (recentEntries.isEmpty) {
      recommendation = l10n.recommendationDefault;
    } else {
      final uniqueDaysTracked = recentEntries
          .map((e) => DateFormat.yMd().format(e.timestamp))
          .toSet();
      final numberOfTrackedDays = uniqueDaysTracked.length;
      int totalRecentCalories = 0;
      for (final entry in recentEntries) {
        final foodItem = await ProductDatabaseHelper.instance
            .getProductByBarcode(entry.barcode);
        if (foodItem != null) {
          totalRecentCalories +=
              (foodItem.calories / 100 * entry.quantityInGrams).round();
        }
      }

      final totalTargetCalories = targetCalories * numberOfTrackedDays;
      final difference = totalRecentCalories - totalTargetCalories;
      final tolerance = totalTargetCalories * 0.05;

      if (numberOfTrackedDays > 1) {
        if (difference > tolerance) {
          recommendation = l10n.recommendationOverTarget(
              numberOfTrackedDays, difference.round());
        } else if (difference < -tolerance) {
          recommendation = l10n.recommendationUnderTarget(
              numberOfTrackedDays, (-difference).round());
        } else {
          recommendation = l10n.recommendationOnTarget(numberOfTrackedDays);
        }
      } else {
        recommendation = l10n.recommendationFirstEntry;
      }
    }

    return {
      'meals': meals,
      'recommendation': recommendation,
    };
  }

  Future<void> _createMealAndOpenEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final defaultName = l10n.mealNameLabel;
    final newMealId =
        await DatabaseHelper.instance.insertMeal(name: defaultName, notes: '');
    final meal = {'id': newMealId, 'name': defaultName, 'notes': ''};

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealScreen(meal: meal, startInEdit: true),
      ),
    );

    final items = await DatabaseHelper.instance.getMealItems(newMealId);
    final createdMeals = await DatabaseHelper.instance.getMeals();
    final createdMeal =
        createdMeals.firstWhere((m) => m['id'] == newMealId, orElse: () => {});

    if (createdMeal.isNotEmpty &&
        (createdMeal['name'] as String) == defaultName &&
        items.isEmpty) {
      await DatabaseHelper.instance.deleteMeal(newMealId);
    }

    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _hubDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(l10n.error));
          }

          final data = snapshot.data!;
          final meals = data['meals'] as List<Map<String, dynamic>>;
          final recommendationText = data['recommendation'] as String;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: DesignConstants.cardPadding,
              children: [
                _buildSectionTitle(context, l10n.today_overview_text),
                SummaryCard(
                  child: Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      recommendationText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context,
                    l10n.my_plans_capslock.replaceAll('PLÄNE', 'MAHLZEITEN')),
                meals.isEmpty
                    ? _buildEmptyMealsCard(context, l10n)
                    : SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: meals.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildCreateMealCard(context, l10n);
                            }
                            return _buildMealCard(context, meals[index - 1]);
                          },
                        ),
                      ),
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context, l10n.overview_capslock),
                _buildNavigationCard(
                  context: context,
                  icon: Icons.restaurant_menu_outlined,
                  title:
                      l10n.manage_all_plans.replaceAll('Pläne', 'Mahlzeiten'),
                  subtitle: l10n.mealsEmptyBody,
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AddFoodScreen(initialTab: 3)),
                        )
                        .then((_) => _refreshData());
                  },
                ),
                //const SizedBox(height: DesignConstants.spacingM),
                _buildNavigationCard(
                  context: context,
                  icon: Icons.medication_outlined,
                  title: l10n.supplementTrackerTitle,
                  subtitle: l10n.supplementTrackerDescription,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SupplementTrackScreen(),
                    ));
                  },
                ),
                //const SizedBox(height: DesignConstants.spacingM),
                _buildNavigationCard(
                  context: context,
                  icon: Icons.search,
                  title: l10n.drawerFoodExplorer,
                  subtitle: l10n.data_from_off_and_wger,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddFoodScreen()),
                    );
                  },
                ),
                const BottomContentSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCreateMealCard(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2.5;
    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: SummaryCard(
          child: InkWell(
            onTap: _createMealAndOpenEditor,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(l10n.mealsCreate, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: SummaryCard(
          child: InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => MealScreen(meal: meal)))
                .then((_) => _refreshData()),
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meal['name'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => MealScreen(meal: meal)))
                        .then((_) => _refreshData()),
                    child: Text(l10n.edit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMealsCard(BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Text(
              l10n.mealsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.mealsEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            TextButton.icon(
              onPressed: _createMealAndOpenEditor,
              icon: const Icon(Icons.add),
              label: Text(l10n.mealsCreate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
