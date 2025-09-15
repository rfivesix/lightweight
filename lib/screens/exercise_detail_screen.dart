// lib/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    // TODO: Lokalisierung für die Titel
    const String categoryTitle = "Kategorie";
    const String primaryMusclesTitle = "Primäre Muskeln";
    const String secondaryMusclesTitle = "Sekundäre Muskeln";
    const String descriptionTitle = "Beschreibung";

    return Scaffold(
      appBar: AppBar(title: Text(exercise.getLocalizedName(context))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context, title: categoryTitle, content: exercise.categoryName, icon: Icons.category),
                  const SizedBox(height: 12),
                  _buildInfoCard(context, title: primaryMusclesTitle, content: exercise.primaryMuscles.join(', '), icon: Icons.insights),
                  if (exercise.secondaryMuscles.isNotEmpty && exercise.secondaryMuscles.first.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 12.0), child: _buildInfoCard(context, title: secondaryMusclesTitle, content: exercise.secondaryMuscles.join(', '), icon: Icons.scatter_plot_outlined)),
                  const SizedBox(height: 24),
                  if (exercise.getLocalizedDescription(context).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(descriptionTitle, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(exercise.getLocalizedDescription(context), style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const WgerAttributionWidget(),
        ],
      ),
    );
  }
  Widget _buildInfoCard(BuildContext context, {required String title, required String content, required IconData icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        subtitle: Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}