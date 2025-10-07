// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Vita';

  @override
  String get bannerText => 'Empfehlung / Aktuelles Workout';

  @override
  String get calories => 'Kalorien';

  @override
  String get water => 'Wasser';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Kohlenhydrate';

  @override
  String get fat => 'Fett';

  @override
  String get daily => 'Täglich';

  @override
  String get today => 'Heute';

  @override
  String get workoutSection => 'Workout-Bereich - noch nicht implementiert';

  @override
  String get addMenuTitle => 'Was möchtest du hinzufügen?';

  @override
  String get addFoodOption => 'Lebensmittel';

  @override
  String get addLiquidOption => 'Flüssigkeit';

  @override
  String get searchHintText => 'Suchen...';

  @override
  String get mealtypeBreakfast => 'Frühstück';

  @override
  String get mealtypeLunch => 'Mittagessen';

  @override
  String get mealtypeDinner => 'Abendessen';

  @override
  String get mealtypeSnack => 'Snack';

  @override
  String get waterHeader => 'Wasser & Getränke';

  @override
  String get openFoodFactsSource => 'Daten von Open Food Facts';

  @override
  String get tabRecent => 'Zuletzt';

  @override
  String get tabSearch => 'Suchen';

  @override
  String get tabFavorites => 'Favoriten';

  @override
  String get fabCreateOwnFood => 'Eigenes Lebensmittel';

  @override
  String get recentEmptyState =>
      'Deine zuletzt verwendeten Lebensmittel\nerscheinen hier.';

  @override
  String get favoritesEmptyState =>
      'Du hast noch keine Favoriten.\nMarkiere ein Lebensmittel mit dem Herz-Icon, um es hier zu sehen.';

  @override
  String get searchInitialHint => 'Bitte gib einen Suchbegriff ein.';

  @override
  String get searchNoResults => 'Keine Ergebnisse gefunden.';

  @override
  String get createFoodScreenTitle => 'Eigenes Lebensmittel erstellen';

  @override
  String get formFieldName => 'Name des Lebensmittels';

  @override
  String get formFieldBrand => 'Marke (optional)';

  @override
  String get formSectionMainNutrients => 'Haupt-Nährwerte (pro 100g)';

  @override
  String get formFieldCalories => 'Kalorien (kcal)';

  @override
  String get formFieldProtein => 'Protein (g)';

  @override
  String get formFieldCarbs => 'Kohlenhydrate (g)';

  @override
  String get formFieldFat => 'Fett (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Weitere Nährwerte (optional, pro 100g)';

  @override
  String get formFieldSugar => 'Davon Zucker (g)';

  @override
  String get formFieldFiber => 'Ballaststoffe (g)';

  @override
  String get formFieldKj => 'Kilojoule (kJ)';

  @override
  String get formFieldSalt => 'Salz (g)';

  @override
  String get formFieldSodium => 'Natrium (mg)';

  @override
  String get formFieldCalcium => 'Kalzium (mg)';

  @override
  String get buttonSave => 'Speichern';

  @override
  String get validatorPleaseEnterName => 'Bitte gib einen Namen ein.';

  @override
  String get validatorPleaseEnterNumber => 'Bitte gib eine gültige Zahl ein.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName wurde erfolgreich gespeichert.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portion';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Zucker';

  @override
  String get fiber => 'Ballaststoffe';

  @override
  String get salt => 'Salz';

  @override
  String get explorerScreenTitle => 'Lebensmittel-Explorer';

  @override
  String get nutritionScreenTitle => 'Ernährungsanalyse';

  @override
  String get entriesForDateRangeLabel => 'Einträge für';

  @override
  String get noEntriesForPeriod => 'Noch keine Einträge für diesen Zeitraum.';

  @override
  String get waterEntryTitle => 'Wasser';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileDailyGoals => 'Tägliche Ziele';

  @override
  String get snackbarGoalsSaved => 'Ziele erfolgreich gespeichert!';

  @override
  String get measurementsScreenTitle => 'Messwerte';

  @override
  String get measurementsEmptyState =>
      'Noch keine Messwerte erfasst.\nBeginne mit dem \'+\' Button.';

  @override
  String get addMeasurementDialogTitle => 'Neuer Messwert';

  @override
  String get formFieldMeasurementType => 'Art der Messung';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Wert ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Bitte Wert eingeben';

  @override
  String get measurementWeight => 'Körpergewicht';

  @override
  String get measurementFatPercent => 'Körperfett';

  @override
  String get measurementNeck => 'Nacken';

  @override
  String get measurementShoulder => 'Schulter';

  @override
  String get measurementChest => 'Brust';

  @override
  String get measurementLeftBicep => 'Linker Bizeps';

  @override
  String get measurementRightBicep => 'Rechter Bizeps';

  @override
  String get measurementLeftForearm => 'Linker Unterarm';

  @override
  String get measurementRightForearm => 'Rechter Unterarm';

  @override
  String get measurementAbdomen => 'Bauch';

  @override
  String get measurementWaist => 'Taille';

  @override
  String get measurementHips => 'Hüfte';

  @override
  String get measurementLeftThigh => 'Linker Oberschenkel';

  @override
  String get measurementRightThigh => 'Rechter Oberschenkel';

  @override
  String get measurementLeftCalf => 'Linke Wade';

  @override
  String get measurementRightCalf => 'Rechte Wade';

  @override
  String get drawerMenuTitle => 'Vita Menü';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerFoodExplorer => 'Lebensmittel-Explorer';

  @override
  String get drawerDataManagement => 'Datensicherung';

  @override
  String get drawerMeasurements => 'Messwerte';

  @override
  String get dataManagementTitle => 'Datensicherung';

  @override
  String get exportCardTitle => 'Daten exportieren';

  @override
  String get exportCardDescription =>
      'Sichert alle deine Tagebucheinträge, Favoriten und eigenen Lebensmittel in einer einzigen Backup-Datei.';

  @override
  String get exportCardButton => 'Backup erstellen';

  @override
  String get importCardTitle => 'Daten importieren';

  @override
  String get importCardDescription =>
      'Stellt deine Daten aus einer zuvor erstellten Backup-Datei wieder her. ACHTUNG: Alle aktuell in der App gespeicherten Daten werden dabei überschrieben!';

  @override
  String get importCardButton => 'Backup wiederherstellen';

  @override
  String get recommendationDefault => 'Tracke deine erste Mahlzeit!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Letzte $count Tage: +$difference kcal über dem Ziel';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Letzte $count Tage: $difference kcal unter dem Ziel';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Letzte $count Tage: Ziel erreicht ✅';
  }

  @override
  String get recommendationFirstEntry =>
      'Super, dein erster Eintrag ist gemacht!';

  @override
  String get dialogConfirmTitle => 'Bestätigung erforderlich';

  @override
  String get dialogConfirmImportContent =>
      'Möchtest du wirklich die Daten aus diesem Backup wiederherstellen?\n\nACHTUNG: Alle deine aktuellen Einträge, Favoriten und eigenen Lebensmittel werden unwiderruflich gelöscht und ersetzt.';

  @override
  String get dialogButtonCancel => 'Abbrechen';

  @override
  String get dialogButtonOverwrite => 'Ja, alles überschreiben';

  @override
  String get snackbarNoFileSelected => 'Keine Datei ausgewählt.';

  @override
  String get snackbarImportSuccessTitle => 'Import erfolgreich!';

  @override
  String get snackbarImportSuccessContent =>
      'Deine Daten wurden wiederhergestellt. Für eine korrekte Anzeige wird empfohlen, die App jetzt neu zu starten.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Fehler beim Importieren der Daten.';

  @override
  String get snackbarExportSuccess =>
      'Backup-Datei wurde an das System übergeben. Bitte wähle einen Speicherort.';

  @override
  String get snackbarExportFailed => 'Export abgebrochen oder fehlgeschlagen.';

  @override
  String get profileUserHeight => 'Körpergröße (cm)';

  @override
  String get workoutRoutinesTitle => 'Trainingspläne';

  @override
  String get workoutHistoryTitle => 'Workout-Verlauf';

  @override
  String get workoutHistoryButton => 'Verlauf';

  @override
  String get emptyRoutinesTitle => 'Keine Trainingspläne gefunden';

  @override
  String get emptyRoutinesSubtitle =>
      'Erstelle deinen ersten Trainingsplan oder starte ein freies Training.';

  @override
  String get createFirstRoutineButton => 'Ersten Plan erstellen';

  @override
  String get startEmptyWorkoutButton => 'Freies Training';

  @override
  String get editRoutineSubtitle =>
      'Tippen zum Bearbeiten, oder starte das Training.';

  @override
  String get startButton => 'Start';

  @override
  String get addRoutineButton => 'Neue Routine';

  @override
  String get freeWorkoutTitle => 'Freies Training';

  @override
  String get finishWorkoutButton => 'Beenden';

  @override
  String get addSetButton => 'Satz hinzufügen';

  @override
  String get addExerciseToWorkoutButton => 'Übung zum Workout hinzufügen';

  @override
  String get lastTimeLabel => 'Letztes Mal';

  @override
  String get setLabel => 'Satz';

  @override
  String get kgLabel => 'Gewicht (kg)';

  @override
  String get repsLabel => 'Wdh';

  @override
  String get restTimerLabel => 'Pause';

  @override
  String get skipButton => 'Überspringen';

  @override
  String get emptyHistory => 'Noch keine Workouts abgeschlossen.';

  @override
  String get workoutDetailsTitle => 'Workout-Details';

  @override
  String get workoutNotFound => 'Workout nicht gefunden.';

  @override
  String get totalVolumeLabel => 'Gesamtvolumen';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get hevyImportTitle => 'Hevy Import';

  @override
  String get hevyImportDescription =>
      'Importiere deine gesamte Trainings-Historie aus einer Hevy CSV-Exportdatei.';

  @override
  String get hevyImportButton => 'Hevy-Daten importieren';

  @override
  String hevyImportSuccess(Object count) {
    return '$count Workouts erfolgreich importiert!';
  }

  @override
  String get hevyImportFailed =>
      'Import fehlgeschlagen. Bitte überprüfe die Datei.';

  @override
  String get startWorkout => 'Workout starten';

  @override
  String get addMeasurement => 'Messwert hinzufügen';

  @override
  String get filterToday => 'Heute';

  @override
  String get filter7Days => '7 Tage';

  @override
  String get filter30Days => '30 Tage';

  @override
  String get filterAll => 'Alle';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showMoreDetails => 'Mehr Details anzeigen';

  @override
  String get deleteConfirmTitle => 'Löschen bestätigen';

  @override
  String get deleteConfirmContent =>
      'Möchtest du diesen Eintrag wirklich löschen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get tabBaseFoods => 'Grundnahrungsmittel';

  @override
  String get baseFoodsEmptyState =>
      'Dieser Bereich wird bald mit einer kuratierten Liste von Grundnahrungsmitteln wie Obst, Gemüse und mehr gefüllt sein.';

  @override
  String get noBrand => 'Keine Marke';

  @override
  String get unknown => 'Unbekannt';

  @override
  String backupFileSubject(String timestamp) {
    return 'Vita App Backup - $timestamp';
  }

  @override
  String foodItemSubtitle(String brand, int calories) {
    return '$brand - $calories kcal / 100g';
  }

  @override
  String foodListSubtitle(int grams, String time) {
    return '${grams}g - $time';
  }

  @override
  String foodListTrailingKcal(int calories) {
    return '$calories kcal';
  }

  @override
  String waterListTrailingMl(int milliliters) {
    return '$milliliters ml';
  }

  @override
  String get exerciseCatalogTitle => 'Übungskatalog';

  @override
  String get filterByMuscle => 'Nach Muskelgruppe filtern';

  @override
  String get noExercisesFound => 'Keine Übungen gefunden.';

  @override
  String get noDescriptionAvailable => 'Keine Beschreibung verfügbar.';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get repsLabelShort => 'Wdh';

  @override
  String get titleNewRoutine => 'Neue Routine';

  @override
  String get titleEditRoutine => 'Routine bearbeiten';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Bitte gib der Routine einen Namen.';

  @override
  String get snackbarRoutineCreated =>
      'Routine erstellt. Füge nun Übungen hinzu.';

  @override
  String get snackbarRoutineSaved => 'Routine gespeichert.';

  @override
  String get formFieldRoutineName => 'Name der Routine';

  @override
  String get emptyStateAddFirstExercise => 'Füge deine erste Übung hinzu.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Übung hinzufügen';

  @override
  String get kgLabelShort => 'kg';

  @override
  String get drawerExerciseCatalog => 'Übungskatalog';

  @override
  String get lastWorkoutTitle => 'Letztes Workout';

  @override
  String get repeatButton => 'Wiederholen';

  @override
  String get weightHistoryTitle => 'Gewichtsverlauf';

  @override
  String get hideSummary => 'Übersicht ausblenden';

  @override
  String get showSummary => 'Übersicht einblenden';

  @override
  String get exerciseDataAttribution => 'Übungsdaten von';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Möchtest du den Trainingsplan \'$routineName\' wirklich unwiderruflich löschen?';
  }

  @override
  String get editPauseTimeTitle => 'Pausendauer bearbeiten';

  @override
  String get pauseInSeconds => 'Pause in Sekunden';

  @override
  String get editPauseTime => 'Pause bearbeiten';

  @override
  String pauseDuration(int seconds) {
    return '$seconds Sekunden Pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pausen bis zu ${seconds}s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Möchtest du dieses protokollierte Workout wirklich unwiderruflich löschen?';

  @override
  String get removeExercise => 'Übung entfernen';

  @override
  String get deleteExerciseConfirmTitle => 'Übung entfernen?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Möchtest du \'$exerciseName\' wirklich aus diesem Trainingsplan entfernen?';
  }

  @override
  String get doneButtonLabel => 'Fertig';

  @override
  String get setRestTimeButton => 'Pause einstellen';

  @override
  String get deleteExerciseButton => 'Übung löschen';

  @override
  String get restOverLabel => 'Pause vorbei';

  @override
  String get workoutRunningLabel => 'Workout läuft …';

  @override
  String get continueButton => 'Weiter';

  @override
  String get discardButton => 'Verwerfen';

  @override
  String get workoutStatsTitle => 'Training (7 Tage)';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get durationLabel => 'Dauer';

  @override
  String get volumeLabel => 'Volumen';

  @override
  String get setsLabel => 'Sätze';

  @override
  String get muscleSplitLabel => 'Muskel-Split';

  @override
  String get snackbar_could_not_open_open_link => 'Konnte Link nicht öffnen';

  @override
  String get chart_no_data_for_period => 'Keine Daten für diesen Zeitraum.';

  @override
  String get amount_in_milliliters => 'Menge in Millilitern';

  @override
  String get amount_in_grams => 'Menge in Gramm';

  @override
  String get meal_label => 'Mahlzeit';

  @override
  String get add_to_water_intake => 'Zur Trinkmenge hinzufügen';

  @override
  String get create_exercise_screen_title => 'Eigene Übung erstellen';

  @override
  String get exercise_name_label => 'Name der Übung';

  @override
  String get category_label => 'Kategorie';

  @override
  String get description_optional_label => 'Beschreibung (optional)';

  @override
  String get primary_muscles_label => 'Primäre Muskeln';

  @override
  String get primary_muscles_hint => 'z.B. Brust, Trizeps';

  @override
  String get secondary_muscles_label => 'Sekundäre Muskeln (optional)';

  @override
  String get secondary_muscles_hint => 'z.B. Schultern';

  @override
  String get set_type_normal => 'Normal';

  @override
  String get set_type_warmup => 'Warmup';

  @override
  String get set_type_failure => 'Failure';

  @override
  String get set_type_dropset => 'Dropset';

  @override
  String get set_reps_hint => '8-12';

  @override
  String get data_export_button => 'Exportieren';

  @override
  String get data_import_button => 'Importieren';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Detailansicht der Messsession.';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Profilbild löschen';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Flüssigkeit hinzufügen';

  @override
  String get add_button => 'Hinzufügen';

  @override
  String get discard_button => 'Verwerfen';

  @override
  String get continue_workout_button => 'Fortsetzen';

  @override
  String get soon_available_snackbar =>
      'Dieser Screen wird bald verfügbar sein!';

  @override
  String get start_button => 'Start';

  @override
  String get today_overview_text => 'HEUTE IM BLICK';

  @override
  String get quick_add_text => 'SCHNELLES HINZUFÜGEN';

  @override
  String get scann_barcode_capslock => 'Barcode scannen';

  @override
  String get protocol_today_capslock => 'HEUTIGES PROTOKOLL';

  @override
  String get my_plans_capslock => 'MEINE PLÄNE';

  @override
  String get overview_capslock => 'ÜBERBLICK';

  @override
  String get manage_all_plans => 'Alle Pläne verwalten';

  @override
  String get free_training => 'Freies Training';

  @override
  String get my_consistency => 'MEINE KONSISTENZ';

  @override
  String get calendar_currently_not_available =>
      'Die Kalender-Ansicht ist in Kürze verfügbar.';

  @override
  String get in_depth_analysis => 'TIEFEN-ANALYSE';

  @override
  String get body_measurements => 'Körpermaße';

  @override
  String get measurements_description =>
      'Gewicht, KFA und Umfänge analysieren.';

  @override
  String get nutrition_description => 'Makros, Kalorien und Trends auswerten.';

  @override
  String get training_analysis => 'Trainings-Analyse';

  @override
  String get training_analysis_description =>
      'Volumen, Kraft und Progression verfolgen.';

  @override
  String get load_dots => 'lade...';

  @override
  String get profile_capslock => 'PROFIL';

  @override
  String get settings_capslock => 'EINSTELLUNGEN';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get my_goals => 'Meine Ziele';

  @override
  String get my_goals_description => 'Kalorien, Makros und Wasser anpassen.';

  @override
  String get backup_and_import => 'Datensicherung & Import';

  @override
  String get backup_and_import_description =>
      'Backups erstellen, wiederherstellen und Daten importieren.';

  @override
  String get about_and_legal_capslock => 'ÜBER & RECHTLICHES';

  @override
  String get attribution_and_license => 'Attribution & Lizenzen';

  @override
  String get data_from_off_and_wger => 'Daten von Open Food Facts und wger.';

  @override
  String get app_version => 'App Version';

  @override
  String get all_measurements => 'ALLE MESSWERTE';

  @override
  String get date_and_time_of_measurement => 'Datum & Uhrzeit der Messung';

  @override
  String get onbWelcomeTitle => 'Willkommen bei Lightweight';

  @override
  String get onbWelcomeBody =>
      'Starte mit deinen persönlichen Zielen für Training und Ernährung.';

  @override
  String get onbTrackTitle => 'Alles tracken';

  @override
  String get onbTrackBody =>
      'Erfasse Ernährung, Workouts und Messwerte — alles an einem Ort.';

  @override
  String get onbPrivacyTitle => 'Offline-first & Privatsphäre';

  @override
  String get onbPrivacyBody =>
      'Deine Daten bleiben auf dem Gerät. Keine Cloud-Konten, kein Hintergrund-Sync.';

  @override
  String get onbFinishTitle => 'Alles bereit';

  @override
  String get onbFinishBody =>
      'Du kannst loslegen. Einstellungen lassen sich jederzeit anpassen.';

  @override
  String get onbFinishCta => 'Los geht’s!';

  @override
  String get onbShowTutorialAgain => 'Tutorial erneut anzeigen';

  @override
  String get onbSetGoalsCta => 'Ziele festlegen';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Überspringen';

  @override
  String get onbBack => 'Zurück';

  @override
  String get onbNext => 'Weiter';

  @override
  String get onbGuideTitle => 'So funktioniert das Tutorial';

  @override
  String get onbGuideBody =>
      'Wische zwischen den Folien oder nutze Weiter. Tippe die Buttons auf jeder Folie, um Funktionen auszuprobieren. Du kannst jederzeit über Überspringen beenden.';

  @override
  String get onbCtaOpenNutrition => 'Ernährung öffnen';

  @override
  String get onbCtaLearnMore => 'Mehr erfahren';

  @override
  String get onbBadgeDone => 'Erledigt';

  @override
  String get onbTipSetGoals => 'Tipp: Lege zuerst deine Ziele fest';

  @override
  String get onbTipAddEntry => 'Tipp: Füge heute einen Eintrag hinzu';

  @override
  String get onbTipLocalControl => 'Du kontrollierst alle Daten lokal';

  @override
  String get onbTrackHowBody =>
      'So erfasst du Ernährung:\n• Öffne den Tab „Food“.\n• Tippe auf das + Symbol.\n• Suche Produkte oder scanne einen Barcode.\n• Passe Portion und Uhrzeit an.\n• Speichere in deinem Tagebuch.';

  @override
  String get onbMeasureTitle => 'Messwerte erfassen';

  @override
  String get onbMeasureBody =>
      'So fügst du Messungen hinzu:\n• Öffne den Tab „Stats“.\n• Tippe auf das + Symbol.\n• Wähle eine Messgröße (z. B. Gewicht, Taille, KFA).\n• Gib Wert und Uhrzeit ein.\n• Speichere deinen Eintrag.';

  @override
  String get onbTipMeasureToday =>
      'Tipp: Trage dein heutiges Gewicht ein, um den Graphen zu starten';

  @override
  String get onbTrainTitle => 'Trainieren mit Routinen';

  @override
  String get onbTrainBody =>
      'Routine erstellen und Workout starten:\n• Öffne den Tab „Train“.\n• Tippe auf Routine erstellen und füge Übungen und Sätze hinzu.\n• Speichere die Routine.\n• Tippe auf Start, um zu beginnen – oder nutze „Freies Training starten“.';

  @override
  String get onbTipStartWorkout =>
      'Tipp: Starte ein freies Training für eine schnelle Einheit';

  @override
  String get unitsSection => 'Einheiten';

  @override
  String get weightUnit => 'Gewichtseinheit';

  @override
  String get lengthUnit => 'Längeneinheit';

  @override
  String get comingSoon => 'In Kürze verfügbar';

  @override
  String get noFavorites => 'Keine Favoriten';

  @override
  String get nothingTrackedYet => 'Noch nichts erfasst';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'Kein Produkt für Barcode \"$barcode\" gefunden.';
  }

  @override
  String get categoryHint => 'z.B. Brust, Rücken, Beine...';

  @override
  String get validatorPleaseEnterCategory => 'Bitte eine Kategorie angeben.';

  @override
  String get dialogEnterPasswordImport => 'Passwort für den Import eingeben';

  @override
  String get dataManagementBackupTitle => 'Lightweight Datensicherung';

  @override
  String get dataManagementBackupDescription =>
      'Sichere oder wiederherstelle alle deine App-Daten. Ideal für einen Gerätewechsel.';

  @override
  String get exportEncrypted => 'Verschlüsselt exportieren';

  @override
  String get dialogPasswordForExport => 'Passwort für verschlüsselten Export';

  @override
  String get snackbarEncryptedBackupShared => 'Verschlüsseltes Backup geteilt.';

  @override
  String get exportFailed => 'Export fehlgeschlagen.';

  @override
  String get csvExportTitle => 'Daten-Export (CSV)';

  @override
  String get csvExportDescription =>
      'Exportiere Teile deiner Daten als CSV-Datei zur Analyse in anderen Programmen.';

  @override
  String get snackbarSharingNutrition => 'Ernährungstagebuch wird geteilt...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Export fehlgeschlagen. Eventuell existieren noch keine Einträge.';

  @override
  String get snackbarSharingMeasurements => 'Messwerte werden geteilt...';

  @override
  String get snackbarSharingWorkouts => 'Trainingsverlauf wird geteilt...';

  @override
  String get mapExercisesTitle => 'Übungen zuordnen';

  @override
  String get mapExercisesDescription =>
      'Unbekannte Namen aus Logs auf wger-Übungen mappen.';

  @override
  String get mapExercisesButton => 'Mapping starten';

  @override
  String get autoBackupTitle => 'Automatische Backups';

  @override
  String get autoBackupDescription =>
      'Legt periodisch eine Sicherung im Ordner ab. Derzeitiger Ordner:';

  @override
  String get autoBackupDefaultFolder => 'App-Dokumente/Backups (Standard)';

  @override
  String get autoBackupChooseFolder => 'Ordner wählen';

  @override
  String get autoBackupCopyPath => 'Pfad kopieren';

  @override
  String get autoBackupRunNow => 'Jetzt Auto-Backup prüfen & ausführen';

  @override
  String get snackbarAutoBackupSuccess => 'Auto-Backup durchgeführt.';

  @override
  String get snackbarAutoBackupFailed =>
      'Auto-Backup fehlgeschlagen oder abgebrochen.';

  @override
  String get noUnknownExercisesFound => 'Keine unbekannten Übungen gefunden';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Auto-Backup-Ordner gesetzt:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Pfad kopiert';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get involvedMuscles => 'Involvierte Muskeln';

  @override
  String get primaryLabel => 'Primär:';

  @override
  String get secondaryLabel => 'Sekundär:';

  @override
  String get noMusclesSpecified => 'Keine Muskeln angegeben.';

  @override
  String get noSelection => 'Keine Auswahl';

  @override
  String get selectButton => 'Auswählen';

  @override
  String get applyingChanges => 'Wird angewendet...';

  @override
  String get applyMapping => 'Zuordnung anwenden';

  @override
  String get personalData => 'Persönliche Daten';

  @override
  String get macroDistribution => 'Makronährstoff-Verteilung';

  @override
  String get dialogFinishWorkoutBody =>
      'Möchtest du dieses Workout wirklich abschließen?';

  @override
  String get attributionText =>
      'Diese App verwendet Daten von externen Quellen:\n\n● Übungsdaten und Bilder von wger (wger.de), lizenziert unter der CC-BY-SA 4.0 Lizenz.\n\n● Lebensmittel-Datenbank von Open Food Facts (openfoodfacts.org), verfügbar unter der Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine nicht gefunden';

  @override
  String get workoutHistoryEmptyTitle => 'Dein Verlauf ist leer';

  @override
  String get workoutSummaryTitle => 'Workout Abgeschlossen';

  @override
  String get workoutSummaryExerciseOverview => 'Übersicht der Übungen';

  @override
  String get nutritionDiary => 'Ernährungstagebuch';

  @override
  String get detailedNutrientGoals => 'Detail-Nährwerte';

  @override
  String get supplementTrackerTitle => 'Supplement-Tracker';

  @override
  String get supplementTrackerDescription =>
      'Ziele, Limits und Einnahmen verfolgen.';

  @override
  String get createSupplementTitle => 'Supplement erstellen';

  @override
  String get supplementNameLabel => 'Name des Supplements';

  @override
  String get defaultDoseLabel => 'Standard-Dosis';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get dailyGoalLabel => 'Tagesziel (optional)';

  @override
  String get dailyLimitLabel => 'Tageslimit (optional)';

  @override
  String get dailyProgressTitle => 'Tagesfortschritt';

  @override
  String get todaysLogTitle => 'Heutiges Protokoll';

  @override
  String get logIntakeTitle => 'Einnahme protokollieren';

  @override
  String get emptySupplementGoals =>
      'Lege Ziele oder Limits für Supplements fest, um deinen Fortschritt hier zu sehen.';

  @override
  String get emptySupplementLogs =>
      'Noch keine Einnahmen für heute protokolliert.';

  @override
  String get doseLabel => 'Dosis';

  @override
  String get settingsDescription => 'Thema, Einheiten, Daten und mehr';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get caffeinePrompt => 'Koffein (optional)';

  @override
  String get caffeineUnit => 'mg pro 100ml';

  @override
  String get profile => 'Profil';

  @override
  String get measurementWeightCapslock => 'KÖRPERGEWICHT';

  @override
  String get diary => 'Tagebuch';

  @override
  String get analysis => 'Analyse';

  @override
  String get yesterday => 'Gestern';

  @override
  String get dayBeforeYesterday => 'Vorgestern';

  @override
  String get statistics => 'Statistiken';

  @override
  String get workout => 'Workout';

  @override
  String get addFoodTitle => 'Lebensmittel hinzufügen';

  @override
  String get supplement_caffeine => 'Koffein';

  @override
  String get supplement_creatine_monohydrate => 'Kreatin Monohydrat';

  @override
  String get manageSupplementsTitle => 'Supplements verwalten';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get operationNotAllowed => 'Diese Aktion nicht erlaubt.';

  @override
  String get emptySupplements => 'Noch keine Supplements vorhanden';

  @override
  String get undo => 'Rückgängig';

  @override
  String get deleteSupplementConfirm =>
      'Supplement wirklich löschen? Alle zugehörigen Einträge werden entfernt.';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get unitNotSupported => 'Einheit wird nicht unterstützt.';

  @override
  String get caffeineUnitLocked => 'Bei Koffein ist die Einheit fest: mg.';

  @override
  String get caffeineMustBeMg => 'Koffein muss in mg erfasst werden.';

  @override
  String get tabCatalogSearch => 'Katalog';

  @override
  String get tabMeals => 'Mahlzeiten';

  @override
  String get emptyCategory => 'Keine Einträge';

  @override
  String get searchSectionBase => 'Grundnahrungsmittel';

  @override
  String get searchSectionOther => 'Weitere Treffer';

  @override
  String get mealsComingSoonTitle => 'Mahlzeiten (in Vorbereitung)';

  @override
  String get mealsComingSoonBody =>
      'Bald kannst du eigene Mahlzeiten aus mehreren Lebensmitteln zusammenstellen.';

  @override
  String get mealsEmptyTitle => 'Noch keine Mahlzeiten';

  @override
  String get mealsEmptyBody =>
      'Lege Mahlzeiten an, um mehrere Lebensmittel mit einem Klick einzutragen.';

  @override
  String get mealsCreate => 'Mahlzeit erstellen';

  @override
  String get mealsEdit => 'Mahlzeit bearbeiten';

  @override
  String get mealsDelete => 'Mahlzeit löschen';

  @override
  String get mealsAddToDiary => 'Zum Tagebuch hinzufügen';

  @override
  String get mealNameLabel => 'Name der Mahlzeit';

  @override
  String get mealNotesLabel => 'Notizen';

  @override
  String get mealIngredientsTitle => 'Zutaten';

  @override
  String get mealAddIngredient => 'Zutat hinzufügen';

  @override
  String get mealIngredientAmountLabel => 'Menge';

  @override
  String get mealDeleteConfirmTitle => 'Mahlzeit löschen';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Möchtest du die Mahlzeit \'$name\' wirklich löschen? Alle Zutaten werden ebenfalls entfernt.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Mahlzeit \'$name\' wurde ins Tagebuch übernommen.';
  }

  @override
  String get mealSaved => 'Mahlzeit gespeichert.';

  @override
  String get mealDeleted => 'Mahlzeit gelöscht.';

  @override
  String get confirm => 'bestätigen';

  @override
  String get addMealToDiaryTitle => 'Zum Tagebuch hinzufügen';

  @override
  String get mealTypeLabel => 'Mahlzeit';

  @override
  String get amountLabel => 'Menge';

  @override
  String get mealAddedToDiarySuccess => 'Mahlzeit zum Tagebuch hinzugefügt';

  @override
  String get error => 'Fehler';

  @override
  String get mealsViewTitle => 'mealsViewTitle';

  @override
  String get noNotes => 'Keine Notizen';

  @override
  String get ingredientsCapsLock => 'ZUTATEN';

  @override
  String get nutritionSectionLabel => 'NÄHRWERTE';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'für aktuelle Mengen';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Entdecke Einblicke, verfolge Mahlzeiten und erstelle hier bald deinen Ernährungsplan.';

  @override
  String get nutritionHubTitle => 'Ernährung';

  @override
  String get nutrition => 'Ernährung';
}
