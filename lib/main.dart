// lib/main.dart
// VOLLSTÄNDIGER CODE (KORRIGIERT)

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/main_screen.dart';
import 'package:lightweight/services/profile_service.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/screens/onboarding_screen.dart';
import 'package:lightweight/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Erstelle die Manager-Instanz
  final workoutSessionManager = WorkoutSessionManager();

  // 2. Rufe die neue, gekapselte Wiederherstellungsmethode auf
  // Annahme: Diese Methode existiert jetzt in deinem WorkoutSessionManager
  // await workoutSessionManager.tryRestoreSession();

  final themeService = ThemeService(); // Create an instance
  // 3. Starte die App mit der (möglicherweise wiederhergestellten) Instanz
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: workoutSessionManager),
        ChangeNotifierProvider(
          create: (context) {
            final profileService = ProfileService();
            profileService.initialize();
            return profileService;
          },
        ),
        ChangeNotifierProvider.value(
            value: themeService), // Provide the ThemeService
      ],
      child: const MyApp(),
    ),
  );
}

Future<bool> _hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding') == true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    const cardDark = Color(0xFF171717);
    const cardLight = Color(0xFFF3F3F3);

    // HINWEIS: Provider.of<ThemeService>(context) wurde von hier entfernt.

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // === Akzent/Seed aus Dynamic Color (Android 12+) oder Fallback ===
        final Color lightSeed = lightDynamic?.primary ?? Colors.blue;
        final Color darkSeed = darkDynamic?.primary ?? lightSeed;

        // --- Light Scheme aus Seed, aber ohne Material You UI ---
        final lightScheme = ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
        );

        // --- Dark Scheme aus Seed + OLED-Schwarz ---
        final seededDark = ColorScheme.fromSeed(
          seedColor: darkSeed,
          brightness: Brightness.dark,
        );
        final darkScheme = seededDark.copyWith(
          surface: Colors.black,
          surfaceDim: Colors.black,
          surfaceBright: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: Colors.black,
          surfaceContainer: Colors.black,
          surfaceContainerHigh: Colors.black,
          surfaceContainerHighest: Colors.black,
        );

        // --- Light Theme (Material2, aber mit ColorScheme aus Seed) ---
        final baseLightTheme = ThemeData(
          useMaterial3: false, // KEIN Material You
          colorScheme: lightScheme,
          primaryColor: lightScheme.primary, // Akzent in M2-Welten
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: cardLight,
          // NEU / ANGEPASST:
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightScheme.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: lightScheme.primary,
            contentTextStyle: TextStyle(
              color: lightScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.black.withOpacity(0.08),
            thickness: 1,
            space: 24,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: false,
          ),
          textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Inter', // Das ist weiterhin korrekt
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
          // Stellen sicher, dass Akzent sichtbar "lebt"
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightScheme.primary,
              foregroundColor: lightScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightScheme.primary,
            foregroundColor: lightScheme.onPrimary,
          ),
          //toggleableActiveColor: lightScheme.primary,
          progressIndicatorTheme:
              ProgressIndicatorThemeData(color: lightScheme.primary),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: lightScheme.primary,
            selectionColor: lightScheme.primary.withOpacity(0.25),
            selectionHandleColor: lightScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(lightScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor:
                WidgetStateProperty.resolveWith((s) => lightScheme.primary),
            trackColor: WidgetStateProperty.resolveWith(
                (s) => lightScheme.primary.withOpacity(0.5)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );

        // --- Dark Theme (Material2, OLED, Akzent aus Seed) ---
        final baseDarkTheme = ThemeData(
          useMaterial3: false, // KEIN Material You
          colorScheme: darkScheme,
          primaryColor: darkScheme.primary, // Akzent in M2-Welten
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          cardColor: cardDark,
          // NEU / ANGEPASST:
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            },
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1C1C1C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: darkScheme.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),

          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            elevation: 0,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: darkScheme.primary,
            contentTextStyle: TextStyle(
              color: darkScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          dividerTheme: DividerThemeData(
            color: Colors.white.withOpacity(0.08),
            thickness: 1,
            space: 24,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            centerTitle: false,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Inter', // Das ist weiterhin korrekt
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkScheme.primary,
              foregroundColor: darkScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkScheme.primary,
            foregroundColor: darkScheme.onPrimary,
          ),
          //toggleableActiveColor: darkScheme.primary,
          progressIndicatorTheme:
              ProgressIndicatorThemeData(color: darkScheme.primary),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: darkScheme.primary,
            selectionColor: darkScheme.primary.withOpacity(0.35),
            selectionHandleColor: darkScheme.primary,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(darkScheme.primary),
          ),
          switchTheme: SwitchThemeData(
            thumbColor:
                WidgetStateProperty.resolveWith((s) => darkScheme.primary),
            trackColor: WidgetStateProperty.resolveWith(
                (s) => darkScheme.primary.withOpacity(0.5)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
// KORREKTUR HIER: Wir verwenden einen Consumer, um an den ThemeService zu kommen.
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              scrollBehavior: NoGlowScrollBehavior(),
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              title: "LightWeight",
              theme: baseLightTheme,
              darkTheme: baseDarkTheme,
              themeMode:
                  themeService.themeMode, // Jetzt funktioniert der Zugriff
              home: child, // Das home-Widget wird weitergereicht
            );
          },
          // Der FutureBuilder wird zum 'child' des Consumers, um nicht bei jeder
          // Theme-Änderung neu aufgebaut zu werden.
          child: FutureBuilder<bool>(
            future: _hasSeenOnboarding(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final seen = snapshot.data ?? false;
              return seen ? const MainScreen() : const OnboardingScreen();
            },
          ),
        );
      },
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Keine Glow-Effekte
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // iOS-Style: Bouncing
    return const BouncingScrollPhysics();
  }
}
