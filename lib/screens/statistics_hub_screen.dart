// lib/screens/statistics_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/measurements_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/bottom_content_spacer.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lightweight/screens/supplement_hub_screen.dart'; // NEUER IMPORT

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
  bool _isLoading = true;
  String _recommendationText = '';

  // Sets zur Speicherung der aktiven Tage des Monats
  Set<int> _workoutDays = {};
  Set<int> _nutritionLogDays = {};
  Set<int> _supplementDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Lade ALLE Daten nur EINMAL beim Start
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // Diese Methode lädt jetzt alles, was der Screen braucht
    setState(() {
      _isLoading = true;
    });

    // Lade Kalenderdaten für den aktuell fokussierten Monat
    await _loadMonthData(_focusedDay);

    // Lade die Empfehlung
    final recommendation = await _getRecommendation();

    if (mounted) {
      setState(() {
        _recommendationText = recommendation;
        _isLoading = false; // Ladezustand wird hier beendet
      });
    }
  }

  Future<void> _loadMonthData(DateTime month) async {
    // Diese Methode lädt nur noch die Kalenderdaten und setzt KEINEN Ladezustand mehr
    final workoutDays =
        await WorkoutDatabaseHelper.instance.getWorkoutDaysInMonth(month);
    final nutritionDays =
        await DatabaseHelper.instance.getNutritionLogDaysInMonth(month);
    final supplementDays =
        await DatabaseHelper.instance.getSupplementLogDaysInMonth(month);

    if (mounted) {
      setState(() {
        _workoutDays = workoutDays;
        _nutritionLogDays = nutritionDays;
        _supplementDays = supplementDays;
      });
    }
  }

  Future<void> _loadRecommendation() async {
    final recommendation = await _getRecommendation();
    if (mounted) {
      setState(() {
        _recommendationText = recommendation;
      });
    }
  }

  Future<String> _getRecommendation() async {
    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final recentEntries = await DatabaseHelper.instance
        .getEntriesForDateRange(sevenDaysAgo, today);

    if (recentEntries.isEmpty) {
      return l10n.recommendationDefault;
    }

    final uniqueDaysTracked =
        recentEntries.map((e) => DateFormat.yMd().format(e.timestamp)).toSet();
    final numberOfTrackedDays = uniqueDaysTracked.length;
    int totalRecentCalories = 0;
    for (final entry in recentEntries) {
      final foodItem = await ProductDatabaseHelper.instance
          .getProductByBarcode(entry.barcode);
      if (foodItem != null) {
        totalRecentCalories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
      }
    }

    final totalTargetCalories = targetCalories * numberOfTrackedDays;
    final difference = totalRecentCalories - totalTargetCalories;
    final tolerance = totalTargetCalories * 0.05;

    if (numberOfTrackedDays > 1) {
      if (difference > tolerance) {
        return l10n.recommendationOverTarget(
            numberOfTrackedDays, difference.round());
      } else if (difference < -tolerance) {
        return l10n.recommendationUnderTarget(
            numberOfTrackedDays, (-difference).round());
      } else {
        return l10n.recommendationOnTarget(numberOfTrackedDays);
      }
    } else {
      return l10n.recommendationFirstEntry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.cardPadding,
              children: [
                _buildSectionTitle(context, l10n.my_consistency),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      locale: Localizations.localeOf(context).toString(),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle:
                            Theme.of(context).textTheme.titleMedium!,
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        // KORREKTUR: Setzt nur noch den Fokus und lädt Kalenderdaten neu.
                        // SetState wird innerhalb von _loadMonthData aufgerufen.
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                        _loadMonthData(focusedDay);
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final isNutritionDay =
                              _nutritionLogDays.contains(day.day);
                          final isSupplementDay =
                              _supplementDays.contains(day.day);

                          return Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNutritionDay)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueAccent),
                                  ),
                                if (isNutritionDay && isSupplementDay)
                                  const SizedBox(width: 2),
                                if (isSupplementDay)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.amber),
                                  ),
                              ],
                            ),
                          );
                        },
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                _buildBannerCard(l10n),
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context, l10n.in_depth_analysis),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.medication_outlined,
                  title: l10n.supplementTrackerTitle,
                  subtitle: l10n.supplementTrackerDescription,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SupplementHubScreen()));
                  },
                ),
                const SizedBox(height: DesignConstants.spacingM),
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
                const BottomContentSpacer(),
              ],
            ),
    );
  }

  Widget _buildBannerCard(AppLocalizations l10n) {
    return SummaryCard(
      child: Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          _recommendationText,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 22,
              fontWeight: FontWeight.w500),
        ),
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
