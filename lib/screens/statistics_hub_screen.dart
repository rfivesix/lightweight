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
          _buildSectionTitle(context, "MEINE KONSISTENZ"),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Die Kalender-Ansicht ist in Kürze verfügbar.",
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
          _buildSectionTitle(context, "TIEFEN-ANALYSE"),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.monitor_weight_outlined,
            title: "Körpermaße",
            subtitle: "Gewicht, KFA und Umfänge analysieren.",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const MeasurementsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.pie_chart_outline_rounded,
            title: "Ernährungs-Analyse",
            subtitle: "Makros, Kalorien und Trends auswerten.",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NutritionScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: "Trainings-Analyse",
            subtitle: "Volumen, Kraft und Progression verfolgen.",
            onTap: () {
              // Platzhalter für den zukünftigen Trainings-Analyse-Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Dieser Screen wird bald verfügbar sein!")),
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
