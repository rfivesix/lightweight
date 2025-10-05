// lib/screens/workout_hub_screen.dart (Final, mit einheitlichem Design)

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/screens/edit_routine_screen.dart';
import 'package:lightweight/screens/exercise_catalog_screen.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/routines_screen.dart';
import 'package:lightweight/screens/workout_history_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/bottom_content_spacer.dart';
import 'package:lightweight/widgets/summary_card.dart';

class WorkoutHubScreen extends StatefulWidget {
  const WorkoutHubScreen({super.key});

  @override
  State<WorkoutHubScreen> createState() => _WorkoutHubScreenState();
}

class _WorkoutHubScreenState extends State<WorkoutHubScreen> {
  bool _isLoading = true;
  List<Routine> _routines = [];
  late final l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final routines = await WorkoutDatabaseHelper.instance.getAllRoutines();
    if (mounted) {
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    }
  }

  void _startEmptyWorkout() async {
    final newLog = await WorkoutDatabaseHelper.instance
        .startWorkout(routineName: l10n.free_training);
    if (mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (context) => LiveWorkoutScreen(workoutLog: newLog),
          ))
          .then((_) => _loadData());
    }
  }

  void _startRoutine(Routine routine) async {
    // Wir brauchen die vollen Details der Routine zum Starten
    final detailedRoutine =
        await WorkoutDatabaseHelper.instance.getRoutineById(routine.id!);
    if (detailedRoutine == null) return;

    final newLog = await WorkoutDatabaseHelper.instance
        .startWorkout(routineName: routine.name);
    if (mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (context) =>
                LiveWorkoutScreen(routine: detailedRoutine, workoutLog: newLog),
          ))
          .then((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: DesignConstants.cardPadding,
                children: [
                  _buildSectionTitle(context, l10n.startCapsLock),
                  SummaryCard(
                    child: InkWell(
                      onTap: _startEmptyWorkout,
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 28),
                            const SizedBox(width: 12),
                            Text(l10n.startEmptyWorkoutButton,
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.my_plans_capslock),
                  _routines.isEmpty
                      ? _buildEmptyRoutinesCard(context, l10n)
                      : SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: _routines.length,
                            itemBuilder: (context, index) {
                              return _buildRoutineCard(
                                  context, _routines[index]);
                            },
                          ),
                        ),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.overview_capslock),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.history,
                    title: l10n.workoutHistoryButton,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const WorkoutHistoryScreen())),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.list_alt_rounded,
                    title: l10n.manage_all_plans,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => const RoutinesScreen()))
                        .then((_) => _loadData()),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.folder_open_outlined,
                    title: l10n.drawerExerciseCatalog,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ExerciseCatalogScreen())),
                  ),
                  const BottomContentSpacer(),
                ],
              ),
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

  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;

    return SizedBox(
      width: cardWidth,
      // KORREKTUR: Wir fügen den Abstand hier als Padding hinzu, nicht als Margin.
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: SummaryCard(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditRoutineScreen(routine: routine),
                ),
              );
            },
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(routine.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  ElevatedButton(
                      onPressed: () => _startRoutine(routine),
                      child: Text(l10n.start_button)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRoutinesCard(BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Text(l10n.emptyRoutinesTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DesignConstants.spacingS),
            Text(l10n.emptyRoutinesSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: DesignConstants.spacingL),
            TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => const RoutinesScreen()))
                  .then((_) => _loadData()),
              icon: const Icon(Icons.add),
              label: Text(l10n.createFirstRoutineButton),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM)),
      ),
    );
  }
}
