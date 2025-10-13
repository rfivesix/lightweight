// lib/screens/nutrition_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/supplement_track_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/bottom_content_spacer.dart';
import 'package:lightweight/widgets/summary_card.dart';

class NutritionHubScreen extends StatelessWidget {
  const NutritionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          _buildNavigationCard(
            context: context,
            icon: Icons.restaurant_menu_outlined,
            title: l10n.tabMeals,
            subtitle: l10n.mealsEmptyBody,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddFoodScreen()),
              ); //MaterialPageRoute(builder: (_) => const AddFoodScreen(initialTab: 3)));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildNavigationCard(
            context: context,
            icon: Icons.medication_outlined,
            title: l10n.supplementTrackerTitle,
            subtitle: l10n.supplementTrackerDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplementTrackScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildNavigationCard(
            context: context,
            icon: Icons.search,
            title: l10n.drawerFoodExplorer,
            subtitle:
                "Datenbank durchsuchen und Favoriten verwalten", // TODO: l10n
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddFoodScreen()));
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildPlaceholderCard(context, l10n),
          const BottomContentSpacer(),
        ],
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

  Widget _buildPlaceholderCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingXL),
        child: Column(
          children: [
            Icon(
              Icons.rule_folder_outlined,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              "Ernährungsplan", // TODO: l10n
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              "Erstelle und verfolge hier bald detaillierte Ernährungspläne.", // TODO: l10n
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
