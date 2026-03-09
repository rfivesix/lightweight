import 'package:flutter/material.dart';

import '../../data/workout_database_helper.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/summary_card.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _recovery = const {};

  @override
  void initState() {
    super.initState();
    _loadRecovery();
  }

  Future<void> _loadRecovery() async {
    setState(() => _isLoading = true);
    final data = await WorkoutDatabaseHelper.instance.getRecoveryAnalytics();
    if (!mounted) return;
    setState(() {
      _recovery = data;
      _isLoading = false;
    });
  }

  String _overallLabel(AppLocalizations l10n, String? state) {
    return switch (state) {
      'mostlyRecovered' => l10n.recoveryOverallMostlyRecovered,
      'mixedRecovery' => l10n.recoveryOverallMixed,
      'severalRecovering' => l10n.recoveryOverallSeveralRecovering,
      _ => l10n.recoveryOverallInsufficientData,
    };
  }

  String _stateLabel(AppLocalizations l10n, String state) {
    return switch (state) {
      'recovering' => l10n.recoveryStateRecovering,
      'ready' => l10n.recoveryStateReady,
      'fresh' => l10n.recoveryStateFresh,
      _ => l10n.recoveryStateUnknown,
    };
  }

  Color _stateColor(BuildContext context, String state) {
    return switch (state) {
      'recovering' => Colors.orange,
      'ready' => Colors.blue,
      'fresh' => Colors.green,
      _ => Theme.of(context).colorScheme.outline,
    };
  }

  String _fatigueContextLabel(AppLocalizations l10n, bool highFatigue) {
    return highFatigue
        ? l10n.recoveryFatigueContextHigh
        : l10n.recoveryFatigueContextBaseline;
  }

  String _explanationForMuscle(
    AppLocalizations l10n,
    Map<String, dynamic> muscle,
  ) {
    final muscleName = muscle['muscleGroup'] as String;
    final hours =
        (muscle['hoursSinceLastSignificantLoad'] as num).toDouble().round();
    final highFatigue = (muscle['highSessionFatigue'] as bool?) ?? false;

    if (highFatigue) {
      return l10n.recoveryExplanationWithHighFatigue(muscleName, hours);
    }
    return l10n.recoveryExplanationBasic(muscleName, hours);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final totals = (_recovery['totals'] as Map<String, dynamic>?) ?? const {};
    final recovering = (totals['recovering'] as num?)?.toInt() ?? 0;
    final ready = (totals['ready'] as num?)?.toInt() ?? 0;
    final fresh = (totals['fresh'] as num?)?.toInt() ?? 0;
    final hasData = (_recovery['hasData'] as bool?) ?? false;

    final muscles = (_recovery['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.recoveryTrackerTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _overallLabel(
                                l10n, _recovery['overallState'] as String?),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasData
                                ? l10n.recoveryHubCountsSummary(
                                    recovering,
                                    ready,
                                    fresh,
                                  )
                                : l10n.recoveryHubNoDataSummary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.recoveryHeuristicDisclaimer,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Text(
                    l10n.recoveryByMuscleTitle,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  if (!hasData)
                    SummaryCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(l10n.recoveryNoDataBody),
                      ),
                    )
                  else
                    ...muscles.map((muscle) {
                      final state = muscle['state'] as String;
                      final stateColor = _stateColor(context, state);
                      final hours =
                          (muscle['hoursSinceLastSignificantLoad'] as num)
                              .toDouble()
                              .round();
                      final highFatigue =
                          (muscle['highSessionFatigue'] as bool?) ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingS),
                        child: SummaryCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        muscle['muscleGroup'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            stateColor.withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _stateLabel(l10n, state),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: stateColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(l10n.recoveryLastLoadedHours(hours)),
                                const SizedBox(height: 2),
                                Text(_fatigueContextLabel(l10n, highFatigue)),
                                const SizedBox(height: 6),
                                Text(
                                  _explanationForMuscle(l10n, muscle),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
