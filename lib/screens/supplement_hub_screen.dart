// lib/screens/supplement_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/dialogs/log_supplement_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/screens/create_supplement_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';

// Helferklasse, um Supplement-Daten und heutige Dosis zu bündeln
class TrackedSupplement {
  final Supplement supplement;
  final double totalDosedToday;
  TrackedSupplement({required this.supplement, required this.totalDosedToday});
}

class SupplementHubScreen extends StatefulWidget {
  const SupplementHubScreen({super.key});
  @override
  State<SupplementHubScreen> createState() => _SupplementHubScreenState();
}

class _SupplementHubScreenState extends State<SupplementHubScreen> {
  bool _isLoading = true;
  List<TrackedSupplement> _trackedSupplements = [];
  List<SupplementLog> _todaysLogs = [];
  final Map<int, String> _supplementNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final allSupplements = await db.getAllSupplements();
    final todaysLogs = await db.getSupplementLogsForDate(DateTime.now());

    final Map<int, double> todaysDoses = {};
    for (final log in todaysLogs) {
      todaysDoses.update(log.supplementId, (value) => value + log.dose,
          ifAbsent: () => log.dose);
    }

    final tracked = allSupplements.map((s) {
      _supplementNames[s.id!] = s.name;
      return TrackedSupplement(
        supplement: s,
        totalDosedToday: todaysDoses[s.id] ?? 0.0,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _trackedSupplements = tracked;
        _todaysLogs = todaysLogs;
        _isLoading = false;
      });
    }
  }

  Future<void> _logSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<LogSupplementDialogContentState> dialogStateKey =
        GlobalKey();

    final result = await showDialog<(double, DateTime)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(supplement.name),
          content: LogSupplementDialogContent(
              key: dialogStateKey, supplement: supplement),
          actions: [
            TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: Text(l10n.add_button),
              onPressed: () {
                final state = dialogStateKey.currentState;
                if (state != null) {
                  final dose =
                      double.tryParse(state.doseText.replaceAll(',', '.'));
                  if (dose != null && dose > 0) {
                    Navigator.of(context).pop((dose, state.selectedDateTime));
                  }
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final newLog = SupplementLog(
        supplementId: supplement.id!,
        dose: result.$1,
        unit: supplement.unit,
        timestamp: result.$2,
      );
      await DatabaseHelper.instance.insertSupplementLog(newLog);
      _loadData();
    }
  }

  Future<void> _deleteLogEntry(int logId) async {
    await DatabaseHelper.instance.deleteSupplementLog(logId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supplementTrackerTitle), // LOKALISIERT
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: DesignConstants.cardPadding,
                children: [
                  _buildSectionTitle(
                      context, l10n.dailyProgressTitle), // LOKALISIERT
                  if (_trackedSupplements
                      .where((ts) =>
                          ts.supplement.dailyGoal != null ||
                          ts.supplement.dailyLimit != null)
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(l10n.emptySupplementGoals,
                          textAlign: TextAlign.center), // LOKALISIERT
                    ),
                  ..._trackedSupplements
                      .where((ts) =>
                          ts.supplement.dailyGoal != null ||
                          ts.supplement.dailyLimit != null)
                      .map((ts) => _buildProgressCard(ts)),

                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(
                      context, l10n.logIntakeTitle), // LOKALISIERT
                  ..._trackedSupplements
                      .map((ts) => _buildLogActionCard(ts.supplement)),

                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(
                      context, l10n.todaysLogTitle), // LOKALISIERT
                  if (_todaysLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(l10n.emptySupplementLogs,
                          textAlign: TextAlign.center), // LOKALISIERT
                    )
                  else
                    ..._todaysLogs.map((log) => _buildLogEntry(log, l10n)),
                ],
              ),
            ),
      floatingActionButton: GlassFab(
        label: l10n.createSupplementTitle,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (context) => const CreateSupplementScreen()),
          );
          if (created == true) {
            _loadData();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
// ... (aus anderem Screen kopiert)
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

  Widget _buildProgressCard(TrackedSupplement ts) {
    final supplement = ts.supplement;
    final isLimit = supplement.dailyLimit != null;
    final target = (isLimit ? supplement.dailyLimit : supplement.dailyGoal)!;
    final progress =
        target > 0 ? (ts.totalDosedToday / target).clamp(0.0, 1.0) : 0.0;
    final overLimit = isLimit && ts.totalDosedToday > target;
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(supplement.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    '${ts.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${supplement.unit}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  (overLimit ? Colors.red : Colors.green).withOpacity(0.2),
              color: overLimit ? Colors.red : Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogActionCard(Supplement supplement) {
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(supplement.name),
        onTap: () => _logSupplement(supplement),
      ),
    );
  }

  Widget _buildLogEntry(SupplementLog log, AppLocalizations l10n) {
    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.endToStart,

      // KORRIGIERT: `background` wird hier `secondaryBackground`
      background: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(l10n.deleteConfirmTitle),
                  content: Text(l10n.deleteConfirmContent),
                  actions: <Widget>[
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel)),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.delete)),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) => _deleteLogEntry(log.id!),
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.grey),
          title: Text(_supplementNames[log.supplementId] ?? 'Unknown'),
          subtitle: Text(DateFormat.Hm().format(log.timestamp)),
          trailing: Text('${log.dose.toStringAsFixed(1)} ${log.unit}'),
        ),
      ),
    );
  }
}
