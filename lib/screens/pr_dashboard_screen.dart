// lib/screens/pr_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/bottom_content_spacer.dart';

/// A dashboard screen that surfaces personal records across all exercises.
///
/// Displays all-time PRs, recent PRs within selectable time windows,
/// and a rep-range breakdown for quick reference.
class PrDashboardScreen extends StatefulWidget {
  const PrDashboardScreen({super.key});

  @override
  State<PrDashboardScreen> createState() => _PrDashboardScreenState();
}

class _PrDashboardScreenState extends State<PrDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, List<Map<String, dynamic>>> _allTimePRs = {};
  List<Map<String, dynamic>> _recentPRs = [];

  // Rep range filter for the "By Rep Range" tab
  int _selectedRepRange = 5;
  static const List<int> _repRanges = [1, 3, 5, 8, 10];

  // Time window for "Recent PRs"
  int _recentDays = 30;

  /// Sentinel value used for the "All time" time-window filter.
  static const int _allTimeDays = 36500; // 100 years

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allTime = await WorkoutDatabaseHelper.instance.getAllTimePRs();
    final recent = await WorkoutDatabaseHelper.instance
        .getRecentPRs(DateTime.now().subtract(Duration(days: _recentDays)));
    if (mounted) {
      setState(() {
        _allTimePRs = allTime;
        _recentPRs = recent;
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadRecent() async {
    final recent = await WorkoutDatabaseHelper.instance
        .getRecentPRs(DateTime.now().subtract(Duration(days: _recentDays)));
    if (mounted) {
      setState(() {
        _recentPRs = recent;
      });
    }
  }

  // Epley formula for estimated 1RM
  double _estimated1RM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.prDashboardTitle,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            Tab(text: l10n.prDashboardAllTime),
            Tab(text: l10n.prDashboardRecent),
            Tab(text: l10n.prDashboardByRepRange),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllTimeTab(l10n, colorScheme),
                _buildRecentTab(l10n, colorScheme),
                _buildRepRangeTab(l10n, colorScheme),
              ],
            ),
    );
  }

  Widget _buildAllTimeTab(AppLocalizations l10n, ColorScheme colorScheme) {
    final topPadding = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        kTextTabBarHeight;
    if (_allTimePRs.isEmpty) {
      return _buildEmptyState(l10n, topPadding);
    }

    final exercises = _allTimePRs.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          DesignConstants.cardPaddingInternal,
          topPadding + DesignConstants.spacingM,
          DesignConstants.cardPaddingInternal,
          0,
        ),
        itemCount: exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == exercises.length) {
            return const BottomContentSpacer();
          }
          final exerciseName = exercises[index];
          final sets = _allTimePRs[exerciseName]!;
          // Best set: highest estimated 1RM
          final bestSet = sets.reduce((a, b) {
            final aE1RM = _estimated1RM(
                (a['weight'] as num).toDouble(), a['reps'] as int);
            final bE1RM = _estimated1RM(
                (b['weight'] as num).toDouble(), b['reps'] as int);
            return aE1RM >= bE1RM ? a : b;
          });

          return Padding(
            padding:
                const EdgeInsets.only(bottom: DesignConstants.spacingS),
            child: SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exerciseName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                                DesignConstants.borderRadiusS),
                          ),
                          child: Text(
                            '${_estimated1RM((bestSet['weight'] as num).toDouble(), bestSet['reps'] as int).toStringAsFixed(1)} kg  ${l10n.prDashboardEstimated1RM}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Wrap(
                      spacing: DesignConstants.spacingS,
                      runSpacing: DesignConstants.spacingXS,
                      children: sets.map((s) {
                        final w = (s['weight'] as num).toDouble();
                        final r = s['reps'] as int;
                        return _PrChip(
                          weight: w,
                          reps: r,
                          colorScheme: colorScheme,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTab(AppLocalizations l10n, ColorScheme colorScheme) {
    final topPadding = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        kTextTabBarHeight;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          SizedBox(height: topPadding + DesignConstants.spacingM),
          // Time window selector
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.cardPaddingInternal),
            child: SummaryCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.cardPaddingInternal,
                    vertical: DesignConstants.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeFilterChip(
                      label: l10n.prDashboardLast30Days,
                      selected: _recentDays == 30,
                      onTap: () {
                        setState(() => _recentDays = 30);
                        _reloadRecent();
                      },
                    ),
                    _TimeFilterChip(
                      label: l10n.prDashboardLast90Days,
                      selected: _recentDays == 90,
                      onTap: () {
                        setState(() => _recentDays = 90);
                        _reloadRecent();
                      },
                    ),
                    _TimeFilterChip(
                      label: l10n.prDashboardAllTime2,
                      selected: _recentDays == _allTimeDays,
                      onTap: () {
                        setState(() => _recentDays = _allTimeDays);
                        _reloadRecent();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Expanded(
            child: _recentPRs.isEmpty
                ? Center(
                    child: Padding(
                      padding: DesignConstants.cardPadding,
                      child: Text(
                        l10n.prDashboardNoData,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.cardPaddingInternal),
                    itemCount: _recentPRs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _recentPRs.length) {
                        return const BottomContentSpacer();
                      }
                      final pr = _recentPRs[index];
                      final exercise = pr['exercise'] as String;
                      final weight = (pr['weight'] as num).toDouble();
                      final reps = pr['reps'] as int;
                      final achievedAtStr = pr['achieved_at'] as String?;
                      DateTime? achievedAt;
                      if (achievedAtStr != null) {
                        try {
                          achievedAt = DateTime.parse(achievedAtStr);
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingS),
                        child: SummaryCard(
                          child: ListTile(
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(Icons.emoji_events_rounded,
                                    color: colorScheme.primary, size: 22),
                              ),
                            ),
                            title: Text(
                              exercise,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: achievedAt != null
                                ? Text(DateFormat.yMMMd()
                                    .format(achievedAt))
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$weight kg × $reps',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.prDashboardNewPR,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepRangeTab(AppLocalizations l10n, ColorScheme colorScheme) {
    final topPadding = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        kTextTabBarHeight;

    // Filter PRs by selected rep range (± 1 rep tolerance)
    final filtered = <String, Map<String, dynamic>>{};
    for (final entry in _allTimePRs.entries) {
      Map<String, dynamic>? best;
      double bestWeight = 0;
      for (final pr in entry.value) {
        final reps = pr['reps'] as int;
        final weight = (pr['weight'] as num).toDouble();
        // Match rep range: for "10+" range match reps >= 10, otherwise exact
        final matches = _selectedRepRange >= 10
            ? reps >= 10
            : (reps == _selectedRepRange);
        if (matches && weight > bestWeight) {
          bestWeight = weight;
          best = pr;
        }
      }
      if (best != null) {
        filtered[entry.key] = best;
      }
    }

    final exercises = filtered.keys.toList()..sort();

    return Column(
      children: [
        SizedBox(height: topPadding + DesignConstants.spacingM),
        // Rep range selector
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.cardPaddingInternal),
          child: SummaryCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingM,
                  vertical: DesignConstants.spacingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _repRanges.map((rep) {
                  final label = rep >= 10
                      ? l10n.prDashboardRepRange10
                      : rep == 1
                          ? l10n.prDashboardRepRange1
                          : rep == 3
                              ? l10n.prDashboardRepRange3
                              : rep == 5
                                  ? l10n.prDashboardRepRange5
                                  : l10n.prDashboardRepRange8;
                  return _RepRangeChip(
                    label: label,
                    selected: _selectedRepRange == rep,
                    onTap: () => setState(() => _selectedRepRange = rep),
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: DesignConstants.cardPadding,
                    child: Text(
                      l10n.prDashboardNoData,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.cardPaddingInternal),
                  itemCount: exercises.length + 1,
                  itemBuilder: (context, index) {
                    if (index == exercises.length) {
                      return const BottomContentSpacer();
                    }
                    final exerciseName = exercises[index];
                    final pr = filtered[exerciseName]!;
                    final weight = (pr['weight'] as num).toDouble();
                    final reps = pr['reps'] as int;
                    final e1rm = _estimated1RM(weight, reps);

                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: DesignConstants.spacingS),
                      child: SummaryCard(
                        child: ListTile(
                          title: Text(
                            exerciseName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${l10n.prDashboardEstimated1RM}: ${e1rm.toStringAsFixed(1)} kg'),
                          trailing: Text(
                            '$weight kg × $reps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, double topPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignConstants.cardPaddingInternal,
        topPadding + DesignConstants.spacingXXL,
        DesignConstants.cardPaddingInternal,
        0,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.prDashboardNoData,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrChip extends StatelessWidget {
  final double weight;
  final int reps;
  final ColorScheme colorScheme;

  const _PrChip({
    required this.weight,
    required this.reps,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(DesignConstants.borderRadiusS),
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} kg × $reps',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RepRangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RepRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
