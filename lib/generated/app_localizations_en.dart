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
  String get profileScreenTitle => 'Profile & Goals';

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
  String get exerciseDataAttribution => 'Exercise data from';

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
}
