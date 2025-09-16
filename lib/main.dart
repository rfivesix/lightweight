// lib/main.dart (Endgültige Korrektur für DialogThemeData)

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/main_screen.dart';
import 'package:lightweight/services/profile_service.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutSessionManager()),
        ChangeNotifierProvider(
          create: (context) {
            final profileService = ProfileService();
            profileService.initialize();
            return profileService;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // --- ColorSchemes definieren ---
        ColorScheme lightColorScheme =
            ColorScheme.fromSeed(seedColor: Colors.blue);

        ColorScheme customDarkColorScheme = darkDynamic?.copyWith(
              brightness: Brightness.dark,
              primary: darkDynamic?.primary ?? Colors.blue,
              onPrimary: darkDynamic?.onPrimary ?? Colors.white,
              background: Colors.black,
              surface: Colors.grey.shade900,
              surfaceContainerHighest: Colors.grey.shade800,
              scrim: Colors.black.withOpacity(0.5),
              onSurface: Colors.white,
              onBackground: Colors.white,
              onSurfaceVariant: Colors.grey.shade300,
            ) ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
              background: Colors.black,
              surface: Colors.grey.shade900,
              surfaceContainerHighest: Colors.grey.shade800,
              onSurface: Colors.white,
              onBackground: Colors.white,
              onSurfaceVariant: Colors.grey.shade300,
            );

        // --- Light Theme Definition ---
        final baseLightTheme = ThemeData(
          colorScheme: lightDynamic ?? lightColorScheme,
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: (lightDynamic ?? lightColorScheme)
                .surfaceContainerHighest
                .withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                  color: (lightDynamic ?? lightColorScheme).primary,
                  width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                  color: (lightDynamic ?? lightColorScheme).error, width: 2.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                  color: (lightDynamic ?? lightColorScheme).error, width: 2.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            hintStyle: TextStyle(
                color: (lightDynamic ?? lightColorScheme)
                    .onSurfaceVariant
                    .withOpacity(0.7)),
            labelStyle:
                TextStyle(color: (lightDynamic ?? lightColorScheme).onSurface),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              side:
                  BorderSide(color: (lightDynamic ?? lightColorScheme).primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
          ),
          listTileTheme: ListTileThemeData(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            tileColor: (lightDynamic ?? lightColorScheme).surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
          ),
          // KORREKTUR: Jetzt verwenden wir die korrekte Klasse `DialogThemeData`.
          dialogTheme: DialogThemeData(
            backgroundColor: (lightDynamic ?? lightColorScheme).surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            titleTextStyle: TextStyle(
                color: (lightDynamic ?? lightColorScheme).onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold),
            contentTextStyle: TextStyle(
                color: (lightDynamic ?? lightColorScheme).onSurfaceVariant,
                fontSize: 16),
          ),
        );

        // --- Dark Theme Definition ---
        final baseDarkTheme = ThemeData(
          colorScheme: customDarkColorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          cardColor: customDarkColorScheme.surface,
          dialogBackgroundColor: customDarkColorScheme.surface,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor:
                customDarkColorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  BorderSide(color: customDarkColorScheme.primary, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  BorderSide(color: customDarkColorScheme.error, width: 2.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  BorderSide(color: customDarkColorScheme.error, width: 2.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            hintStyle: TextStyle(
                color: customDarkColorScheme.onSurfaceVariant.withOpacity(0.7)),
            labelStyle: TextStyle(color: customDarkColorScheme.onSurface),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              side: BorderSide(color: customDarkColorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
          ),
          listTileTheme: ListTileThemeData(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            tileColor: customDarkColorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
          ),
          // KORREKTUR: Jetzt verwenden wir die korrekte Klasse `DialogThemeData`.
          dialogTheme: DialogThemeData(
            backgroundColor: customDarkColorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            titleTextStyle: TextStyle(
                color: customDarkColorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold),
            contentTextStyle: TextStyle(
                color: customDarkColorScheme.onSurfaceVariant, fontSize: 16),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: "LightWeight",
          theme: baseLightTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(baseLightTheme.textTheme),
          ),
          darkTheme: baseDarkTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(baseDarkTheme.textTheme),
          ),
          themeMode: ThemeMode.system,
          home: const MainScreen(),
        );
      },
    );
  }
}
