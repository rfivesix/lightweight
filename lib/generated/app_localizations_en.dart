// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vita';

  @override
  String get bannerText => 'Recommendation / Current Workout';

  @override
  String get calories => 'Calories';

  @override
  String get water => 'Water';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get daily => 'Daily';

  @override
  String get today => 'Today';

  @override
  String get workoutSection => 'Workout section - not yet implemented';

  @override
  String get addMenuTitle => 'What do you want to add?';

  @override
  String get addFoodOption => 'Food';

  @override
  String get addLiquidOption => 'Liquid';

  @override
  String get searchHintText => 'Search...';

  @override
  String get mealtypeBreakfast => 'Breakfast';

  @override
  String get mealtypeLunch => 'Lunch';

  @override
  String get mealtypeDinner => 'Dinner';

  @override
  String get mealtypeSnack => 'Snack';

  @override
  String get waterHeader => 'Water & Drinks';

  @override
  String get openFoodFactsSource => 'Data from Open Food Facts';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get fabCreateOwnFood => 'Custom Food';

  @override
  String get recentEmptyState =>
      'Your recently used food items\nwill appear here.';

  @override
  String get favoritesEmptyState =>
      'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.';

  @override
  String get searchInitialHint => 'Please enter a search term.';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get createFoodScreenTitle => 'Create Custom Food';

  @override
  String get formFieldName => 'Name of the food';

  @override
  String get formFieldBrand => 'Brand (optional)';

  @override
  String get formSectionMainNutrients => 'Main Nutrients (per 100g)';

  @override
  String get formFieldCalories => 'Calories (kcal)';

  @override
  String get formFieldProtein => 'Protein (g)';

  @override
  String get formFieldCarbs => 'Carbohydrates (g)';

  @override
  String get formFieldFat => 'Fat (g)';

  @override
  String get formSectionOptionalNutrients =>
      'Additional Nutrients (optional, per 100g)';

  @override
  String get formFieldSugar => 'Of which sugars (g)';

  @override
  String get formFieldFiber => 'Fiber (g)';

  @override
  String get formFieldKj => 'Kilojoules (kJ)';

  @override
  String get formFieldSalt => 'Salt (g)';

  @override
  String get formFieldSodium => 'Sodium (mg)';

  @override
  String get formFieldCalcium => 'Calcium (mg)';

  @override
  String get buttonSave => 'Save';

  @override
  String get validatorPleaseEnterName => 'Please enter a name.';

  @override
  String get validatorPleaseEnterNumber => 'Please enter a valid number.';

  @override
  String snackbarSaveSuccess(String foodName) {
    return '$foodName was saved successfully.';
  }

  @override
  String get foodDetailSegmentPortion => 'Portion';

  @override
  String get foodDetailSegment100g => '100g';

  @override
  String get sugar => 'Sugar';

  @override
  String get fiber => 'Fiber';

  @override
  String get salt => 'Salt';

  @override
  String get explorerScreenTitle => 'Food Explorer';

  @override
  String get nutritionScreenTitle => 'Nutrition Analysis';

  @override
  String get entriesForDateRangeLabel => 'Entries for';

  @override
  String get noEntriesForPeriod => 'No entries for this period yet.';

  @override
  String get waterEntryTitle => 'Water';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileDailyGoals => 'Daily Goals';

  @override
  String get snackbarGoalsSaved => 'Goals saved successfully!';

  @override
  String get measurementsScreenTitle => 'Measurements';

  @override
  String get measurementsEmptyState =>
      'No measurements recorded yet.\nStart with the \'+\' button.';

  @override
  String get addMeasurementDialogTitle => 'Add New Measurement';

  @override
  String get formFieldMeasurementType => 'Type of Measurement';

  @override
  String formFieldMeasurementValue(Object unit) {
    return 'Value ($unit)';
  }

  @override
  String get validatorPleaseEnterValue => 'Please enter a value';

  @override
  String get measurementWeight => 'Body Weight';

  @override
  String get measurementFatPercent => 'Body Fat';

  @override
  String get measurementNeck => 'Neck';

  @override
  String get measurementShoulder => 'Shoulder';

  @override
  String get measurementChest => 'Chest';

  @override
  String get measurementLeftBicep => 'Left Bicep';

  @override
  String get measurementRightBicep => 'Right Bicep';

  @override
  String get measurementLeftForearm => 'Left Forearm';

  @override
  String get measurementRightForearm => 'Right Forearm';

  @override
  String get measurementAbdomen => 'Abdomen';

  @override
  String get measurementWaist => 'Waist';

  @override
  String get measurementHips => 'Hips';

  @override
  String get measurementLeftThigh => 'Left Thigh';

  @override
  String get measurementRightThigh => 'Right Thigh';

  @override
  String get measurementLeftCalf => 'Left Calf';

  @override
  String get measurementRightCalf => 'Right Calf';

  @override
  String get drawerMenuTitle => 'Vita Menu';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerFoodExplorer => 'Food Explorer';

  @override
  String get drawerDataManagement => 'Data Backup';

  @override
  String get drawerMeasurements => 'Measurements';

  @override
  String get dataManagementTitle => 'Data Backup';

  @override
  String get exportCardTitle => 'Export Data';

  @override
  String get exportCardDescription =>
      'Saves all your journal entries, favorites, and custom foods into a single backup file.';

  @override
  String get exportCardButton => 'Create Backup';

  @override
  String get importCardTitle => 'Import Data';

  @override
  String get importCardDescription =>
      'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!';

  @override
  String get importCardButton => 'Restore Backup';

  @override
  String get recommendationDefault => 'Track your first meal!';

  @override
  String recommendationOverTarget(Object count, Object difference) {
    return 'Last $count days: +$difference kcal over target';
  }

  @override
  String recommendationUnderTarget(Object count, Object difference) {
    return 'Last $count days: $difference kcal under target';
  }

  @override
  String recommendationOnTarget(Object count) {
    return 'Last $count days: Target achieved ✅';
  }

  @override
  String get recommendationFirstEntry => 'Great, your first entry is logged!';

  @override
  String get dialogConfirmTitle => 'Confirmation Required';

  @override
  String get dialogConfirmImportContent =>
      'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.';

  @override
  String get dialogButtonCancel => 'Cancel';

  @override
  String get dialogButtonOverwrite => 'Yes, overwrite all';

  @override
  String get snackbarNoFileSelected => 'No file selected.';

  @override
  String get snackbarImportSuccessTitle => 'Import successful!';

  @override
  String get snackbarImportSuccessContent =>
      'Your data has been restored. It is recommended to restart the app for a correct display.';

  @override
  String get snackbarButtonOK => 'OK';

  @override
  String get snackbarImportError => 'Error while importing data.';

  @override
  String get snackbarExportSuccess =>
      'Backup file has been passed to the system. Please choose a location to save.';

  @override
  String get snackbarExportFailed => 'Export canceled or failed.';

  @override
  String get profileUserHeight => 'Height (cm)';

  @override
  String get workoutRoutinesTitle => 'Routines';

  @override
  String get workoutHistoryTitle => 'Workout History';

  @override
  String get workoutHistoryButton => 'History';

  @override
  String get emptyRoutinesTitle => 'No Routines Found';

  @override
  String get emptyRoutinesSubtitle =>
      'Create your first routine or start a blank workout.';

  @override
  String get createFirstRoutineButton => 'Create First Routine';

  @override
  String get startEmptyWorkoutButton => 'Free Workout';

  @override
  String get editRoutineSubtitle => 'Tap to edit, or start the workout.';

  @override
  String get startButton => 'Start';

  @override
  String get addRoutineButton => 'New Routine';

  @override
  String get freeWorkoutTitle => 'Free Workout';

  @override
  String get finishWorkoutButton => 'Finish';

  @override
  String get addSetButton => 'Add Set';

  @override
  String get addExerciseToWorkoutButton => 'Add Exercise to Workout';

  @override
  String get lastTimeLabel => 'Last Time';

  @override
  String get setLabel => 'Set';

  @override
  String get kgLabel => 'Weight (kg)';

  @override
  String get repsLabel => 'Reps';

  @override
  String get restTimerLabel => 'Rest';

  @override
  String get skipButton => 'Skip';

  @override
  String get emptyHistory => 'No completed workouts yet.';

  @override
  String get workoutDetailsTitle => 'Workout Details';

  @override
  String get workoutNotFound => 'Workout not found.';

  @override
  String get totalVolumeLabel => 'Total Volume';

  @override
  String get notesLabel => 'Notes';

  @override
  String get hevyImportTitle => 'Hevy Import';

  @override
  String get hevyImportDescription =>
      'Import your entire training history from a Hevy CSV export file.';

  @override
  String get hevyImportButton => 'Import Hevy Data';

  @override
  String hevyImportSuccess(Object count) {
    return 'Successfully imported $count workouts!';
  }

  @override
  String get hevyImportFailed => 'Import failed. Please check the file.';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get addMeasurement => 'Add Measurement';

  @override
  String get filterToday => 'Today';

  @override
  String get filter7Days => '7 Days';

  @override
  String get filter30Days => '30 Days';

  @override
  String get filterAll => 'All';

  @override
  String get showLess => 'Show less';

  @override
  String get showMoreDetails => 'Show more details';

  @override
  String get deleteConfirmTitle => 'Confirm Deletion';

  @override
  String get deleteConfirmContent => 'Do you really want to delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get tabBaseFoods => 'Base Foods';

  @override
  String get baseFoodsEmptyState =>
      'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.';

  @override
  String get noBrand => 'No Brand';

  @override
  String get unknown => 'Unknown';

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
  String get exerciseCatalogTitle => 'Exercise Catalog';

  @override
  String get filterByMuscle => 'Filter by muscle group';

  @override
  String get noExercisesFound => 'No exercises found.';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get edit => 'Edit';

  @override
  String get repsLabelShort => 'reps';

  @override
  String get titleNewRoutine => 'New Routine';

  @override
  String get titleEditRoutine => 'Edit Routine';

  @override
  String get validatorPleaseEnterRoutineName =>
      'Please enter a name for the routine.';

  @override
  String get snackbarRoutineCreated =>
      'Routine created. Now add some exercises.';

  @override
  String get snackbarRoutineSaved => 'Routine saved.';

  @override
  String get formFieldRoutineName => 'Name of the routine';

  @override
  String get emptyStateAddFirstExercise => 'Add your first exercise.';

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get fabAddExercise => 'Add Exercise';

  @override
  String get kgLabelShort => 'kg';

  @override
  String get drawerExerciseCatalog => 'Exercise Catalog';

  @override
  String get lastWorkoutTitle => 'Last Workout';

  @override
  String get repeatButton => 'Repeat';

  @override
  String get weightHistoryTitle => 'Weight History';

  @override
  String get hideSummary => 'Hide Summary';

  @override
  String get showSummary => 'Show Summary';

  @override
  String get exerciseDataAttribution => 'Exercise data from wger';

  @override
  String get duplicate => 'Duplicate';

  @override
  String deleteRoutineConfirmContent(String routineName) {
    return 'Are you sure you want to permanently delete the routine \'$routineName\'?';
  }

  @override
  String get editPauseTimeTitle => 'Edit Pause Duration';

  @override
  String get pauseInSeconds => 'Pause in seconds';

  @override
  String get editPauseTime => 'Edit Pause';

  @override
  String pauseDuration(int seconds) {
    return '$seconds second pause';
  }

  @override
  String maxPauseDuration(int seconds) {
    return 'Pauses up to ${seconds}s';
  }

  @override
  String get deleteWorkoutConfirmContent =>
      'Are you sure you want to permanently delete this workout log?';

  @override
  String get removeExercise => 'Remove Exercise';

  @override
  String get deleteExerciseConfirmTitle => 'Remove Exercise?';

  @override
  String deleteExerciseConfirmContent(String exerciseName) {
    return 'Are you sure you want to remove \'$exerciseName\' from this routine?';
  }

  @override
  String get doneButtonLabel => 'Done';

  @override
  String get setRestTimeButton => 'Set rest time';

  @override
  String get deleteExerciseButton => 'Delete exercise';

  @override
  String get restOverLabel => 'Pause is over';

  @override
  String get workoutRunningLabel => 'Workout is active …';

  @override
  String get continueButton => 'Continue';

  @override
  String get discardButton => 'Discard';

  @override
  String get workoutStatsTitle => 'Training (7 days)';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get durationLabel => 'Duration';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get setsLabel => 'Sets';

  @override
  String get muscleSplitLabel => 'Muscle Split';

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
  String get data_export_button => 'Export';

  @override
  String get data_import_button => 'Import';

  @override
  String get snackbar_button_ok => 'OK';

  @override
  String get measurement_session_detail_view =>
      'Detailview of measurement session';

  @override
  String get unit_grams => 'g';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get delete_profile_picture_button => 'Delete profile picture';

  @override
  String get attribution_title => 'Attribution';

  @override
  String get add_liquid_title => 'Add fluid';

  @override
  String get add_button => 'Add';

  @override
  String get discard_button => 'Discard';

  @override
  String get continue_workout_button => 'Continue';

  @override
  String get soon_available_snackbar => 'This screen will be available soon';

  @override
  String get start_button => 'Start';

  @override
  String get today_overview_text => 'TODAY IN FOCUS';

  @override
  String get quick_add_text => 'QUICK ADD';

  @override
  String get scann_barcode_capslock => 'Scan barcode';

  @override
  String get protocol_today_capslock => 'TODAY\'S PROTOCOL';

  @override
  String get my_plans_capslock => 'MY PLANS';

  @override
  String get overview_capslock => 'OVERVIEW';

  @override
  String get manage_all_plans => 'Manage all plans';

  @override
  String get free_training => 'free training';

  @override
  String get my_consistency => 'MY CONSISTENCY';

  @override
  String get calendar_currently_not_available =>
      'The calendar view will be available soon.';

  @override
  String get in_depth_analysis => 'IN-DEPTH ANALYSIS';

  @override
  String get body_measurements => 'Body measurements';

  @override
  String get measurements_description =>
      'Analyze weight, body fat percentage and circumference.';

  @override
  String get nutrition_description => 'Evaluate macros, calories and trends.';

  @override
  String get training_analysis => 'Training analysis';

  @override
  String get training_analysis_description =>
      'Track volume, strength and progression.';

  @override
  String get load_dots => 'loading...';

  @override
  String get profile_capslock => 'PROFILE';

  @override
  String get settings_capslock => 'SETTINGS';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get my_goals => 'My goals';

  @override
  String get my_goals_description => 'Adjust calories, macros and water.';

  @override
  String get backup_and_import => 'Data backup & import';

  @override
  String get backup_and_import_description =>
      'Create backups, restore, and import data.';

  @override
  String get about_and_legal_capslock => 'ABOUT & LEGAL';

  @override
  String get attribution_and_license => 'Attribution & Licenses';

  @override
  String get data_from_off_and_wger => 'Data from Open Food Facts and wger.';

  @override
  String get app_version => 'App version';

  @override
  String get all_measurements => 'ALL MEASUREMENTS';

  @override
  String get date_and_time_of_measurement => 'Date & time of measurement';

  @override
  String get onbWelcomeTitle => 'Welcome to Lightweight';

  @override
  String get onbWelcomeBody =>
      'Let’s start by setting personal goals to guide training and nutrition.';

  @override
  String get onbTrackTitle => 'Track everything';

  @override
  String get onbTrackBody =>
      'Log nutrition, workouts, and measurements — all in one place.';

  @override
  String get onbPrivacyTitle => 'Offline-first & privacy';

  @override
  String get onbPrivacyBody =>
      'Your data stays on the device. No cloud accounts, no background sync.';

  @override
  String get onbFinishTitle => 'All set';

  @override
  String get onbFinishBody =>
      'You’re ready to explore the app. You can adjust settings anytime.';

  @override
  String get onbFinishCta => 'Let’s go!';

  @override
  String get onbShowTutorialAgain => 'Show tutorial again';

  @override
  String get onbSetGoalsCta => 'Set goals';

  @override
  String get onbHeaderTitle => 'Tutorial';

  @override
  String get onbHeaderSkip => 'Skip';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNext => 'Next';

  @override
  String get onbGuideTitle => 'How this tutorial works';

  @override
  String get onbGuideBody =>
      'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.';

  @override
  String get onbCtaOpenNutrition => 'Open nutrition';

  @override
  String get onbCtaLearnMore => 'Learn more';

  @override
  String get onbBadgeDone => 'Done';

  @override
  String get onbTipSetGoals => 'Tip: adjust targets first';

  @override
  String get onbTipAddEntry => 'Tip: add one entry today';

  @override
  String get onbTipLocalControl => 'You control all data locally';

  @override
  String get onbTrackHowBody =>
      'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.';

  @override
  String get onbMeasureTitle => 'Track measurements';

  @override
  String get onbMeasureBody =>
      'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.';

  @override
  String get onbTipMeasureToday =>
      'Tip: add today’s weight to start your graph';

  @override
  String get onbTrainTitle => 'Train with routines';

  @override
  String get onbTrainBody =>
      'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.';

  @override
  String get onbTipStartWorkout =>
      'Tip: start an empty workout to log a quick session';

  @override
  String get unitsSection => 'units';

  @override
  String get weightUnit => 'Weight units';

  @override
  String get lengthUnit => 'unit of length';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noFavorites => 'No Favorites';

  @override
  String get nothingTrackedYet => 'Nothing tracked yet';

  @override
  String snackbarBarcodeNotFound(String barcode) {
    return 'No product found for barcode \"$barcode\".';
  }

  @override
  String get categoryHint => 'e.g. Chest, Back, Legs...';

  @override
  String get validatorPleaseEnterCategory => 'Please enter a category.';

  @override
  String get dialogEnterPasswordImport => 'Enter password to import backup';

  @override
  String get dataManagementBackupTitle => 'Lightweight Data Backup';

  @override
  String get dataManagementBackupDescription =>
      'Back up or restore all your app data. Ideal for changing devices.';

  @override
  String get exportEncrypted => 'Export Encrypted';

  @override
  String get dialogPasswordForExport => 'Password for encrypted export';

  @override
  String get snackbarEncryptedBackupShared => 'Encrypted backup shared.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get csvExportTitle => 'Data Export (CSV)';

  @override
  String get csvExportDescription =>
      'Export parts of your data as a CSV file for analysis in other programs.';

  @override
  String get snackbarSharingNutrition => 'Sharing nutrition diary...';

  @override
  String get snackbarExportFailedNoEntries =>
      'Export failed. There may be no entries yet.';

  @override
  String get snackbarSharingMeasurements => 'Sharing measurements...';

  @override
  String get snackbarSharingWorkouts => 'Sharing workout history...';

  @override
  String get mapExercisesTitle => 'Map Exercises';

  @override
  String get mapExercisesDescription =>
      'Map unknown names from logs to wger exercises.';

  @override
  String get mapExercisesButton => 'Start Mapping';

  @override
  String get autoBackupTitle => 'Automatic Backups';

  @override
  String get autoBackupDescription =>
      'Periodically saves a backup in the folder. Current folder:';

  @override
  String get autoBackupDefaultFolder => 'App-Documents/Backups (Default)';

  @override
  String get autoBackupChooseFolder => 'Choose Folder';

  @override
  String get autoBackupCopyPath => 'Copy Path';

  @override
  String get autoBackupRunNow => 'Check & Run Auto-Backup Now';

  @override
  String get snackbarAutoBackupSuccess => 'Auto-Backup completed.';

  @override
  String get snackbarAutoBackupFailed => 'Auto-Backup failed or was canceled.';

  @override
  String get noUnknownExercisesFound => 'No unknown exercises found';

  @override
  String snackbarAutoBackupFolderSet(String path) {
    return 'Auto-backup folder set:\n$path';
  }

  @override
  String get snackbarPathCopied => 'Path copied';

  @override
  String get passwordLabel => 'Password';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get involvedMuscles => 'Involved Muscles';

  @override
  String get primaryLabel => 'Primary:';

  @override
  String get secondaryLabel => 'Secondary:';

  @override
  String get noMusclesSpecified => 'No muscles specified.';

  @override
  String get noSelection => 'No selection';

  @override
  String get selectButton => 'Select';

  @override
  String get applyingChanges => 'Applying changes...';

  @override
  String get applyMapping => 'Apply Mapping';

  @override
  String get personalData => 'Personal Data';

  @override
  String get macroDistribution => 'Macronutrient Distribution';

  @override
  String get dialogFinishWorkoutBody =>
      'Are you sure you want to finish this workout?';

  @override
  String get attributionText =>
      'This app uses data from external sources:\n\n● Exercise data and images from wger (wger.de), licensed under CC-BY-SA 4.0.\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).';

  @override
  String get errorRoutineNotFound => 'Routine not found';

  @override
  String get workoutHistoryEmptyTitle => 'Your history is empty';

  @override
  String get workoutSummaryTitle => 'Workout Complete';

  @override
  String get workoutSummaryExerciseOverview => 'Exercise Overview';

  @override
  String get nutritionDiary => 'Diary';

  @override
  String get detailedNutrientGoals => 'Detailed Nutrients';

  @override
  String get supplementTrackerTitle => 'Supplement Tracker';

  @override
  String get supplementTrackerDescription => 'Track goals, limits, and intake.';

  @override
  String get createSupplementTitle => 'Create Supplement';

  @override
  String get supplementNameLabel => 'Supplement Name';

  @override
  String get defaultDoseLabel => 'Default Dose';

  @override
  String get unitLabel => 'Unit';

  @override
  String get dailyGoalLabel => 'Daily Goal (optional)';

  @override
  String get dailyLimitLabel => 'Daily Limit (optional)';

  @override
  String get dailyProgressTitle => 'Daily Progress';

  @override
  String get todaysLogTitle => 'Today\'s Log';

  @override
  String get logIntakeTitle => 'Log Intake';

  @override
  String get emptySupplementGoals =>
      'Set goals or limits for supplements to see your progress here.';

  @override
  String get emptySupplementLogs => 'No intake logged for today yet.';

  @override
  String get doseLabel => 'Dose';

  @override
  String get settingsDescription => 'Theme, units, data and more';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get caffeinePrompt => 'Caffeine (optional)';

  @override
  String get caffeineUnit => 'mg per 100ml';

  @override
  String get profile => 'Profile';

  @override
  String get measurementWeightCapslock => 'BODY WEIGHT';

  @override
  String get diary => 'Diary';

  @override
  String get analysis => 'Analysis';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayBeforeYesterday => 'Two days ago';

  @override
  String get statistics => 'Statistics';

  @override
  String get workout => 'Workout';

  @override
  String get addFoodTitle => 'add food';

  @override
  String get supplement_caffeine => 'Caffeine';

  @override
  String get supplement_creatine_monohydrate => 'Creatine Monohydrate';

  @override
  String get manageSupplementsTitle => 'Manage supplements';

  @override
  String get deleted => 'deleted';

  @override
  String get operationNotAllowed => 'This operation isn\'t allowed';

  @override
  String get emptySupplements => 'No supplements available';

  @override
  String get undo => 'Rückgängig';

  @override
  String get deleteSupplementConfirm =>
      'Are you sure you want to delete this supplement? All related entries will be removed.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get unitNotSupported => 'Unit not supported.';

  @override
  String get caffeineUnitLocked => 'For caffeine the unit is fixed: mg.';

  @override
  String get caffeineMustBeMg => 'Caffeine must be recorded in mg.';

  @override
  String get tabCatalogSearch => 'Catalog';

  @override
  String get tabMeals => 'Meals';

  @override
  String get emptyCategory => 'No entries';

  @override
  String get searchSectionBase => 'Base foods';

  @override
  String get searchSectionOther => 'Other results';

  @override
  String get mealsComingSoonTitle => 'Meals (coming soon)';

  @override
  String get mealsComingSoonBody =>
      'Soon you will be able to create your own meals from multiple foods.';

  @override
  String get mealsEmptyTitle => 'No meals yet';

  @override
  String get mealsEmptyBody =>
      'Create meals to quickly log multiple foods at once.';

  @override
  String get mealsCreate => 'Create meal';

  @override
  String get mealsEdit => 'Edit meal';

  @override
  String get mealsDelete => 'Delete meal';

  @override
  String get mealsAddToDiary => 'Add to diary';

  @override
  String get mealNameLabel => 'Meal name';

  @override
  String get mealNotesLabel => 'Notes';

  @override
  String get mealIngredientsTitle => 'Ingredients';

  @override
  String get mealAddIngredient => 'Add ingredient';

  @override
  String get mealIngredientAmountLabel => 'Amount';

  @override
  String get mealDeleteConfirmTitle => 'Delete meal';

  @override
  String mealDeleteConfirmBody(Object name) {
    return 'Are you sure you want to delete the meal \'$name\'? All its ingredients will also be removed.';
  }

  @override
  String mealAddedToDiary(Object name) {
    return 'Meal \'$name\' has been added to your diary.';
  }

  @override
  String get mealSaved => 'Meal saved.';

  @override
  String get mealDeleted => 'Meal deleted.';

  @override
  String get confirm => 'Confirm';

  @override
  String get addMealToDiaryTitle => 'Add to diary';

  @override
  String get mealTypeLabel => 'Meal';

  @override
  String get amountLabel => 'Amount';

  @override
  String get mealAddedToDiarySuccess => 'Meal added to diary';

  @override
  String get error => 'Error';

  @override
  String get mealsViewTitle => 'mealsViewTitle';

  @override
  String get noNotes => 'No notes';

  @override
  String get ingredientsCapsLock => 'INGREDIENTS';

  @override
  String get nutritionSectionLabel => 'NUTRITION FACTS';

  @override
  String get nutritionCalculatedForCurrentAmounts => 'for current quantities';

  @override
  String get startCapsLock => 'START';

  @override
  String get nutritionHubSubtitle =>
      'Discover insights, track meals, and plan your nutrition here soon.';

  @override
  String get nutritionHubTitle => 'Nutrition';

  @override
  String get nutrition => 'nutrition';
}
