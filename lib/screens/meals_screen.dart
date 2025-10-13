import 'package:flutter/material.dart';
import 'meal_editor_screen.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Platzhalter-Liste – später mit echten Meals füllen
    final meals = <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      body: meals.isEmpty
          ? const Center(
              child: Text(
                'Noch keine Meals.\nTippe auf das +, um eines zu erstellen.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: meals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => ListTile(
                title: Text(meals[i]),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealEditorScreen(initialName: meals[i]),
                    ),
                  );
                  if (result == true && context.mounted) {
                    // TODO: Liste neu laden (später)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal gespeichert')),
                    );
                  }
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealEditorScreen()),
          );
          if (result == true && context.mounted) {
            // TODO: Liste neu laden (später)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Meal gespeichert')));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
