import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/dialogs/log_supplement_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/models/tracked_supplement.dart';
import 'package:lightweight/screens/create_supplement_screen.dart';
import 'package:lightweight/util/date_util.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';

class SupplementHubScreen extends StatefulWidget {
  const SupplementHubScreen({super.key});
  @override
  State<SupplementHubScreen> createState() => _SupplementHubScreenState();
}

class _SupplementHubScreenState extends State<SupplementHubScreen> {
  bool _isLoading = true;
  List<TrackedSupplement> _trackedSupplements = [];
  List<SupplementLog> _todaysLogs = [];
  final Map<int, Supplement> _supplementsById = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData(_selectedDate);
  }

  String localizeSupplementName(Supplement s, AppLocalizations l10n) {
    switch (s.code) {
      case 'caffeine':
        return l10n.supplement_caffeine;
      case 'creatine_monohydrate':
        return l10n.supplement_creatine_monohydrate;
      default:
        // Fallback: benutzerdefinierte Supplements behalten ihren Namen
        return s.name;
    }
  }

  Future<void> _loadData(DateTime date) async {
    setState(() => _isLoading = true);

    final db = DatabaseHelper.instance;
    final allSupplements = await db.getAllSupplements();
    final logsForDate = await db.getSupplementLogsForDate(date);

    // Map: supplementId -> Supplement (für l10n-Lookup im Log)
    final Map<int, Supplement> byId = {
      for (final s in allSupplements)
        if (s.id != null) s.id!: s,
    };

    // Tagesdosen akkumulieren
    final Map<int, double> todaysDoses = {};
    for (final log in logsForDate) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    // Progress-Karten Daten
    final tracked = allSupplements.map((s) {
      return TrackedSupplement(
        supplement: s,
        totalDosedToday: todaysDoses[s.id] ?? 0.0,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _supplementsById
        ..clear()
        ..addAll(byId);
      _trackedSupplements = tracked;
      _todaysLogs = logsForDate;
      _isLoading = false;
    });
  }

  Future<void> _logSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<LogSupplementDialogContentState> dialogStateKey =
        GlobalKey();

    final result = await showDialog<(double, DateTime)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizeSupplementName(supplement, l10n)),
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
      _loadData(_selectedDate);
    }
  }

  Future<void> _deleteLogEntry(int logId) async {
    await DatabaseHelper.instance.deleteSupplementLog(logId);
    _loadData(_selectedDate);
  }

  void _navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;

    setState(() {
      _selectedDate = newDay;
    });
    _loadData(_selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData(_selectedDate);
    }
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

  Widget _buildProgressCard(TrackedSupplement ts) {
    final supplement = ts.supplement;
    final isLimit = supplement.dailyLimit != null;
    final target = (isLimit ? supplement.dailyLimit : supplement.dailyGoal)!;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (ts.totalDosedToday / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final progressColor =
        overTarget ? Colors.red.shade400 : Colors.green.shade400;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: progressColor),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizeSupplementName(supplement, l10n),
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ts.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${supplement.unit}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(SupplementLog log, AppLocalizations l10n) {
    final s = _supplementsById[log.supplementId];
    final titleText = (s != null)
        ? localizeSupplementName(s, l10n) // l10n über code (z.B. 'caffeine')
        : 'Unknown';

    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.horizontal,
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editLogEntry(log);
          return false; // nicht aus der Liste entfernen
        } else {
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
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteLogEntry(log.id!);
        }
      },
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.grey),
          title: Text(titleText),
          subtitle: Text(DateFormat.Hm().format(log.timestamp)),
          trailing: Text('${log.dose.toStringAsFixed(1)} ${log.unit}'),
        ),
      ),
    );
  }

  Future<void> _navigateToEditSupplement(Supplement supplement) async {
    final reloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateSupplementScreen(supplementToEdit: supplement),
      ),
    );
    if (reloaded == true) {
      _loadData(_selectedDate);
    }
  }

  Future<void> _deleteSupplement(Supplement supplement) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        // TODO: This confirmation message should be localized
        content: Text(
            "Are you sure you want to permanently delete the supplement '${localizeSupplementName(supplement, l10n)}'? All of its log entries will also be removed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteSupplement(supplement.id!);
      _loadData(_selectedDate);
    }
  }

  Widget _buildLogActionCard(Supplement supplement) {
    final l10n = AppLocalizations.of(context)!;
    // Check if the supplement is the non-editable "Caffeine"
    final isBuiltin = supplement.isBuiltin || supplement.code == 'caffeine';

    // If it is Caffeine, return a simple, non-dismissible ListTile.
    if (isBuiltin) {
      return SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(supplement),
        ),
      );
    }

    // Otherwise, return the original Dismissible widget for all other supplements.
    return Dismissible(
      key: Key('supplement_${supplement.id}'),
      direction: DismissDirection.horizontal,
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _navigateToEditSupplement(supplement);
          return false; // Don't dismiss, just navigate
        } else {
          // We trigger the dialog and let it handle the deletion.
          // We return false because the list is rebuilt anyway, avoiding a visual glitch.
          _deleteSupplement(supplement);
          return false;
        }
      },
      child: SummaryCard(
        child: ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(localizeSupplementName(supplement, l10n)),
          onTap: () => _logSupplement(supplement),
        ),
      ),
    );
  }

  Future<void> _editLogEntry(SupplementLog log) async {
    final l10n = AppLocalizations.of(context)!;
    // Find the full supplement object to pass its details (like unit) to the dialog.
    final supplement = _trackedSupplements
        .firstWhere((ts) => ts.supplement.id == log.supplementId)
        .supplement;
    final GlobalKey<LogSupplementDialogContentState> dialogStateKey =
        GlobalKey();

    final result = await showDialog<(double, DateTime)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizeSupplementName(supplement, l10n)),
          content: LogSupplementDialogContent(
            key: dialogStateKey,
            supplement: supplement,
            initialDose: log.dose,
            initialTimestamp: log.timestamp,
          ),
          actions: [
            TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: Text(l10n.save), // Use 'Save' for editing
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
      final updatedLog = SupplementLog(
        id: log.id,
        supplementId: supplement.id!,
        dose: result.$1,
        unit: supplement.unit,
        timestamp: result.$2,
      );
      await DatabaseHelper.instance.updateSupplementLog(updatedLog);
      _loadData(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.supplementTrackerTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navigateDay(false)),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Text(
                      DateFormat.yMMMMd(locale).format(_selectedDate),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedDate.isSameDate(DateTime.now())
                        ? null
                        : () => _navigateDay(true)),
              ],
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.1)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadData(_selectedDate),
                    child: ListView(
                      padding: DesignConstants.cardPadding,
                      children: [
                        _buildSectionTitle(context, l10n.dailyProgressTitle),
                        if (_trackedSupplements
                            .where((ts) =>
                                ts.supplement.dailyGoal != null ||
                                ts.supplement.dailyLimit != null)
                            .isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(l10n.emptySupplementGoals,
                                textAlign: TextAlign.center),
                          ),
                        ..._trackedSupplements
                            .where((ts) =>
                                ts.supplement.dailyGoal != null ||
                                ts.supplement.dailyLimit != null)
                            .map((ts) => _buildProgressCard(ts)),
                        const SizedBox(height: DesignConstants.spacingXL),
                        _buildSectionTitle(context, l10n.logIntakeTitle),
                        ..._trackedSupplements
                            .map((ts) => _buildLogActionCard(ts.supplement)),
                        const SizedBox(height: DesignConstants.spacingXL),
                        _buildSectionTitle(context, l10n.todaysLogTitle),
                        if (_todaysLogs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(l10n.emptySupplementLogs,
                                textAlign: TextAlign.center),
                          )
                        else
                          ..._todaysLogs
                              .map((log) => _buildLogEntry(log, l10n)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        label: l10n.createSupplementTitle,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (context) => const CreateSupplementScreen()),
          );
          if (created == true) {
            _loadData(_selectedDate);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
