// lib/screens/exercise_catalog_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'package:lightweight/screens/create_exercise_screen.dart';
import 'package:lightweight/widgets/glass_fab.dart';

class ExerciseCatalogScreen extends StatefulWidget {
  final bool isSelectionMode;
  const ExerciseCatalogScreen({super.key, this.isSelectionMode = false});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  List<Exercise> _foundExercises = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _runFilter(_searchController.text));
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await WorkoutDatabaseHelper.instance.getAllCategories();
    setState(() {
      _allCategories = categories;
      _isLoading = false;
    });
    _runFilter(_searchController.text); // Erste Ladung oder Filter
  }

  void _runFilter(String enteredKeyword) async {
    final results = await WorkoutDatabaseHelper.instance.searchExercises(
      query: enteredKeyword,
      selectedCategories: _selectedCategories,
    );
    if (mounted) {
      setState(() {
        _foundExercises = results;
      });
    }
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        // Lokaler State für die Auswahl im Dialog
        List<String> tempSelectedCategories = List.from(_selectedCategories);
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              // Nutzt globales DialogTheme
              title: Text(l10n.filterByCategory),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allCategories.map((category) {
                    final isSelected =
                        tempSelectedCategories.contains(category);
                    return ListTile(
                      title: Text(category),
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setStateSB(() {
                            // State des Dialogs aktualisieren
                            if (value == true) {
                              tempSelectedCategories.add(category);
                            } else {
                              tempSelectedCategories.remove(category);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  // Nutzt globales Theme
                  onPressed: () {
                    setState(() {
                      // State des Haupt-Screens aktualisieren
                      _selectedCategories = tempSelectedCategories;
                    });
                    _runFilter(_searchController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.doneButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          "Exercises",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // KORREKTUR 1: AppBar entfernt, Titel und Aktionen im Body
// Body ohne doppelten Titel
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isSelectionMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.doneButtonLabel),
                    ),
                  ),
                const SizedBox(height: DesignConstants.spacingS),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchHintText,
                    prefixIcon: Icon(Icons.search,
                        color: colorScheme.onSurfaceVariant, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                _buildFilterButton(context, l10n),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurfaceVariant.withOpacity(0.1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foundExercises.isEmpty
                    ? Center(
                        child: Text(l10n.noExercisesFound,
                            style: textTheme.titleMedium))
                    : ListView.builder(
                        padding: DesignConstants.cardPadding,
                        itemCount: _foundExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _foundExercises[index];
                          return SummaryCard(
                            // KORREKTUR 3: Übungs-Card
                            child: ListTile(
                              leading: const Icon(Icons.fitness_center),
                              title: Text(exercise.getLocalizedName(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(exercise.categoryName),
                              trailing: widget.isSelectionMode
                                  ? IconButton(
                                      // Auswahl-Modus: Hinzufügen-Icon
                                      icon: Icon(Icons.add_circle_outline,
                                          color: colorScheme.primary),
                                      onPressed: () =>
                                          Navigator.of(context).pop(exercise),
                                    )
                                  : const Icon(Icons
                                      .chevron_right), // Anzeige-Modus: Pfeil
                              onTap: () {
                                if (widget.isSelectionMode) {
                                  // Im Auswahl-Modus: Bei Klick auch auswählen
                                  Navigator.of(context).pop(exercise);
                                } else {
                                  // Im Anzeige-Modus: Detail-Screen öffnen
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          ExerciseDetailScreen(
                                              exercise: exercise)));
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
          // KORREKTUR 4: WgerAttributionWidget am Ende
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: WgerAttributionWidget(
              textStyle: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        label: l10n.create_exercise_screen_title,
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
                builder: (context) => const CreateExerciseScreen()),
          )
              .then((wasCreated) {
            // Wenn der Screen mit 'true' zurückkehrt, wurde eine Übung erstellt.
            // Lade die Liste neu, um die neue Übung anzuzeigen.
            if (wasCreated == true) {
              _runFilter(_searchController.text);
            }
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // KORREKTUR 5: Helfer-Widget für den Filter-Button
  Widget _buildFilterButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: () => _showFilterDialog(context, l10n),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _selectedCategories.isNotEmpty
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list,
                  size: 20,
                  color: _selectedCategories.isNotEmpty
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l10n.filterByCategory,
                style: textTheme.labelLarge?.copyWith(
                  color: _selectedCategories.isNotEmpty
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
