import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/design_constants.dart';

class NutritionHubScreen extends StatelessWidget {
  const NutritionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 72, color: theme.colorScheme.primary.withOpacity(0.6)),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.nutritionHubTitle ?? 'Nutrition Hub',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.nutritionHubSubtitle ??
                    'Discover insights, track meals, and plan your nutrition here soon.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
