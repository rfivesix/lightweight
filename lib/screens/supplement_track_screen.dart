// lib/screens/supplement_track_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/dialogs/log_supplement_dialog_content.dart';
import 'package:lightweight/dialogs/log_supplement_menu.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/models/tracked_supplement.dart';
import 'package:lightweight/screens/manage_supplements_screen.dart';
import 'package:lightweight/util/date_util.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/util/supplement_l10n.dart';
import 'package:lightweight/widgets/glass_bottom_menu.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';

class SupplementTrackScreen extends StatefulWidget {
  const SupplementTrackScreen({super.key});
  @override
  State<SupplementTrackScreen> createState() => _SupplementTrackScreenState();
}

class _SupplementTrackScreenState extends State<SupplementTrackScreen> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  final Map<int, Supplement> _supplementsById = {};
  List<TrackedSupplement> _tracked = const [];
  List<SupplementLog> _todaysLogs = const [];

  @override
  void initState() {
    super.initState();
    _loadData(_selectedDate);
  }

  Future<void> _loadData(DateTime day) async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final supplements = await db.getAllSupplements();
    final logs = await db.getSupplementLogsForDate(day);

    final byId = <int, Supplement>{
      for (final s in supplements)
        if (s.id != null) s.id!: s,
    };

    final doses = <int, double>{};
    for (final log in logs) {
      doses.update(
        log.supplementId,
        (v) => v + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    final tracked = supplements
        .map(
          (s) => TrackedSupplement(
            supplement: s,
            totalDosedToday: doses[s.id] ?? 0.0,
          ),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _supplementsById
        ..clear()
        ..addAll(byId);
      _tracked = tracked;
      _todaysLogs = logs;
      _isLoading = false;
    });
  }

  void _navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    if (forward && newDay.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = newDay);
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
      setState(() => _selectedDate = picked);
      _loadData(_selectedDate);
    }
  }

  Future<void> _logSupplement(Supplement supplement) async {
  final l10n = AppLocalizations.of(context)!;

  final result = await showGlassBottomMenu<(double, DateTime)?>(
    context: context,
    title: localizeSupplementName(supplement, l10n),
    contentBuilder: (ctx, close) {
      return LogSupplementDoseBody(
        supplement: supplement,
        primaryLabel: l10n.add_button,
        onCancel: close,
        onSubmit: (dose, ts) {
          close();
          Navigator.of(ctx).pop((dose, ts));
        },
      );
    },
  );

  if (result == null) return;

  final log = SupplementLog(
    supplementId: supplement.id!,
    dose: result.$1,
    unit: supplement.unit,
    timestamp: result.$2,
  );
  await DatabaseHelper.instance.insertSupplementLog(log);
  _loadData(_selectedDate);
}

  Future<void> _editLogEntry(SupplementLog log) async {
    final l10n = AppLocalizations.of(context)!;
    final supplement = _supplementsById[log.supplementId]!;
    final key = GlobalKey<LogSupplementDialogContentState>();

    final result = await showDialog<(double, DateTime)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizeSupplementName(supplement, l10n)),
        content: LogSupplementDialogContent(
          key: key,
          supplement: supplement,
          initialDose: log.dose,
          initialTimestamp: log.timestamp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final st = key.currentState;
              if (st == null) return;
              final dose = double.tryParse(st.doseText.replaceAll(',', '.'));
              if (dose != null && dose > 0) {
                Navigator.pop(context, (dose, st.selectedDateTime));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null) return;

    final updated = SupplementLog(
      id: log.id,
      supplementId: supplement.id!,
      dose: result.$1,
      unit: supplement.unit,
      timestamp: result.$2,
    );
    await DatabaseHelper.instance.updateSupplementLog(updated);
    _loadData(_selectedDate);
  }

  Future<void> _deleteLogEntry(int id) async {
    // Log sichern
    final deleted = _todaysLogs.firstWhere((l) => l.id == id);

    await DatabaseHelper.instance.deleteSupplementLog(id);
    await _loadData(_selectedDate);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.deleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            // Gleiche Daten, aber ohne ID (damit es ein neuer Datensatz wird)
            final restored = SupplementLog(
              supplementId: deleted.supplementId,
              dose: deleted.dose,
              unit: deleted.unit,
              timestamp: deleted.timestamp,
            );
            await DatabaseHelper.instance.insertSupplementLog(restored);
            _loadData(_selectedDate);
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  Widget _progressCard(TrackedSupplement ts) {
    final s = ts.supplement;
    final isLimit = s.dailyLimit != null;
    final target = (isLimit ? s.dailyLimit : s.dailyGoal) ?? 0.0;
    final overTarget = isLimit && ts.totalDosedToday > target;
    final hasTarget = target > 0;
    final progress =
        hasTarget ? (ts.totalDosedToday / target).clamp(0.0, 1.0) : 0.0;
    final color = overTarget ? Colors.red.shade400 : Colors.green.shade400;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                child: Container(color: color),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizeSupplementName(s, l10n),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTarget
                        ? '${ts.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${s.unit}'
                        : '${ts.totalDosedToday.toStringAsFixed(1)} ${s.unit}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
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

  Widget _logActionTile(Supplement s) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(localizeSupplementName(s, l10n)),
        onTap: () => _logSupplement(s),
      ),
    );
  }

  Widget _logEntryTile(SupplementLog log, AppLocalizations l10n) {
    final s = _supplementsById[log.supplementId];
    final titleText = (s == null) ? 'Unknown' : localizeSupplementName(s, l10n);

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
          return false;
        }
        final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.deleteConfirmTitle),
                content: Text(l10n.deleteConfirmContent),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
        return ok;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) _deleteLogEntry(log.id!);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.supplementTrackerTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: l10n.manageSupplementsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const ManageSupplementsScreen(),
                ),
              );
              if (changed == true) _loadData(_selectedDate);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(_selectedDate),
              child: ListView(
                padding: EdgeInsets.only(
                  left: DesignConstants.cardPadding.left,
                  right: DesignConstants.cardPadding.right,
                  bottom: DesignConstants.cardPadding.bottom + 24,
                  top: 8,
                ),
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _navigateDay(false),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: Text(
                              DateFormat.yMMMMd(locale).format(_selectedDate),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _selectedDate.isSameDate(DateTime.now())
                              ? null
                              : () => _navigateDay(true),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),

                  // Progress section
                  _sectionTitle(l10n.dailyProgressTitle),
                  if (_tracked
                      .where(
                        (t) =>
                            t.supplement.dailyGoal != null ||
                            t.supplement.dailyLimit != null,
                      )
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        l10n.emptySupplementGoals,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ..._tracked
                      .where(
                        (t) =>
                            t.supplement.dailyGoal != null ||
                            t.supplement.dailyLimit != null,
                      )
                      .map(_progressCard),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Log intake
                  _sectionTitle(l10n.logIntakeTitle),
                  ..._tracked.map((t) => _logActionTile(t.supplement)),

                  const SizedBox(height: DesignConstants.spacingXL),

                  // Today's logs
                  _sectionTitle(l10n.todaysLogTitle),
                  if (_todaysLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        l10n.emptySupplementLogs,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._todaysLogs.map((log) => _logEntryTile(log, l10n)),
                ],
              ),
            ),
    );
  }
}
