// lib/screens/workout_history_screen.dart (Final & De-Materialisiert mit AppBar)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/workout_log_detail_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/util/time_util.dart';
import 'package:lightweight/widgets/summary_card.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<WorkoutLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await WorkoutDatabaseHelper.instance.getWorkoutLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLog(int logId) async {
    await WorkoutDatabaseHelper.instance.deleteWorkoutLog(logId);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.workoutHistoryTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              // KORREKTUR: Aufgewerteter "Empty State"
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_outlined,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: DesignConstants.spacingL),
                        Text(
                          l10n.workoutHistoryEmptyTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignConstants.spacingS),
                        Text(
                          l10n.emptyHistory,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: DesignConstants.cardPadding,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final duration = log.endTime?.difference(log.startTime);

                    return Dismissible(
                      key: Key('log_${log.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.deleteConfirmTitle),
                                content: Text(l10n.deleteWorkoutConfirmContent),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(l10n.delete),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (direction) {
                        _deleteLog(log.id!);
                      },
                      child: SummaryCard(
                        child: ListTile(
                          leading: const Icon(Icons.event_note, size: 40),
                          title: Text(
                            log.routineName ?? l10n.freeWorkoutTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMMd(locale)
                                .add_Hm()
                                .format(log.startTime),
                          ),
                          trailing: duration != null
                              ? Text(
                                  formatDuration(duration),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkoutLogDetailScreen(logId: log.id!),
                                ),
                              )
                              .then((_) => _loadHistory()),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
