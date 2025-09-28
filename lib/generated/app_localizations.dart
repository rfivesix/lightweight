import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vita'**
  String get appTitle;

  /// No description provided for @bannerText.
  ///
  /// In en, this message translates to:
  /// **'Recommendation / Current Workout'**
  String get bannerText;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @workoutSection.
  ///
  /// In en, this message translates to:
  /// **'Workout section - not yet implemented'**
  String get workoutSection;

  /// No description provided for @addMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to add?'**
  String get addMenuTitle;

  /// No description provided for @addFoodOption.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get addFoodOption;

  /// No description provided for @addLiquidOption.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get addLiquidOption;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHintText;

  /// No description provided for @mealtypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealtypeBreakfast;

  /// No description provided for @mealtypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealtypeLunch;

  /// No description provided for @mealtypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealtypeDinner;

  /// No description provided for @mealtypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealtypeSnack;

  /// No description provided for @waterHeader.
  ///
  /// In en, this message translates to:
  /// **'Water & Drinks'**
  String get waterHeader;

  /// No description provided for @openFoodFactsSource.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts'**
  String get openFoodFactsSource;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @fabCreateOwnFood.
  ///
  /// In en, this message translates to:
  /// **'Custom Food'**
  String get fabCreateOwnFood;

  /// No description provided for @recentEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Your recently used food items\nwill appear here.'**
  String get recentEmptyState;

  /// No description provided for @favoritesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any favorites yet.\nMark a food with the heart icon to see it here.'**
  String get favoritesEmptyState;

  /// No description provided for @searchInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term.'**
  String get searchInitialHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// No description provided for @createFoodScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Food'**
  String get createFoodScreenTitle;

  /// No description provided for @formFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name of the food'**
  String get formFieldName;

  /// No description provided for @formFieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get formFieldBrand;

  /// No description provided for @formSectionMainNutrients.
  ///
  /// In en, this message translates to:
  /// **'Main Nutrients (per 100g)'**
  String get formSectionMainNutrients;

  /// No description provided for @formFieldCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get formFieldCalories;

  /// No description provided for @formFieldProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get formFieldProtein;

  /// No description provided for @formFieldCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates (g)'**
  String get formFieldCarbs;

  /// No description provided for @formFieldFat.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get formFieldFat;

  /// No description provided for @formSectionOptionalNutrients.
  ///
  /// In en, this message translates to:
  /// **'Additional Nutrients (optional, per 100g)'**
  String get formSectionOptionalNutrients;

  /// No description provided for @formFieldSugar.
  ///
  /// In en, this message translates to:
  /// **'Of which sugars (g)'**
  String get formFieldSugar;

  /// No description provided for @formFieldFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get formFieldFiber;

  /// No description provided for @formFieldKj.
  ///
  /// In en, this message translates to:
  /// **'Kilojoules (kJ)'**
  String get formFieldKj;

  /// No description provided for @formFieldSalt.
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get formFieldSalt;

  /// No description provided for @formFieldSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium (mg)'**
  String get formFieldSodium;

  /// No description provided for @formFieldCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium (mg)'**
  String get formFieldCalcium;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @validatorPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get validatorPleaseEnterName;

  /// No description provided for @validatorPleaseEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get validatorPleaseEnterNumber;

  /// No description provided for @snackbarSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'{foodName} was saved successfully.'**
  String snackbarSaveSuccess(String foodName);

  /// No description provided for @foodDetailSegmentPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get foodDetailSegmentPortion;

  /// No description provided for @foodDetailSegment100g.
  ///
  /// In en, this message translates to:
  /// **'100g'**
  String get foodDetailSegment100g;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiber;

  /// No description provided for @salt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get salt;

  /// No description provided for @explorerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get explorerScreenTitle;

  /// No description provided for @nutritionScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Analysis'**
  String get nutritionScreenTitle;

  /// No description provided for @entriesForDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries for'**
  String get entriesForDateRangeLabel;

  /// No description provided for @noEntriesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No entries for this period yet.'**
  String get noEntriesForPeriod;

  /// No description provided for @waterEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterEntryTitle;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Goals'**
  String get profileScreenTitle;

  /// No description provided for @profileDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get profileDailyGoals;

  /// No description provided for @snackbarGoalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Goals saved successfully!'**
  String get snackbarGoalsSaved;

  /// No description provided for @measurementsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurementsScreenTitle;

  /// No description provided for @measurementsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No measurements recorded yet.\nStart with the \'+\' button.'**
  String get measurementsEmptyState;

  /// No description provided for @addMeasurementDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Measurement'**
  String get addMeasurementDialogTitle;

  /// No description provided for @formFieldMeasurementType.
  ///
  /// In en, this message translates to:
  /// **'Type of Measurement'**
  String get formFieldMeasurementType;

  /// No description provided for @formFieldMeasurementValue.
  ///
  /// In en, this message translates to:
  /// **'Value ({unit})'**
  String formFieldMeasurementValue(Object unit);

  /// No description provided for @validatorPleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get validatorPleaseEnterValue;

  /// No description provided for @measurementWeight.
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get measurementWeight;

  /// No description provided for @measurementFatPercent.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get measurementFatPercent;

  /// No description provided for @measurementNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get measurementNeck;

  /// No description provided for @measurementShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get measurementShoulder;

  /// No description provided for @measurementChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measurementChest;

  /// No description provided for @measurementLeftBicep.
  ///
  /// In en, this message translates to:
  /// **'Left Bicep'**
  String get measurementLeftBicep;

  /// No description provided for @measurementRightBicep.
  ///
  /// In en, this message translates to:
  /// **'Right Bicep'**
  String get measurementRightBicep;

  /// No description provided for @measurementLeftForearm.
  ///
  /// In en, this message translates to:
  /// **'Left Forearm'**
  String get measurementLeftForearm;

  /// No description provided for @measurementRightForearm.
  ///
  /// In en, this message translates to:
  /// **'Right Forearm'**
  String get measurementRightForearm;

  /// No description provided for @measurementAbdomen.
  ///
  /// In en, this message translates to:
  /// **'Abdomen'**
  String get measurementAbdomen;

  /// No description provided for @measurementWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measurementWaist;

  /// No description provided for @measurementHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measurementHips;

  /// No description provided for @measurementLeftThigh.
  ///
  /// In en, this message translates to:
  /// **'Left Thigh'**
  String get measurementLeftThigh;

  /// No description provided for @measurementRightThigh.
  ///
  /// In en, this message translates to:
  /// **'Right Thigh'**
  String get measurementRightThigh;

  /// No description provided for @measurementLeftCalf.
  ///
  /// In en, this message translates to:
  /// **'Left Calf'**
  String get measurementLeftCalf;

  /// No description provided for @measurementRightCalf.
  ///
  /// In en, this message translates to:
  /// **'Right Calf'**
  String get measurementRightCalf;

  /// No description provided for @drawerMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Vita Menu'**
  String get drawerMenuTitle;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerFoodExplorer.
  ///
  /// In en, this message translates to:
  /// **'Food Explorer'**
  String get drawerFoodExplorer;

  /// No description provided for @drawerDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get drawerDataManagement;

  /// No description provided for @drawerMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get drawerMeasurements;

  /// No description provided for @dataManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataManagementTitle;

  /// No description provided for @exportCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportCardTitle;

  /// No description provided for @exportCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Saves all your journal entries, favorites, and custom foods into a single backup file.'**
  String get exportCardDescription;

  /// No description provided for @exportCardButton.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get exportCardButton;

  /// No description provided for @importCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importCardTitle;

  /// No description provided for @importCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Restores your data from a previously created backup file. WARNING: All data currently stored in the app will be overwritten!'**
  String get importCardDescription;

  /// No description provided for @importCardButton.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get importCardButton;

  /// No description provided for @recommendationDefault.
  ///
  /// In en, this message translates to:
  /// **'Track your first meal!'**
  String get recommendationDefault;

  /// No description provided for @recommendationOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: +{difference} kcal over target'**
  String recommendationOverTarget(Object count, Object difference);

  /// No description provided for @recommendationUnderTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: {difference} kcal under target'**
  String recommendationUnderTarget(Object count, Object difference);

  /// No description provided for @recommendationOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days: Target achieved ✅'**
  String recommendationOnTarget(Object count);

  /// No description provided for @recommendationFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Great, your first entry is logged!'**
  String get recommendationFirstEntry;

  /// No description provided for @dialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Required'**
  String get dialogConfirmTitle;

  /// No description provided for @dialogConfirmImportContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to restore data from this backup?\n\nWARNING: All your current entries, favorites, and custom foods will be permanently deleted and replaced.'**
  String get dialogConfirmImportContent;

  /// No description provided for @dialogButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogButtonCancel;

  /// No description provided for @dialogButtonOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Yes, overwrite all'**
  String get dialogButtonOverwrite;

  /// No description provided for @snackbarNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get snackbarNoFileSelected;

  /// No description provided for @snackbarImportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get snackbarImportSuccessTitle;

  /// No description provided for @snackbarImportSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. It is recommended to restart the app for a correct display.'**
  String get snackbarImportSuccessContent;

  /// No description provided for @snackbarButtonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbarButtonOK;

  /// No description provided for @snackbarImportError.
  ///
  /// In en, this message translates to:
  /// **'Error while importing data.'**
  String get snackbarImportError;

  /// No description provided for @snackbarExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file has been passed to the system. Please choose a location to save.'**
  String get snackbarExportSuccess;

  /// No description provided for @snackbarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export canceled or failed.'**
  String get snackbarExportFailed;

  /// No description provided for @profileUserHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileUserHeight;

  /// No description provided for @workoutRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get workoutRoutinesTitle;

  /// No description provided for @workoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistoryTitle;

  /// No description provided for @workoutHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get workoutHistoryButton;

  /// No description provided for @emptyRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Routines Found'**
  String get emptyRoutinesTitle;

  /// No description provided for @emptyRoutinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first routine or start a blank workout.'**
  String get emptyRoutinesSubtitle;

  /// No description provided for @createFirstRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Routine'**
  String get createFirstRoutineButton;

  /// No description provided for @startEmptyWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get startEmptyWorkoutButton;

  /// No description provided for @editRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit, or start the workout.'**
  String get editRoutineSubtitle;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @addRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get addRoutineButton;

  /// No description provided for @freeWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Workout'**
  String get freeWorkoutTitle;

  /// No description provided for @finishWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishWorkoutButton;

  /// No description provided for @addSetButton.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSetButton;

  /// No description provided for @addExerciseToWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise to Workout'**
  String get addExerciseToWorkoutButton;

  /// No description provided for @lastTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Time'**
  String get lastTimeLabel;

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get kgLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @restTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restTimerLabel;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet.'**
  String get emptyHistory;

  /// No description provided for @workoutDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Details'**
  String get workoutDetailsTitle;

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found.'**
  String get workoutNotFound;

  /// No description provided for @totalVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolumeLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @hevyImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Hevy Import'**
  String get hevyImportTitle;

  /// No description provided for @hevyImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import your entire training history from a Hevy CSV export file.'**
  String get hevyImportDescription;

  /// No description provided for @hevyImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Hevy Data'**
  String get hevyImportButton;

  /// No description provided for @hevyImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} workouts!'**
  String hevyImportSuccess(Object count);

  /// No description provided for @hevyImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file.'**
  String get hevyImportFailed;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filter7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get filter7Days;

  /// No description provided for @filter30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get filter30Days;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Show more details'**
  String get showMoreDetails;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this entry?'**
  String get deleteConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @tabBaseFoods.
  ///
  /// In en, this message translates to:
  /// **'Base Foods'**
  String get tabBaseFoods;

  /// No description provided for @baseFoodsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'This section will soon be filled with a curated list of base foods like fruits, vegetables, and more.'**
  String get baseFoodsEmptyState;

  /// No description provided for @noBrand.
  ///
  /// In en, this message translates to:
  /// **'No Brand'**
  String get noBrand;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @backupFileSubject.
  ///
  /// In en, this message translates to:
  /// **'Vita App Backup - {timestamp}'**
  String backupFileSubject(String timestamp);

  /// No description provided for @foodItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{brand} - {calories} kcal / 100g'**
  String foodItemSubtitle(String brand, int calories);

  /// No description provided for @foodListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{grams}g - {time}'**
  String foodListSubtitle(int grams, String time);

  /// No description provided for @foodListTrailingKcal.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String foodListTrailingKcal(int calories);

  /// No description provided for @waterListTrailingMl.
  ///
  /// In en, this message translates to:
  /// **'{milliliters} ml'**
  String waterListTrailingMl(int milliliters);

  /// No description provided for @exerciseCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get exerciseCatalogTitle;

  /// No description provided for @filterByMuscle.
  ///
  /// In en, this message translates to:
  /// **'Filter by muscle group'**
  String get filterByMuscle;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found.'**
  String get noExercisesFound;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @repsLabelShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsLabelShort;

  /// No description provided for @titleNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get titleNewRoutine;

  /// No description provided for @titleEditRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get titleEditRoutine;

  /// No description provided for @validatorPleaseEnterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the routine.'**
  String get validatorPleaseEnterRoutineName;

  /// No description provided for @snackbarRoutineCreated.
  ///
  /// In en, this message translates to:
  /// **'Routine created. Now add some exercises.'**
  String get snackbarRoutineCreated;

  /// No description provided for @snackbarRoutineSaved.
  ///
  /// In en, this message translates to:
  /// **'Routine saved.'**
  String get snackbarRoutineSaved;

  /// No description provided for @formFieldRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Name of the routine'**
  String get formFieldRoutineName;

  /// No description provided for @emptyStateAddFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise.'**
  String get emptyStateAddFirstExercise;

  /// No description provided for @setCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 set}other{{count} sets}}'**
  String setCount(int count);

  /// No description provided for @fabAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get fabAddExercise;

  /// No description provided for @kgLabelShort.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgLabelShort;

  /// No description provided for @drawerExerciseCatalog.
  ///
  /// In en, this message translates to:
  /// **'Exercise Catalog'**
  String get drawerExerciseCatalog;

  /// No description provided for @lastWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Workout'**
  String get lastWorkoutTitle;

  /// No description provided for @repeatButton.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatButton;

  /// No description provided for @weightHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight History'**
  String get weightHistoryTitle;

  /// No description provided for @hideSummary.
  ///
  /// In en, this message translates to:
  /// **'Hide Summary'**
  String get hideSummary;

  /// No description provided for @showSummary.
  ///
  /// In en, this message translates to:
  /// **'Show Summary'**
  String get showSummary;

  /// No description provided for @exerciseDataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Exercise data from'**
  String get exerciseDataAttribution;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @deleteRoutineConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete the routine \'{routineName}\'?'**
  String deleteRoutineConfirmContent(String routineName);

  /// No description provided for @editPauseTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause Duration'**
  String get editPauseTimeTitle;

  /// No description provided for @pauseInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Pause in seconds'**
  String get pauseInSeconds;

  /// No description provided for @editPauseTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Pause'**
  String get editPauseTime;

  /// No description provided for @pauseDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds} second pause'**
  String pauseDuration(int seconds);

  /// No description provided for @maxPauseDuration.
  ///
  /// In en, this message translates to:
  /// **'Pauses up to {seconds}s'**
  String maxPauseDuration(int seconds);

  /// No description provided for @deleteWorkoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this workout log?'**
  String get deleteWorkoutConfirmContent;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise'**
  String get removeExercise;

  /// No description provided for @deleteExerciseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise?'**
  String get deleteExerciseConfirmTitle;

  /// No description provided for @deleteExerciseConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \'{exerciseName}\' from this routine?'**
  String deleteExerciseConfirmContent(String exerciseName);

  /// No description provided for @doneButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButtonLabel;

  /// No description provided for @setRestTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Set rest time'**
  String get setRestTimeButton;

  /// No description provided for @deleteExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExerciseButton;

  /// No description provided for @restOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause is over'**
  String get restOverLabel;

  /// No description provided for @workoutRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout is active …'**
  String get workoutRunningLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @workoutStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training (7 days)'**
  String get workoutStatsTitle;

  /// No description provided for @workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// Label for workout duration summary
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// Label for number of sets summary
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// Label for muscle split bar chart
  ///
  /// In en, this message translates to:
  /// **'Muscle Split'**
  String get muscleSplitLabel;

  /// No description provided for @snackbar_could_not_open_open_link.
  ///
  /// In en, this message translates to:
  /// **'Konnte Link nicht öffnen'**
  String get snackbar_could_not_open_open_link;

  /// No description provided for @chart_no_data_for_period.
  ///
  /// In en, this message translates to:
  /// **'Keine Daten für diesen Zeitraum.'**
  String get chart_no_data_for_period;

  /// No description provided for @amount_in_milliliters.
  ///
  /// In en, this message translates to:
  /// **'Menge in Millilitern'**
  String get amount_in_milliliters;

  /// No description provided for @amount_in_grams.
  ///
  /// In en, this message translates to:
  /// **'Menge in Gramm'**
  String get amount_in_grams;

  /// No description provided for @meal_label.
  ///
  /// In en, this message translates to:
  /// **'Mahlzeit'**
  String get meal_label;

  /// No description provided for @add_to_water_intake.
  ///
  /// In en, this message translates to:
  /// **'Zur Trinkmenge hinzufügen'**
  String get add_to_water_intake;

  /// No description provided for @create_exercise_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Eigene Übung erstellen'**
  String get create_exercise_screen_title;

  /// No description provided for @exercise_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name der Übung'**
  String get exercise_name_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Kategorie'**
  String get category_label;

  /// No description provided for @description_optional_label.
  ///
  /// In en, this message translates to:
  /// **'Beschreibung (optional)'**
  String get description_optional_label;

  /// No description provided for @primary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Primäre Muskeln'**
  String get primary_muscles_label;

  /// No description provided for @primary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'z.B. Brust, Trizeps'**
  String get primary_muscles_hint;

  /// No description provided for @secondary_muscles_label.
  ///
  /// In en, this message translates to:
  /// **'Sekundäre Muskeln (optional)'**
  String get secondary_muscles_label;

  /// No description provided for @secondary_muscles_hint.
  ///
  /// In en, this message translates to:
  /// **'z.B. Schultern'**
  String get secondary_muscles_hint;

  /// No description provided for @set_type_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get set_type_normal;

  /// No description provided for @set_type_warmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get set_type_warmup;

  /// No description provided for @set_type_failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get set_type_failure;

  /// No description provided for @set_type_dropset.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get set_type_dropset;

  /// No description provided for @set_reps_hint.
  ///
  /// In en, this message translates to:
  /// **'8-12'**
  String get set_reps_hint;

  /// No description provided for @data_export_button.
  ///
  /// In en, this message translates to:
  /// **'Exportieren'**
  String get data_export_button;

  /// No description provided for @data_import_button.
  ///
  /// In en, this message translates to:
  /// **'Importieren'**
  String get data_import_button;

  /// No description provided for @snackbar_button_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get snackbar_button_ok;

  /// No description provided for @measurement_session_detail_view.
  ///
  /// In en, this message translates to:
  /// **'Detailansicht der Messsession.'**
  String get measurement_session_detail_view;

  /// No description provided for @unit_grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unit_grams;

  /// No description provided for @unit_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unit_kcal;

  /// No description provided for @delete_profile_picture_button.
  ///
  /// In en, this message translates to:
  /// **'Delete profile picture'**
  String get delete_profile_picture_button;

  /// No description provided for @attribution_title.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get attribution_title;

  /// No description provided for @add_liquid_title.
  ///
  /// In en, this message translates to:
  /// **'Flüssigkeit hinzufügen'**
  String get add_liquid_title;

  /// No description provided for @add_button.
  ///
  /// In en, this message translates to:
  /// **'Hinzufügen'**
  String get add_button;

  /// No description provided for @discard_button.
  ///
  /// In en, this message translates to:
  /// **'Verwerfen'**
  String get discard_button;

  /// No description provided for @continue_workout_button.
  ///
  /// In en, this message translates to:
  /// **'Workout fortsetzen'**
  String get continue_workout_button;

  /// No description provided for @soon_available_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Dieser Screen wird bald verfügbar sein!'**
  String get soon_available_snackbar;

  /// No description provided for @start_button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_button;

  /// No description provided for @today_overview_text.
  ///
  /// In en, this message translates to:
  /// **'TODAY IN FOCUS'**
  String get today_overview_text;

  /// No description provided for @quick_add_text.
  ///
  /// In en, this message translates to:
  /// **'QUICK ADD'**
  String get quick_add_text;

  /// No description provided for @scann_barcode_capslock.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scann_barcode_capslock;

  /// No description provided for @protocol_today_capslock.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROTOCOL'**
  String get protocol_today_capslock;

  /// No description provided for @my_plans_capslock.
  ///
  /// In en, this message translates to:
  /// **'MY PLANS'**
  String get my_plans_capslock;

  /// No description provided for @overview_capslock.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview_capslock;

  /// No description provided for @manage_all_plans.
  ///
  /// In en, this message translates to:
  /// **'Manage all plans'**
  String get manage_all_plans;

  /// No description provided for @free_training.
  ///
  /// In en, this message translates to:
  /// **'free training'**
  String get free_training;

  /// No description provided for @my_consistency.
  ///
  /// In en, this message translates to:
  /// **'MY CONSISTENCY'**
  String get my_consistency;

  /// No description provided for @calendar_currently_not_available.
  ///
  /// In en, this message translates to:
  /// **'The calendar view will be available soon.'**
  String get calendar_currently_not_available;

  /// No description provided for @in_depth_analysis.
  ///
  /// In en, this message translates to:
  /// **'IN-DEPTH ANALYSIS'**
  String get in_depth_analysis;

  /// No description provided for @body_measurements.
  ///
  /// In en, this message translates to:
  /// **'Body measurements'**
  String get body_measurements;

  /// No description provided for @measurements_description.
  ///
  /// In en, this message translates to:
  /// **'Analyze weight, body fat percentage and circumference.'**
  String get measurements_description;

  /// No description provided for @nutrition_description.
  ///
  /// In en, this message translates to:
  /// **'Evaluate macros, calories and trends.'**
  String get nutrition_description;

  /// No description provided for @training_analysis.
  ///
  /// In en, this message translates to:
  /// **'Training analysis'**
  String get training_analysis;

  /// No description provided for @training_analysis_description.
  ///
  /// In en, this message translates to:
  /// **'Track volume, strength and progression.'**
  String get training_analysis_description;

  /// No description provided for @load_dots.
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get load_dots;

  /// No description provided for @profile_capslock.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile_capslock;

  /// No description provided for @settings_capslock.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings_capslock;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @my_goals.
  ///
  /// In en, this message translates to:
  /// **'My goals'**
  String get my_goals;

  /// No description provided for @my_goals_description.
  ///
  /// In en, this message translates to:
  /// **'Adjust calories, macros and water.'**
  String get my_goals_description;

  /// No description provided for @backup_and_import.
  ///
  /// In en, this message translates to:
  /// **'Data backup & import'**
  String get backup_and_import;

  /// No description provided for @backup_and_import_description.
  ///
  /// In en, this message translates to:
  /// **'Create backups, restore, and import data.'**
  String get backup_and_import_description;

  /// No description provided for @about_and_legal_capslock.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & LEGAL'**
  String get about_and_legal_capslock;

  /// No description provided for @attribution_and_license.
  ///
  /// In en, this message translates to:
  /// **'Attribution & Licenses'**
  String get attribution_and_license;

  /// No description provided for @data_from_off_and_wger.
  ///
  /// In en, this message translates to:
  /// **'Data from Open Food Facts and wger.'**
  String get data_from_off_and_wger;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get app_version;

  /// No description provided for @all_measurements.
  ///
  /// In en, this message translates to:
  /// **'ALL MEASUREMENTS'**
  String get all_measurements;

  /// No description provided for @date_and_time_of_measurement.
  ///
  /// In en, this message translates to:
  /// **'Date & time of measurement'**
  String get date_and_time_of_measurement;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lightweight'**
  String get onbWelcomeTitle;

  /// Onboarding slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Let’s start by setting personal goals to guide training and nutrition.'**
  String get onbWelcomeBody;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Track everything'**
  String get onbTrackTitle;

  /// Onboarding slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Log nutrition, workouts, and measurements — all in one place.'**
  String get onbTrackBody;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Offline-first & privacy'**
  String get onbPrivacyTitle;

  /// Onboarding slide 3 description
  ///
  /// In en, this message translates to:
  /// **'Your data stays on the device. No cloud accounts, no background sync.'**
  String get onbPrivacyBody;

  /// Onboarding final slide title
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get onbFinishTitle;

  /// Onboarding final slide description
  ///
  /// In en, this message translates to:
  /// **'You’re ready to explore the app. You can adjust settings anytime.'**
  String get onbFinishBody;

  /// Final button label to finish onboarding
  ///
  /// In en, this message translates to:
  /// **'Let’s go!'**
  String get onbFinishCta;

  /// Settings item to reopen onboarding
  ///
  /// In en, this message translates to:
  /// **'Show tutorial again'**
  String get onbShowTutorialAgain;

  /// Optional CTA linking to Goals screen from onboarding
  ///
  /// In en, this message translates to:
  /// **'Set goals'**
  String get onbSetGoalsCta;

  /// Onboarding header title
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get onbHeaderTitle;

  /// Skip button label in onboarding header
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbHeaderSkip;

  /// Back button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// Next button in onboarding footer
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// Guide banner title in onboarding
  ///
  /// In en, this message translates to:
  /// **'How this tutorial works'**
  String get onbGuideTitle;

  /// Guide banner description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Swipe between slides or use Next. Tap the buttons on each slide to try features. You can finish anytime with Skip.'**
  String get onbGuideBody;

  /// CTA to open nutrition tracking from onboarding
  ///
  /// In en, this message translates to:
  /// **'Open nutrition'**
  String get onbCtaOpenNutrition;

  /// CTA to learn more about privacy/offline
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get onbCtaLearnMore;

  /// Badge label shown after completing CTA
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onbBadgeDone;

  /// Hint text on goals slide
  ///
  /// In en, this message translates to:
  /// **'Tip: adjust targets first'**
  String get onbTipSetGoals;

  /// Hint text on nutrition slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add one entry today'**
  String get onbTipAddEntry;

  /// Hint on privacy slide about local data control
  ///
  /// In en, this message translates to:
  /// **'You control all data locally'**
  String get onbTipLocalControl;

  /// Onboarding slide 2 replacement body: step-by-step nutrition logging instructions
  ///
  /// In en, this message translates to:
  /// **'How to log nutrition:\n• Open the Food tab.\n• Tap the + button.\n• Search products or scan a barcode.\n• Adjust portion and time.\n• Save to your diary.'**
  String get onbTrackHowBody;

  /// Onboarding slide title for measurements
  ///
  /// In en, this message translates to:
  /// **'Track measurements'**
  String get onbMeasureTitle;

  /// Step-by-step instructions for adding measurements
  ///
  /// In en, this message translates to:
  /// **'How to add measurements:\n• Open the Stats tab.\n• Tap the + button.\n• Choose a metric (e.g., weight, waist, body fat).\n• Enter value and time.\n• Save to your history.'**
  String get onbMeasureBody;

  /// Hint for measurements slide
  ///
  /// In en, this message translates to:
  /// **'Tip: add today’s weight to start your graph'**
  String get onbTipMeasureToday;

  /// Onboarding slide title for training routines
  ///
  /// In en, this message translates to:
  /// **'Train with routines'**
  String get onbTrainTitle;

  /// Instructions for creating a routine and starting a workout
  ///
  /// In en, this message translates to:
  /// **'Create a routine and start a workout:\n• Open the Train tab.\n• Tap Create routine to add exercises and sets.\n• Save the routine.\n• Tap Start to begin, or use “Start empty workout”.'**
  String get onbTrainBody;

  /// Hint for training slide
  ///
  /// In en, this message translates to:
  /// **'Tip: start an empty workout to log a quick session'**
  String get onbTipStartWorkout;

  /// No description provided for @unitsSection.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSection;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight units'**
  String get weightUnit;

  /// No description provided for @lengthUnit.
  ///
  /// In en, this message translates to:
  /// **'unit of length'**
  String get lengthUnit;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Favorites'**
  String get noFavorites;

  /// No description provided for @nothingTrackedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet'**
  String get nothingTrackedYet;

  /// No description provided for @snackbarBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for barcode \"{barcode}\".'**
  String snackbarBarcodeNotFound(String barcode);

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chest, Back, Legs...'**
  String get categoryHint;

  /// No description provided for @validatorPleaseEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category.'**
  String get validatorPleaseEnterCategory;

  /// No description provided for @dialogEnterPasswordImport.
  ///
  /// In en, this message translates to:
  /// **'Enter password to import backup'**
  String get dialogEnterPasswordImport;

  /// No description provided for @dataManagementBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightweight Data Backup'**
  String get dataManagementBackupTitle;

  /// No description provided for @dataManagementBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Back up or restore all your app data. Ideal for changing devices.'**
  String get dataManagementBackupDescription;

  /// No description provided for @exportEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Export Encrypted'**
  String get exportEncrypted;

  /// No description provided for @dialogPasswordForExport.
  ///
  /// In en, this message translates to:
  /// **'Password for encrypted export'**
  String get dialogPasswordForExport;

  /// No description provided for @snackbarEncryptedBackupShared.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup shared.'**
  String get snackbarEncryptedBackupShared;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get exportFailed;

  /// No description provided for @csvExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Export (CSV)'**
  String get csvExportTitle;

  /// No description provided for @csvExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Export parts of your data as a CSV file for analysis in other programs.'**
  String get csvExportDescription;

  /// No description provided for @snackbarSharingNutrition.
  ///
  /// In en, this message translates to:
  /// **'Sharing nutrition diary...'**
  String get snackbarSharingNutrition;

  /// No description provided for @snackbarExportFailedNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Export failed. There may be no entries yet.'**
  String get snackbarExportFailedNoEntries;

  /// No description provided for @snackbarSharingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Sharing measurements...'**
  String get snackbarSharingMeasurements;

  /// No description provided for @snackbarSharingWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Sharing workout history...'**
  String get snackbarSharingWorkouts;

  /// No description provided for @mapExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Exercises'**
  String get mapExercisesTitle;

  /// No description provided for @mapExercisesDescription.
  ///
  /// In en, this message translates to:
  /// **'Map unknown names from logs to wger exercises.'**
  String get mapExercisesDescription;

  /// No description provided for @mapExercisesButton.
  ///
  /// In en, this message translates to:
  /// **'Start Mapping'**
  String get mapExercisesButton;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backups'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodically saves a backup in the folder. Current folder:'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'App-Documents/Backups (Default)'**
  String get autoBackupDefaultFolder;

  /// No description provided for @autoBackupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get autoBackupChooseFolder;

  /// No description provided for @autoBackupCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get autoBackupCopyPath;

  /// No description provided for @autoBackupRunNow.
  ///
  /// In en, this message translates to:
  /// **'Check & Run Auto-Backup Now'**
  String get autoBackupRunNow;

  /// No description provided for @snackbarAutoBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup completed.'**
  String get snackbarAutoBackupSuccess;

  /// No description provided for @snackbarAutoBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-Backup failed or was canceled.'**
  String get snackbarAutoBackupFailed;

  /// No description provided for @noUnknownExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No unknown exercises found'**
  String get noUnknownExercisesFound;

  /// No description provided for @snackbarAutoBackupFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup folder set:\n{path}'**
  String snackbarAutoBackupFolderSet(String path);

  /// No description provided for @snackbarPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get snackbarPathCopied;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @involvedMuscles.
  ///
  /// In en, this message translates to:
  /// **'Involved Muscles'**
  String get involvedMuscles;

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary:'**
  String get primaryLabel;

  /// No description provided for @secondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary:'**
  String get secondaryLabel;

  /// No description provided for @noMusclesSpecified.
  ///
  /// In en, this message translates to:
  /// **'No muscles specified.'**
  String get noMusclesSpecified;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection'**
  String get noSelection;

  /// No description provided for @selectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// No description provided for @applyingChanges.
  ///
  /// In en, this message translates to:
  /// **'Applying changes...'**
  String get applyingChanges;

  /// No description provided for @applyMapping.
  ///
  /// In en, this message translates to:
  /// **'Apply Mapping'**
  String get applyMapping;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @macroDistribution.
  ///
  /// In en, this message translates to:
  /// **'Macronutrient Distribution'**
  String get macroDistribution;

  /// No description provided for @dialogFinishWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this workout?'**
  String get dialogFinishWorkoutBody;

  /// No description provided for @attributionText.
  ///
  /// In en, this message translates to:
  /// **'This app uses data from external sources:\n\n● Exercise data and images from wger (wger.de), licensed under CC-BY-SA 4.0.\n\n● Food database from Open Food Facts (openfoodfacts.org), available under the Open Database License (ODbL).'**
  String get attributionText;

  /// No description provided for @errorRoutineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Routine not found'**
  String get errorRoutineNotFound;

  /// No description provided for @workoutHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your history is empty'**
  String get workoutHistoryEmptyTitle;

  /// No description provided for @workoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete'**
  String get workoutSummaryTitle;

  /// No description provided for @workoutSummaryExerciseOverview.
  ///
  /// In en, this message translates to:
  /// **'Exercise Overview'**
  String get workoutSummaryExerciseOverview;

  /// No description provided for @nutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'nutrition diary'**
  String get nutritionDiary;

  /// No description provided for @detailedNutrientGoals.
  ///
  /// In en, this message translates to:
  /// **'Detailed Nutrients'**
  String get detailedNutrientGoals;

  /// No description provided for @supplementTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplement Tracker'**
  String get supplementTrackerTitle;

  /// No description provided for @supplementTrackerDescription.
  ///
  /// In en, this message translates to:
  /// **'Track goals, limits, and intake.'**
  String get supplementTrackerDescription;

  /// No description provided for @createSupplementTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Supplement'**
  String get createSupplementTitle;

  /// No description provided for @supplementNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplement Name'**
  String get supplementNameLabel;

  /// No description provided for @defaultDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Dose'**
  String get defaultDoseLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit (e.g. g, mg)'**
  String get unitLabel;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal (optional)'**
  String get dailyGoalLabel;

  /// No description provided for @dailyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit (optional)'**
  String get dailyLimitLabel;

  /// No description provided for @dailyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgressTitle;

  /// No description provided for @todaysLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Log'**
  String get todaysLogTitle;

  /// No description provided for @logIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Intake'**
  String get logIntakeTitle;

  /// No description provided for @emptySupplementGoals.
  ///
  /// In en, this message translates to:
  /// **'Set goals or limits for supplements to see your progress here.'**
  String get emptySupplementGoals;

  /// No description provided for @emptySupplementLogs.
  ///
  /// In en, this message translates to:
  /// **'No intake logged for today yet.'**
  String get emptySupplementLogs;

  /// No description provided for @doseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseLabel;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Theme, units, data and more'**
  String get settingsDescription;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @caffeinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Caffeine (optional)'**
  String get caffeinePrompt;

  /// No description provided for @caffeineUnit.
  ///
  /// In en, this message translates to:
  /// **'mg per 100ml'**
  String get caffeineUnit;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @measurementWeightCapslock.
  ///
  /// In en, this message translates to:
  /// **'BODY WEIGHT'**
  String get measurementWeightCapslock;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
