// lib/screens/statistics_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/measurements_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:table_calendar/table_calendar.dart'; // NEUER IMPORT

// KORREKTUR: Umwandlung in ein StatefulWidget
class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({super.key});

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  // State-Variablen für den Kalender
  late final l10n = AppLocalizations.of(context)!;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoadingCalendar = true;

  // Sets zur Speicherung der aktiven Tage des Monats
  Set<int> _workoutDays = {};
  Set<int> _nutritionLogDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthData(_focusedDay); // Lade Daten für den aktuellen Monat
  }

  /// Lädt Workout- und Ernährungs-Tage für den gegebenen Monat.
  Future<void> _loadMonthData(DateTime month) async {
    setState(() {
      _isLoadingCalendar = true;
    });

    final workoutDays =
        await WorkoutDatabaseHelper.instance.getWorkoutDaysInMonth(month);
    final nutritionDays =
        await DatabaseHelper.instance.getNutritionLogDaysInMonth(month);

    if (mounted) {
      setState(() {
        _workoutDays = workoutDays;
        _nutritionLogDays = nutritionDays;
        _isLoadingCalendar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          // Sektion 1: "MEINE KONSISTENZ" mit dem neuen Kalender
          _buildSectionTitle(context, l10n.my_consistency),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                locale: Localizations.localeOf(context).toString(),
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false, // Versteckt den "2 Weeks"-Button
                  titleCentered: true,
                  titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // Hier könnte in Zukunft die Detail-Anzeige für den Tag geladen werden
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadMonthData(focusedDay); // Lade Daten für den neuen Monat
                },
                // HIER PASSIERT DIE MAGIE: Das Aussehen der Tage wird angepasst
                calendarBuilders: CalendarBuilders(
                  // Builder für die Marker (die kleinen Punkte)
                  markerBuilder: (context, day, events) {
                    final isNutritionDay = _nutritionLogDays.contains(day.day);
                    if (isNutritionDay) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  // Builder für die Tages-Zellen selbst
                  defaultBuilder: (context, day, focusedDay) {
                    final isWorkoutDay = _workoutDays.contains(day.day);
                    if (isWorkoutDay) {
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    // Wenn kein Workout-Tag, wird der Standard-Look verwendet
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

          // Sektion 2: "TIEFEN-ANALYSE" (bleibt unverändert)
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
          const SizedBox(height: DesignConstants.spacingM),
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
          const SizedBox(height: DesignConstants.spacingM),
          _buildAnalysisGateway(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: l10n.training_analysis,
            subtitle: l10n.training_analysis_description,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.soon_available_snackbar)),
              );
            },
          ),
        ],
      ),
    );
  }

  // Diese Helfer-Methoden bleiben unverändert
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
