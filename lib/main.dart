import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // 👈 wichtig
import 'package:lightweight/screens/home.dart';
import 'package:lightweight/services/workout_session_manager.dart'; // 👈 dein Manager
import 'package:lightweight/generated/app_localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkoutSessionManager(),
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
        ColorScheme lightColorScheme =
            ColorScheme.fromSeed(seedColor: Colors.blue);
        ColorScheme darkColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: lightDynamic ?? lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const Home(),
        );
      },
    );
  }
}
