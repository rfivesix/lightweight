// lib/screens/statistics_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/measurements_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/widgets/summary_card.dart';

class StatisticsHubScreen extends StatelessWidget {
  const StatisticsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sektion 1: "MEINE KONSISTENZ" (Platzhalter)
          _buildSectionTitle(context, l10n.my_consistency),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.calendar_currently_not_available,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sektion 2: "TIEFEN-ANALYSE" (Voll funktionsfähig)
          _buildSectionTitle(context, l10n.in_depth_analysis),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.monitor_weight_outlined,
            title: l10n.body_measurements,
            subtitle: l10n.measurements_description,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const MeasurementsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.pie_chart_outline_rounded,
            title: l10n.nutritionScreenTitle,
            subtitle: l10n.nutrition_description,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NutritionScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: l10n.training_analysis,
            subtitle: l10n.training_analysis_description,
            onTap: () {
              // Platzhalter für den zukünftigen Trainings-Analyse-Screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.soon_available_snackbar)),
              );
            },
          ),
        ],
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

  Widget _buildAnalysisGateway({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        leading:
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      ),
    );
  }
}
