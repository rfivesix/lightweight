import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/dialogs/log_supplement_dialog_content.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/dialogs/water_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/add_measurement_screen.dart';
import 'package:lightweight/screens/diary_screen.dart';
import 'package:lightweight/screens/edit_routine_screen.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/profile_screen.dart';
import 'package:lightweight/screens/routines_screen.dart';
import 'package:lightweight/screens/statistics_hub_screen.dart';
import 'package:lightweight/screens/workout_hub_screen.dart';
import 'package:lightweight/services/profile_service.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/theme/color_constants.dart';
import 'package:lightweight/widgets/glass_bottom_nav_bar.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/keep_alive_page.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _tagebuchKey =
      GlobalKey<DiaryScreenState>();
  bool _isAddMenuOpen = false;
  late final AnimationController _menuController;
  double kNavBarHeight = 76.0; // aktuelle Höhe deiner GlassBottomNavBar
  double kBarFabGap = 12.0; // Abstand zwischen BottomBar und + Button

  double _safe01(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _menuController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavigationTapped(int index) {
    _pageController.jumpToPage(index);
  }

  void _toggleAddMenu() {
    setState(() {
      _isAddMenuOpen = !_isAddMenuOpen;
      if (_isAddMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _executeAddMenuAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'start_workout':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RoutinesScreen()));
        break;
      case 'add_measurement':
        final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (context) => const AddMeasurementScreen()));
        if (success == true) _refreshHomeScreen();
        break;
      case 'add_food':
        _handleAddFood();
        break;
      case 'add_liquid':
        _handleWaterAdd();
        break;
      case 'log_supplement':
        _handleSupplementAdd();
        break;
    }
  }

  Future<void> _refreshHomeScreen() async {
    // Renamed to DiaryScreen
    if (_currentIndex == 0) {
      _tagebuchKey.currentState?.loadDataForDate(DateTime.now());
    }
  }

  void _handleCreateRoutine() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const EditRoutineScreen()));
  }

  Future<void> _handleAddFood() async {
    final FoodItem? selectedFoodItem = await Navigator.of(context)
        .push<FoodItem>(
            MaterialPageRoute(builder: (context) => const AddFoodScreen()));

    if (selectedFoodItem == null || !mounted) return;

    final result = await _showQuantityDialog(selectedFoodItem);
    if (result == null || !mounted) return;

    final int quantity = result.$1; // ml ~ g
    final DateTime timestamp = result.$2;
    final bool countAsWater = result.$3;
    final String mealType = result.$4;
    final double? caffeinePer100ml = result.$5; // mg per 100 ml

    final newEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: mealType,
    );

    // ⬇️ wir bekommen jetzt die ID zurück
    final int newId = await DatabaseHelper.instance.insertFoodEntry(newEntry);

    if (countAsWater) {
      await DatabaseHelper.instance.insertWaterEntry(quantity, timestamp);
    }

    // Koffein-Log: nur bei Getränken (countAsWater) und wenn ein Wert angegeben ist
    await DatabaseHelper.instance.upsertCaffeineForFoodEntry(
      foodEntryId: newId,
      timestamp: timestamp,
      caffeinePer100ml: (countAsWater ? caffeinePer100ml : null),
      quantityInMl: quantity.toDouble(), // mg = mg/100ml * (ml/100)
    );

    _refreshHomeScreen();
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

  Future<void> _handleWaterAdd() async {
    final result = await _showWaterDialog();
    if (result != null) {
      await DatabaseHelper.instance.insertWaterEntry(result.$1, result.$2);
      _refreshHomeScreen();
    }
  }

  Future<void> _handleSupplementAdd() async {
    final allSupplements = await DatabaseHelper.instance.getAllSupplements();
    if (!mounted || allSupplements.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final Supplement? selectedSupplement = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logIntakeTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allSupplements.length,
            itemBuilder: (context, index) {
              final supplement = allSupplements[index];
              return ListTile(
                title: Text(localizeSupplementName(supplement, l10n)),
                onTap: () => Navigator.of(context).pop(supplement),
              );
            },
          ),
        ),
      ),
    );

    if (selectedSupplement != null && mounted) {
      _logSupplement(selectedSupplement);
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
          timestamp: result.$2);
      await DatabaseHelper.instance.insertSupplementLog(newLog);
      _refreshHomeScreen();
    }
  }

  Future<(int, DateTime, bool, String, double?)?> _showQuantityDialog(
      FoodItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();
    return showDialog<(int, DateTime, bool, String, double?)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          content: QuantityDialogContent(key: dialogStateKey, item: item),
          actions: [
            TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: Text(l10n.add_button),
              onPressed: () {
                final state = dialogStateKey.currentState;
                if (state != null) {
                  final quantity = int.tryParse(state.quantityText);
                  final caffeine =
                      double.tryParse(state.caffeineText.replaceAll(',', '.'));
                  if (quantity != null && quantity > 0) {
                    Navigator.of(context).pop((
                      quantity,
                      state.selectedDateTime,
                      state.countAsWater,
                      state.selectedMealType,
                      caffeine
                    ));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<(int, DateTime)?> _showWaterDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<WaterDialogContentState> dialogStateKey = GlobalKey();
    return showDialog<(int, DateTime)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.add_liquid_title),
          content: WaterDialogContent(key: dialogStateKey),
          actions: [
            TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: Text(l10n.add_button),
              onPressed: () {
                final state = dialogStateKey.currentState;
                if (state != null) {
                  final quantity = int.tryParse(state.quantityText);
                  if (quantity != null && quantity > 0) {
                    Navigator.of(context)
                        .pop((quantity, state.selectedDateTime));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, int index, AppLocalizations l10n) {
    String title = '';
    // Handle titles for Train, Stats, and Profile screens
    switch (index) {
      case 1:
        title = 'Workout'; // TODO: l10n
        return AppBar(
          title: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      case 2:
        return AppBar(
          title: Text(
            l10n.statistics, // ← NEW (or l10n.stats)
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      case 3:
        // The profile screen's AppBar is now managed here.
        return AppBar(
          title: Text(
            l10n.profile,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      case 0:
      default:
        // The Diary Screen has a special, dynamic AppBar
        return AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: DiaryAppBar(
            // Pass the state's notifier directly IF the state exists
            selectedDateNotifier:
                _tagebuchKey.currentState?.selectedDateNotifier,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _tagebuchKey.currentState?.navigateDay(false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                _tagebuchKey.currentState?.pickDate();
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _tagebuchKey.currentState?.navigateDay(true);
              },
            ),
          ],
        );
    }
  }

  List<Map<String, dynamic>> _getSpeedDialActions(AppLocalizations l10n) {
    return [
      {
        'icon': Icons.local_drink,
        'label': l10n.addLiquidOption,
        'action': 'add_liquid'
      },
      {
        'icon': Icons.restaurant_menu,
        'label': l10n.addFoodOption,
        'action': 'add_food'
      },
      {
        'icon': Icons.straighten_outlined,
        'label': l10n.addMeasurement,
        'action': 'add_measurement'
      },
      {
        'icon': Icons.fitness_center,
        'label': l10n.startWorkout,
        'action': 'start_workout'
      },
      {
        'icon': Icons.medication_outlined,
        'label': l10n.logIntakeTitle,
        'action': 'log_supplement'
      },
    ];
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = Provider.of<ProfileService>(context);

    // Workout-Status (nur UI, Logik bleibt)
    final manager = context.watch<WorkoutSessionManager>();
    final bool isWorkoutRunning = manager.isActive; // ✅
    final String elapsed = _formatDuration(manager.elapsedDuration); // ✅
    const basePad = 120.0; // nav bar + FAB visual height
    final runningPad = manager.isActive ? 68.0 : 0.0;

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          appBar: _buildAppBar(context, _currentIndex, l10n),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: <Widget>[
              KeepAlivePage(
                  storageKey: const PageStorageKey('tab_tagebuch'),
                  child: DiaryScreen(key: _tagebuchKey)),
              const KeepAlivePage(
                  storageKey: PageStorageKey('tab_workout'),
                  child: WorkoutHubScreen()),
              const KeepAlivePage(
                  storageKey: PageStorageKey('tab_stats'),
                  child: StatisticsHubScreen()),
              const KeepAlivePage(
                  storageKey: PageStorageKey('tab_profile'),
                  child: ProfileScreen()),
            ],
          ),
        ),

        // RUNNING WORKOUT BAR (oberhalb der BottomBar)
        if (isWorkoutRunning)
          Positioned(
            bottom: 24 + kNavBarHeight + kBarFabGap,
            // Abstand: BottomBar-Höhe + 8
            left: 16,
            right: 16,
            child: _FrostedBar(
              child: _RunningWorkoutRow(
                timeText: elapsed,
                onContinue: () {
                  final log = context.read<WorkoutSessionManager>().workoutLog;
                  if (log != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveWorkoutScreen(workoutLog: log, routine: null),
                      ),
                    );
                  }
                },
                onDiscard: () async {
                  final l10n = AppLocalizations.of(context)!;
                  final wsm = context.read<WorkoutSessionManager>();
                  final logId = wsm.workoutLog?.id;

                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.discard_button),
                      content: Text(l10n.dialogFinishWorkoutBody),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel)),
                        FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.discard_button)),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    if (logId != null) {
                      await WorkoutDatabaseHelper.instance
                          .deleteWorkoutLog(logId);
                    }
                    await wsm.finishWorkout();
                  }
                },
                l10n: l10n,
              ),
            ),
          ),

        // GLASS BOTTOM NAV BAR (deine kombinierte Leiste)

        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bottom bar takes the remaining width
              Expanded(
                child: GlassBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: _onNavigationTapped,
                  onFabTap: _toggleAddMenu, // now ignored by the bar
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.book_outlined),
                      label: l10n.diary,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.fitness_center_outlined),
                      label: l10n.workout,
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart_outlined),
                      label: 'Stats', //l10n.statistics,
                    ),
                    BottomNavigationBarItem(
                      icon: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: profileService.profileImagePath != null
                            ? FileImage(File(profileService.profileImagePath!))
                            : null,
                        child: profileService.profileImagePath == null
                            ? const Icon(Icons.person,
                                size: 16, color: Colors.black54)
                            : null,
                      ),
                      label: l10n.profile,
                    ),
                  ],
                ),
              ),
              SizedBox(width: kBarFabGap),
              // Detached GlassFab (+)
              GlassFab(
                onPressed: _toggleAddMenu,
                icon: Icons.add,
                // label: null, // keep it square; add a label if you want a pill
              ),
            ],
          ),
        ),

        // SPEED-DIAL (unverändert)
        AnimatedBuilder(
          animation: _menuController,
          builder: (context, _) {
            final v = _safe01(_menuController.value);
            return Offstage(
              offstage: v == 0.0,
              child: IgnorePointer(
                ignoring: v == 0.0,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: v,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAddMenuOpen = false;
                            _menuController.reverse();
                          });
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 6.0 * v, sigmaY: 6.0 * v),
                          child: Container(
                              color: Colors.black.withOpacity(0.4 * v)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100.0,
                      right: 20.0,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _getSpeedDialActions(l10n)
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final action = entry.value;
                            final curved = CurvedAnimation(
                              parent: _menuController,
                              curve: Interval(
                                  (index * 0.12).clamp(0.0, 0.95), 1.0,
                                  curve: Curves.easeOutBack),
                            );
                            final tv = _safe01(curved.value);
                            final offsetY = 90.0 * (index + 1);
                            return Transform.translate(
                              offset: Offset(0, (1 - tv) * offsetY),
                              child: Opacity(
                                opacity: tv,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        action['label'],
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.black87
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            _isAddMenuOpen = false;
                                            _menuController.reverse();
                                          });
                                          _executeAddMenuAction(
                                              action['action']);
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 12, sigmaY: 12),
                                            child: Container(
                                              width: 76,
                                              height: 76,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                action['icon'],
                                                size: 34,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FrostedBar extends StatelessWidget {
  final Widget child;
  const _FrostedBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summary_card_dark_mode : summary_card_white_mode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.30)
                  : Colors.black.withOpacity(0.10),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RunningWorkoutRow extends StatelessWidget {
  final String timeText;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;
  final AppLocalizations l10n;

  const _RunningWorkoutRow({
    required this.timeText,
    required this.onContinue,
    required this.onDiscard,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  decoration: TextDecoration.none, // ← remove underline
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.continue_workout_button),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.discard_button),
        ),
      ],
    );
  }
}
