// lib/screens/main_screen.dart (Final & Vollständig Korrigiert)

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/home.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/nutrition_hub_screen.dart';
import 'package:lightweight/screens/profile_screen.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/util/time_util.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:provider/provider.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/add_measurement_screen.dart';
import 'package:lightweight/screens/routines_screen.dart';
import 'package:lightweight/widgets/add_menu_sheet.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/dialogs/water_dialog_content.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/screens/workout_hub_screen.dart';
import 'package:lightweight/screens/statistics_hub_screen.dart';
import 'package:lightweight/services/profile_service.dart';
import 'package:lightweight/widgets/keep_alive_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late final TabController _tabController;

  // KORREKTUR 1: Der Key verwendet jetzt den öffentlichen Klassennamen 'HomeState'.
  final GlobalKey<HomeState> _homeKey = GlobalKey<HomeState>();

  late final List<Widget> _pages;
  bool _isAddMenuOpen = false;
  late final AnimationController _menuController;
  // Hilfsfunktion: NaN -> 0.0 und [0,1] clampen
  double _safe01(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    _pages = [
      KeepAlivePage(
        storageKey: const PageStorageKey('tab_home'),
        child: Home(key: _homeKey),
      ),
      const KeepAlivePage(
        storageKey: PageStorageKey('tab_nutrition'),
        child: NutritionHubScreen(),
      ),
      const KeepAlivePage(
        storageKey: PageStorageKey('tab_workout'),
        child: WorkoutHubScreen(),
      ),
      const KeepAlivePage(
        storageKey: PageStorageKey('tab_stats'),
        child: StatisticsHubScreen(),
      ),
      const KeepAlivePage(
        storageKey: PageStorageKey('tab_profile'),
        child: ProfileScreen(),
      ),
    ];

    // KORREKTUR 2: Der Controller wird jetzt konsistent mit der Länge von _pages (5) initialisiert.
    _tabController = TabController(length: _pages.length, vsync: this);
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ZENTRALISIERTE LOGIK
  // ===========================================================================

  Future<void> _refreshHomeScreen() async {
    if (_tabController.index == 0) {
      _homeKey.currentState?.loadAllHomeScreenData();
    }
  }

  void _addFoodItem(FoodItem item) async {
    final result = await _showQuantityDialog(item);
    if (result != null && mounted) {
      final quantity = result.$1;
      final timestamp = result.$2;
      final countAsWater = result.$3;
      final mealType = result.$4;
      final newEntry = FoodEntry(
          barcode: item.barcode,
          timestamp: timestamp,
          quantityInGrams: quantity,
          mealType: mealType);
      await DatabaseHelper.instance.insertFoodEntry(newEntry);
      if (countAsWater) {
        await DatabaseHelper.instance.insertWaterEntry(quantity, timestamp);
      }
      _refreshHomeScreen();
    }
  }

  void _addWater(int quantityInMl, DateTime timestamp) async {
    await DatabaseHelper.instance.insertWaterEntry(quantityInMl, timestamp);
    _refreshHomeScreen();
  }

  void _showAddMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => const AddMenuSheet(),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case 'start_workout':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RoutinesScreen()));
        break;
      case 'add_measurement':
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (context) => const AddMeasurementScreen()))
            .then((success) {
          if (success == true) _refreshHomeScreen();
        });
        break;
      case 'add_food':
        final selectedFoodItem = await Navigator.of(context).push<FoodItem>(
            MaterialPageRoute(builder: (context) => const AddFoodScreen()));
        if (selectedFoodItem != null) _addFoodItem(selectedFoodItem);
        break;
      case 'add_liquid':
        final waterResult = await _showWaterDialog();
        if (waterResult != null) _addWater(waterResult.$1, waterResult.$2);
        break;
    }
  }

  Future<(int, DateTime)?> _showWaterDialog() async {
    final GlobalKey<WaterDialogContentState> dialogStateKey =
        GlobalKey<WaterDialogContentState>();
    return showDialog<(int, DateTime)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Flüssigkeit hinzufügen"),
          content: WaterDialogContent(key: dialogStateKey),
          actions: [
            TextButton(
                child: const Text("Abbrechen"),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: const Text("Hinzufügen"),
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

  Future<(int, DateTime, bool, String)?> _showQuantityDialog(
      FoodItem item) async {
    final GlobalKey<QuantityDialogContentState> dialogStateKey =
        GlobalKey<QuantityDialogContentState>();
    return showDialog<(int, DateTime, bool, String)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          content: QuantityDialogContent(key: dialogStateKey, item: item),
          actions: [
            TextButton(
                child: const Text("Abbrechen"),
                onPressed: () => Navigator.of(context).pop(null)),
            FilledButton(
              child: const Text("Hinzufügen"),
              onPressed: () {
                final state = dialogStateKey.currentState;
                if (state != null) {
                  final quantity = int.tryParse(state.quantityText);
                  if (quantity != null && quantity > 0) {
                    Navigator.of(context).pop((
                      quantity,
                      state.selectedDateTime,
                      state.countAsWater,
                      state.selectedMealType
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

  // ===========================================================================
  // Diese Methode wird jetzt vom neuen UI aufgerufen
  void _executeAddMenuAction(String action) async {
    // KORREKTUR: Die Navigations-Logik aus deiner AddMenuSheet ist jetzt hier.
    switch (action) {
      case 'start_workout':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RoutinesScreen()));
        break;
      case 'add_measurement':
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (context) => const AddMeasurementScreen()))
            .then((success) {
          if (success == true) _refreshHomeScreen();
        });
        break;
      case 'add_food':
        final selectedFoodItem = await Navigator.of(context).push<FoodItem>(
            MaterialPageRoute(builder: (context) => const AddFoodScreen()));
        if (selectedFoodItem != null) _addFoodItem(selectedFoodItem);
        break;
      case 'add_liquid':
        final waterResult = await _showWaterDialog();
        if (waterResult != null) _addWater(waterResult.$1, waterResult.$2);
        break;
    }
  }
// In lib/screens/main_screen.dart

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> speedDialActions = [
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
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.0),
                child: Container(color: Colors.transparent, height: 0.0)),
            title: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 0.0, color: Colors.transparent),
              ),
              indicatorColor: Colors.transparent,
              indicatorWeight: 0.0001,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.0,
              ),
              tabs: [
                const Tab(text: 'Home'),
                const Tab(text: 'Food'),
                const Tab(text: 'Train'),
                const Tab(text: 'Stats'),
                // KORREKTUR: Der Profil-Tab reagiert jetzt auf seine Auswahl.
                // Erhöht den Radius, wenn der Tab ausgewählt ist.
                AnimatedBuilder(
                  // HINZUGEFÜGT: animated, damit die Größe sich animiert
                  animation: _tabController,
                  builder: (context, child) {
                    final isProfileSelected =
                        _tabController.index == 4; // Index des Profil-Tabs
                    final double radius =
                        isProfileSelected ? 21 : 19; // Größer, wenn aktiv
                    final double iconSize =
                        isProfileSelected ? 24 : 22; // Icon-Größe anpassen

                    return Consumer<ProfileService>(
                      builder: (context, profileService, child) {
                        return Tab(
                          icon: CircleAvatar(
                            radius: radius, // Dynamischer Radius
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage:
                                profileService.profileImagePath != null
                                    ? FileImage(
                                        File(profileService.profileImagePath!))
                                    : null,
                            child: profileService.profileImagePath == null
                                ? Icon(Icons.person,
                                    size: iconSize,
                                    color:
                                        Colors.black54) // Dynamische Icon-Größe
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _pages,
          ),
          floatingActionButton: GlassFab(
            onPressed: () {
              setState(() {
                _isAddMenuOpen = !_isAddMenuOpen;
                if (_isAddMenuOpen) {
                  _menuController.forward();
                } else {
                  _menuController.reverse();
                }
              });
            },
          ),
          bottomNavigationBar: Consumer<WorkoutSessionManager>(
            builder: (context, manager, child) {
              if (!manager.isActive) {
                return const SizedBox.shrink();
              }

              return BottomAppBar(
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(manager.elapsedDuration),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Row(
                        // KORREKTUR: Die Buttons in eine eigene Row packen
                        children: [
                          // HINZUGEFÜGT: Der "Verwerfen"-Knopf
                          TextButton(
                            onPressed: () async {
                              final logId = manager.workoutLog?.id;
                              if (logId != null) {
                                await WorkoutDatabaseHelper.instance
                                    .deleteWorkoutLog(logId);
                              }
                              manager
                                  .finishWorkout(); // Beendet die Session im Manager
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red
                                  .shade600, // Auffälliges Rot für die Warnung
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Verwerfen'),
                          ),
                          const SizedBox(
                              width: 8), // Abstand zwischen den Knöpfen
                          ElevatedButton(
                            onPressed: () {
                              if (manager.workoutLog != null &&
                                  manager.workoutLog!.id != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LiveWorkoutScreen(
                                      workoutLog: manager.workoutLog!,
                                      routine: null,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.onPrimary,
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            child: const Text('Workout fortsetzen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
// Overlay & Speed-Dial
        AnimatedBuilder(
          animation: _menuController,
          builder: (context, _) {
            // Fortschritt sauber in [0,1]
            final v = _safe01(_menuController.value);

            return Offstage(
              // Wenn zu: gar nicht rendern / hittesten
              offstage: v == 0.0,
              child: IgnorePointer(
                // Wenn zu: keine Gesten durchlassen
                ignoring: v == 0.0,
                child: Stack(
                  children: [
                    // Blur-Overlay
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
                            sigmaX: 6.0 * v,
                            sigmaY: 6.0 * v,
                          ),
                          child: Container(
                            color: Colors.black.withOpacity(0.4 * v),
                          ),
                        ),
                      ),
                    ),

                    // Actions (gestaffelt vom FAB „hochfahren“)
                    Positioned(
                      bottom: 100.0,
                      right: 20.0,
                      child: Material(
                        color: Colors.transparent, // eigener Ink-Kontext -> kein gelber Balken mehr
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: speedDialActions.asMap().entries.map((entry) {

                          final index = entry.key;
                          final action = entry.value;

                          final curved = CurvedAnimation(
                            parent: _menuController,
                            curve: Interval(
                              (index * 0.12).clamp(0.0, 0.95),
                              1.0,
                              curve: Curves.easeOutBack,
                            ),
                          );

                          final tv = _safe01(curved.value);
                          final offsetY = 90.0 * (index + 1);

                          return Transform.translate(
                            offset: Offset(0, (1 - tv) * offsetY),
                            child: Opacity(
                              opacity: tv,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Text links
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
                                    // Glas-Icon rechts
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _isAddMenuOpen = false;
                                          _menuController.reverse();
                                        });
                                        _executeAddMenuAction(action['action']);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
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
