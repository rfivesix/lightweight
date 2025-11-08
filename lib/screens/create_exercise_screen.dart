// lib/screens/create_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/global_app_bar.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});
  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController =
      TextEditingController(); // Controller für das Textfeld

  // State-Variablen
  List<String> _allCategories = []; // Für Autocomplete-Vorschläge
  List<String> _allMuscleGroups = []; // Für Chip-Auswahl
  final List<String> _selectedPrimaryMuscles = [];
  final List<String> _selectedSecondaryMuscles = [];
  bool _isLoading = true;
  bool _saving = false;

  late final l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true); // Ladeindikator starten
    final db = WorkoutDatabaseHelper.instance;
    try {
      final categories = await db.getAllCategories();
      final muscles = await db.getAllMuscleGroups();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _allMuscleGroups = muscles;
          _isLoading = false; // Ladeindikator beenden
        });
      }
    } catch (e) {
      print("Fehler beim Laden der Daten für CreateExerciseScreen: $e");
      if (mounted) {
        setState(
            () => _isLoading = false); // Ladeindikator auch bei Fehler beenden
        // Optional: Fehlermeldung anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Daten: $e')),
        );
      }
    }
  }

  Future<void> _saveExercise() async {
    // Verhindere Doppelklick und Speichern ohne Daten
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true); // Zeige Ladezustand im Button

    try {
      final newExercise = Exercise(
        // ID wird von der DB vergeben
        nameDe: _nameController.text
            .trim(), // Annahme: Deutscher Name = Englischer Name für Custom
        nameEn: _nameController.text.trim(),
        descriptionDe: _descriptionController.text.trim(),
        descriptionEn: _descriptionController.text.trim(),
        categoryName:
            _categoryController.text.trim(), // Kategorie aus dem Textfeld
        primaryMuscles: List.from(_selectedPrimaryMuscles), // Kopie erstellen
        secondaryMuscles:
            List.from(_selectedSecondaryMuscles), // Kopie erstellen
        // imagePath bleibt null für Custom Exercises
      );

      // Speichere über den WorkoutDatabaseHelper (der jetzt is_custom=1 setzt)
      await WorkoutDatabaseHelper.instance.insertExercise(newExercise);

      if (mounted) {
        // Erfolgs-Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarSaveSuccess(newExercise.nameDe))),
        );
        // Schließe den Screen und gib 'true' zurück, um anzuzeigen, dass gespeichert wurde
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print("Fehler beim Speichern der Übung: $e");
      if (mounted) {
        // Fehler-Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      // Ladezustand im Button beenden, auch bei Fehler
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.create_exercise_screen_title,
        actions: [
          // Speicher-Button in der AppBar
          TextButton(
            onPressed: _saving
                ? null
                : _saveExercise, // Deaktivieren während Speichern
            child: _saving
                ? const SizedBox(
                    // Ladeindikator im Button
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      color: _saving
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Zeige Ladeindikator
          : SingleChildScrollView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // Formularelemente füllen Breite
                  children: [
                    // --- Name ---
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.exercise_name_label, // Benötigt
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n
                              .validatorPleaseEnterName; // Standard-Validierung
                        }
                        return null;
                      },
                      textInputAction:
                          TextInputAction.next, // Fokus zum nächsten Feld
                    ),
                    const SizedBox(height: DesignConstants.spacingL),

                    // --- Kategorie (Autocomplete) ---
                    Autocomplete<String>(
                      // Controller für das zugrundeliegende Textfeld
                      initialValue:
                          TextEditingValue(text: _categoryController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        if (query.isEmpty) {
                          return const Iterable<
                              String>.empty(); // Keine Vorschläge bei leerem Feld
                        }
                        // Filtere existierende Kategorien
                        return _allCategories
                            .where((cat) => cat.toLowerCase().contains(query));
                      },
                      onSelected: (String selection) {
                        // Wenn ein Vorschlag ausgewählt wird, übernehme ihn
                        _categoryController.text = selection;
                        // Schließe die Tastatur
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder: (context, fieldController, focusNode,
                          onFieldSubmitted) {
                        // Wichtig: Internen Controller mit unserem synchronisieren
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_categoryController.text !=
                              fieldController.text) {
                            _categoryController.text = fieldController.text;
                          }
                        });

                        return TextFormField(
                          controller:
                              fieldController, // Interner Controller des Autocomplete
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.category_label, // Benötigt
                            hintText: l10n.categoryHint, // Beispiel anzeigen
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n
                                  .validatorPleaseEnterCategory; // Eigene Validierung
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next, // Fokus weiter
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        // Style für die Vorschlagsliste
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 200), // Begrenzte Höhe
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: ListTile(title: Text(option)),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: DesignConstants.spacingL),

                    // --- Beschreibung ---
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description_optional_label, // Optional
                      ),
                      maxLines: 3, // Mehrzeilig
                      textInputAction:
                          TextInputAction.done, // Formular abschließen
                    ),
                    const SizedBox(
                        height: DesignConstants.spacingXL), // Größerer Abstand

                    // --- Primäre Muskeln ---
                    _buildSectionTitle(context, l10n.primary_muscles_label),
                    _buildMuscleSelection(
                      allMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedPrimaryMuscles,
                    ),
                    const SizedBox(
                        height: DesignConstants.spacingXL), // Größerer Abstand

                    // --- Sekundäre Muskeln ---
                    _buildSectionTitle(context, l10n.secondary_muscles_label),
                    _buildMuscleSelection(
                      allMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedSecondaryMuscles,
                    ),
                    const SizedBox(
                        height:
                            DesignConstants.spacingXXL), // Extra Abstand unten
                  ],
                ),
              ),
            ),
    );
  }

  // Helfer-Widget für Sektionstitel (kannst du behalten oder anpassen)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700], // Etwas dunkler für mehr Kontrast
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Helfer-Widget für die Muskelauswahl mit Chips
  Widget _buildMuscleSelection({
    required List<String> allMuscles,
    required List<String> selectedMuscles,
  }) {
    // Falls keine Muskeln geladen wurden (Fehlerfall)
    if (allMuscles.isEmpty && !_isLoading) {
      return Text("Fehler: Muskelgruppen konnten nicht geladen werden.",
          style: TextStyle(color: Theme.of(context).colorScheme.error));
    }

    return Wrap(
      spacing: 8.0, // Horizontaler Abstand
      runSpacing: 4.0, // Vertikaler Abstand
      children: allMuscles.map((muscle) {
        final isSelected = selectedMuscles.contains(muscle);
        return FilterChip(
          label: Text(muscle),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              // Wichtig: UI muss neu gezeichnet werden
              if (selected) {
                selectedMuscles.add(muscle);
              } else {
                selectedMuscles.remove(muscle);
              }
            });
          },
          // Visuelle Anpassungen für besseres Aussehen
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
          showCheckmark: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Kompakter
        );
      }).toList(),
    );
  }
}
