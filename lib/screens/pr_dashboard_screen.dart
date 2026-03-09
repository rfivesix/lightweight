// lib/screens/pr_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// A screen showing personal records (PRs) across all exercises.
///
/// Displays all-time bests, recent PRs, and PRs grouped by rep range.
class PRDashboardScreen extends StatefulWidget {
  const PRDashboardScreen({super.key});

  @override
  State<PRDashboardScreen> createState() => _PRDashboardScreenState();
}

class _PRDashboardScreenState extends State<PRDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, PersonalRecord> _allTimePRs = {};
  List<PersonalRecord> _recentPRs = [];
  String _recentPRWindow = '30';

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
    if (!mounted) return;
    setState(() => _isLoading = true);

    final allTime = await WorkoutDatabaseHelper.instance.getPersonalRecords();
    final since = DateTime.now()
        .subtract(Duration(days: int.parse(_recentPRWindow)));
    final recent =
        await WorkoutDatabaseHelper.instance.getRecentPersonalRecords(since);

    if (mounted) {
      setState(() {
        _allTimePRs = allTime;
        _recentPRs = recent;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRecentWindow(String days) async {
    if (_recentPRWindow == days) return;
    setState(() => _recentPRWindow = days);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + kTextTabBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: l10n.pr_dashboard,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.allTimePRs),
            Tab(text: l10n.recentPRs),
            Tab(text: l10n.prsByRepRange),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _AllTimePRsTab(prs: _allTimePRs, topPadding: topPadding),
                _RecentPRsTab(
                  prs: _recentPRs,
                  window: _recentPRWindow,
                  onWindowChanged: _changeRecentWindow,
                  topPadding: topPadding,
                ),
                _PRsByRepRangeTab(
                    prs: _allTimePRs, topPadding: topPadding),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// ALL-TIME PRs TAB
// ---------------------------------------------------------------------------

class _AllTimePRsTab extends StatelessWidget {
  final Map<String, PersonalRecord> prs;
  final double topPadding;

  const _AllTimePRsTab({required this.prs, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (prs.isEmpty) {
      return Center(
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Text(
            l10n.noPRsFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ),
      );
    }

    final sorted = prs.values.toList()
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: DesignConstants.cardPadding.copyWith(top: topPadding),
        itemCount: sorted.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
              child: Text(
                '${sorted.length} ${l10n.allTimePRs}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            );
          }
          final pr = sorted[index - 1];
          return _PRTile(pr: pr);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RECENT PRs TAB
// ---------------------------------------------------------------------------

class _RecentPRsTab extends StatelessWidget {
  final List<PersonalRecord> prs;
  final String window;
  final ValueChanged<String> onWindowChanged;
  final double topPadding;

  const _RecentPRsTab({
    required this.prs,
    required this.window,
    required this.onWindowChanged,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPadding),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignConstants.cardPaddingInternal,
            DesignConstants.spacingM,
            DesignConstants.cardPaddingInternal,
            0,
          ),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: '30', label: Text(l10n.last30Days)),
              ButtonSegment(value: '90', label: Text(l10n.last90Days)),
            ],
            selected: {window},
            onSelectionChanged: (s) => onWindowChanged(s.first),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Expanded(
          child: prs.isEmpty
              ? Center(
                  child: Padding(
                    padding: DesignConstants.cardPadding,
                    child: Text(
                      l10n.noPRsFound,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: DesignConstants.cardPadding,
                  itemCount: prs.length,
                  itemBuilder: (context, index) =>
                      _PRTile(pr: prs[index], showDate: true),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PRs BY REP RANGE TAB
// ---------------------------------------------------------------------------

class _PRsByRepRangeTab extends StatelessWidget {
  final Map<String, PersonalRecord> prs;
  final double topPadding;

  const _PRsByRepRangeTab({required this.prs, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (prs.isEmpty) {
      return Center(
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Text(
            l10n.noPRsFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ),
      );
    }

    final ranges = [
      _RepRangeGroup(label: l10n.repRange1to3, min: 1, max: 3),
      _RepRangeGroup(label: l10n.repRange4to6, min: 4, max: 6),
      _RepRangeGroup(label: l10n.repRange7to12, min: 7, max: 12),
      _RepRangeGroup(label: l10n.repRange13plus, min: 13, max: 999),
    ];

    for (final pr in prs.values) {
      for (final range in ranges) {
        if (pr.reps >= range.min && pr.reps <= range.max) {
          range.prs.add(pr);
        }
      }
    }

    for (final range in ranges) {
      range.prs.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
    }

    return ListView(
      padding: DesignConstants.cardPadding.copyWith(top: topPadding),
      children: [
        for (final range in ranges)
          if (range.prs.isNotEmpty) ...[
            _buildRepRangeSection(context, range),
            const SizedBox(height: DesignConstants.spacingM),
          ],
        const BottomContentSpacer(),
      ],
    );
  }

  Widget _buildRepRangeSection(
      BuildContext context, _RepRangeGroup range) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              bottom: DesignConstants.spacingXS, left: 4),
          child: Text(
            range.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...range.prs.map((pr) => _PRTile(pr: pr)),
      ],
    );
  }
}

class _RepRangeGroup {
  final String label;
  final int min;
  final int max;
  final List<PersonalRecord> prs = [];

  _RepRangeGroup({required this.label, required this.min, required this.max});
}

// ---------------------------------------------------------------------------
// SHARED: PR TILE
// ---------------------------------------------------------------------------

class _PRTile extends StatelessWidget {
  final PersonalRecord pr;
  final bool showDate;

  const _PRTile({required this.pr, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().format(pr.date);

    return SummaryCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.spacingL,
          vertical: DesignConstants.spacingM,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.exerciseName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pr.weightKg.toStringAsFixed(pr.weightKg.truncateToDouble() == pr.weightKg ? 0 : 1)} kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '× ${pr.reps}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
