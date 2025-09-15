// lib/screens/exercise_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';

class ExerciseCatalogScreen extends StatefulWidget {
  final bool isSelectionMode;
  const ExerciseCatalogScreen({super.key, this.isSelectionMode = false});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  bool _isLoading = true;
  List<Exercise> _foundExercises = [];
  final _searchController = TextEditingController();

  List<String> _allCategories = [];
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final categoriesFuture = WorkoutDatabaseHelper.instance.getAllCategories();
    final exercisesFuture = WorkoutDatabaseHelper.instance.searchExercises();

    final results = await Future.wait([categoriesFuture, exercisesFuture]);
    
    if (mounted) {
      setState(() {
        _allCategories = results[0] as List<String>;
        _foundExercises = results[1] as List<Exercise>;
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadExercises() async {
    setState(() => _isLoading = true);
    final data = await WorkoutDatabaseHelper.instance.searchExercises(
      query: _searchController.text,
      selectedCategories: _selectedCategories.toList(),
    );
    if (mounted) {
      setState(() {
        _foundExercises = data;
        _isLoading = false;
      });
    }
  }
  
  void _showFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(l10n.filterByCategory,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _allCategories.map((category) {
                              return FilterChip(
                                label: Text(category),
                                selected: _selectedCategories.contains(category),
                                onSelected: (isSelected) {
                                  setModalState(() {
                                    if (isSelected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check),
                          label: Text(l10n.doneButtonLabel), // z.B. "Fertig"
                        ),
                      )
                    ],
                  ),
                );

              }
            );
          },
        );
      },
    ).then((_) {
      _reloadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exerciseCatalogTitle),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (_selectedCategories.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: Text(
                      _selectedCategories.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _reloadExercises(),
              decoration: InputDecoration(
                hintText: l10n.searchHintText,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        _reloadExercises();
                      })
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foundExercises.isEmpty 
                    ? Center(child: Text(l10n.noExercisesFound))
                    : _foundExercises.isEmpty 
                      ? Center(child: Text(l10n.noExercisesFound))
                      : ListView(
                          children: _allCategories.map((category) {
                            final exercisesInCategory = _foundExercises
                                .where((ex) => ex.categoryName == category)
                                .toList();

                            if (exercisesInCategory.isEmpty) return const SizedBox.shrink();

                            return ExpansionTile(
                              title: Text(category, style: Theme.of(context).textTheme.titleMedium),
                              children: exercisesInCategory.map((exercise) {
                                return ListTile(
                                  title: Text(exercise.getLocalizedName(context)),
                                  subtitle: Text(
                                    exercise.primaryMuscles.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    if (widget.isSelectionMode) {
                                      Navigator.of(context).pop(exercise);
                                    } else {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(exercise: exercise),
                                      ));
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
          ),
          const WgerAttributionWidget(),
        ],
      ),
      floatingActionButton: widget.isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push<bool>(MaterialPageRoute(builder: (context) => const CreateExerciseScreen())).then((success) {
                  if (success == true) _loadInitialData();
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}