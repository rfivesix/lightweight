# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
## [0.4.0-beta.9] - 2025-11-25

### Bug Fixes
- **Datensicherung**: Ein Fehler wurde behoben, durch den Supplements und Supplement-Logs beim Wiederherstellen eines Backups ignoriert wurden. Diese werden nun korrekt in die Datenbank importiert (#70).
- **UI / Design**: Die AppBar im Mahlzeiten-Editor (`MealScreen`) wurde korrigiert. Sie verwendet nun die globale `GlobalAppBar` für ein einheitliches Design (Glassmorphismus), insbesondere im Light Mode (#68).

## [0.4.0-beta.8] - 2025-11-25
### UI/UX Improvements
- **Unified Design:** Replaced the native `AlertDialog`s with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete discard workout from main_screen.dart
### fix(l10n): localize remaining hardcoded UI strings for v0.6

- Added missing translation keys to `app_de.arb` and `app_en.arb` (Settings, Onboarding, Data Hub, Workout Bar).
- Replaced hardcoded strings in `SettingsScreen` (Visual Style selection).
- Localized search hints and empty states in `AddFoodScreen`.
- Localized app bar title in `DataManagementScreen`.
- Updated `OnboardingScreen` to use localization keys.

## [0.4.0-beta.7] - 2025-11-24

### Features
- **Android:** Enabled **Predictive Back Gesture** support for Android 14+ devices.

### UI/UX Improvements
- **Unified Design:** Replaced almost all native `AlertDialog`s and standard BottomSheets with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete confirmations, Supplement logging/editing, Meal ingredient picker, Routine pause/set type editing.
- **Edit Routine:** Aligned the pause timer display style with the Live Workout screen.
- **Food Details:** Fixed layout issue where content overlapped with the transparent app bar.

### Bug Fixes
- **Supplements:** The Supplement Hub and "Log Intake" dialog now correctly respect the date selected in the Diary (instead of always defaulting to "today").
- **Navigation:** Fixed back navigation stack when starting a workout from the Main Screen (back button now correctly returns to the dashboard).
- **Add Food:** Fixed a `RangeError` crash when scrolling to the bottom of the Meals tab.
## [0.4.0-beta.6] - 2025-11-22

### Fixed
*   **Critical: Custom Exercises**
    *   Fixed a database error that prevented users from saving new custom exercises (Issue #58).
    *   Resolved an issue where custom exercises appeared with empty titles when added to a routine.
*   **Critical: Data Restoration**
    *   Improved the backup import logic to strictly preserve original IDs for custom exercises. This prevents routines from breaking or losing exercises after restoring a backup.
*   **Profile Picture**
    *   Fixed a bug where deleting the profile picture did not visually update the app until a restart (Issue #31).
*   **Live Workout Stability**
    *   Fixed a layout crash that occurred when opening the "Change Set Type" menu.
    *   Fixed the "Finish Workout" dialog being inconsistent with the rest of the UI.
*   **Diary & Logging**
    *   Fixed the "Add Ingredient" flow in the Meal Editor which previously closed the menu without adding the item.
    *   Ensured that adding food, fluids, or supplements via the FAB always logs to the **currently selected date** in the diary, rather than defaulting to "now".

### Changed
*   **UI/UX Polish:**
    *   **Bottom Navigation:** Fixed the height of the Glass Bottom Navigation Bar to perfectly align with the Floating Action Button (Issue #61).
    *   **Scroll Padding:** Adjusted bottom spacing across all list screens (Routines, History, Explorer) so the last items are no longer hidden behind the navigation bar (Issue #60).
    *   **Liquid Glass Theme:** Reduced the background opacity and distortion thickness of the "Liquid" visual style to improve content readability.
*   **Modernized Menus:**
    *   Replaced remaining system dialogs (Edit Pause Time, Delete Confirmations, Set Type Picker) with the unified **Glass Bottom Menu**.
    *   Added visual symbols (N, W, F, D) to the Set Type selector for better recognition.

## [0.4.0-beta.5] - 2025-11-07

### Added
* **UI/UX:**
    * Added bottom spacer in the food explorer
    * added glass bottom menu in supplement screen
    * added glass bottom menu in data management screen
* **haptic:**
    * added haptic feedback on the glass navigationbar
### Changed
* haptic
    * increased haptic feedback when hovering on the weight graph
    * increased feedback on glassFAB
* **UI/UX**
    * changed the Appbar to blur
### Fixed
* Fixed an issue where a routine did not loaded.
    

## [0.4.0-beta.4] - 2025-11-07

### Changed
* **UI/UX: Liquid glass**
    * adjusted border intensity
    * adjusted design of the glass bottom menu


## [0.4.0-beta.3] - 2025-11-06

### Added
*   **New Feature: Optional "Liquid Glass" UI Style**
    *   A new, optional visual style can be enabled in `Settings > Appearance` to switch to a rounded, fluid, and translucent UI.
    *   This feature is powered by the `liquid_glass_renderer` package, providing a high-fidelity, cross-platform frosted glass effect on both iOS and Android.
    *   The standard "Glass" UI remains the default.

### Fixed
*   **Critical: Create Food Screen Unusable**
    *   Fixed a critical bug where the "Create Food" screen incorrectly displayed a numeric keyboard for text fields (name, brand), making it impossible to enter non-numeric characters. (Fixes #56)
*   **Critical: Create/Edit Routine Bugs**
    *   Resolved an issue where adding a new exercise to a routine did not visually update the list on the screen until the app was restarted. (Fixes #58)
    *   Fixed a bug where exercises added to a routine were missing their details (name, muscle groups) due to an inconsistent database query.
    *   Addressed a UI state bug where adding, removing, or changing set types in the routine editor would not update the UI in real-time.
*   **Database Stability:**
    *   Prevented crashes when saving custom food items by making the database insertion logic resilient to schema differences between the app model and the asset database.

### Changed
*   **UI/UX Consistency:**
    *   Replaced all standard `AlertDialog` pop-ups in the Supplement tracking feature with the modern `GlassBottomMenu` to provide a consistent and fluid user experience.
*   **Code Refactoring:**
    *   Simplified and stabilized the supplement logging flow by refactoring the UI logic into distinct, reusable widgets, resolving a crash when attempting to log a supplement.
    
## [0.4.0-beta.2] - 2025-10-22
### Added
* **App icon:** Now there is an App icon
### Fixed
* **Backup:** tried to fix the backup
### Changed
* **App Name:** Changed the name from "Lightweight" to "Hypertrack".


## [0.4.0-beta.1] - 2025-10-19

### Added

*   **New Feature: Onboarding Screen**
    *   Implemented the full, interactive Onboarding process for new users (or when the app is reset).
*   **New Feature: Initial Tab Navigation**
    *   The Main Screen now supports starting on a specific tab, improving navigation flexibility (e.g., deep linking).
*   **Fluid Log Editing**
    *   The "Edit Fluid Entry" dialog now includes fields for the **Name**, **Sugar per 100ml**, and **Caffeine per 100ml**, allowing for precise editing of non-water drinks.

### Fixed

*   **Critical Data Consistency: Fluid/Liquid Food Deletion**
    *   Fixed a critical bug where deleting a **liquid food entry** (e.g., a juice logged via the food tracker) did not correctly remove the linked Fluid Log and Caffeine Log entries, causing orphaned data (Fixes logic in `deleteFluidEntry`).
*   **Modal Display Issue (UX)**
    *   Fixed a bug where the Glass Bottom Menu (and other modals) sometimes failed to display correctly over the main navigation stack.
*   **Live Workout View**
    *   Corrected the padding in the Live Workout screen's exercise list, preventing the final exercise from being obscured by the bottom navigation/content spacer.

### Changed

*   **Major Branding Change: Renamed to "Lightweight"**
    *   The application has been officially renamed from **"Vita" to "Lightweight"** across all screens, assets, bundle identifiers, and localization files.
*   **UX Improvement: Modernized Edit Dialogs**
    *   The "Edit Food Entry" and "Edit Fluid Entry" flows in the Diary screen were upgraded from the old `AlertDialog` to the new **Glass Bottom Menu (Bottom Sheet)**, improving mobile UX.
*   **UI Consistency**
    *   Visually updated the buttons and backgrounds in the Floating Action Button (FAB) menu to ensure consistency with the established "Glass FAB" design language.

## [0.4.0-alpha.12] - 2025-10-15

### Added

*   **New Feature: Today's Workout Summary on Diary Screen**
    *   Workout statistics (Duration, Volume, Set Count) for the current day are now displayed directly on the Diary/Nutrition screen (Issue #55).
*   **New Hub UI: Nutrition Hub Overhaul**
    *   The **Nutrition Hub** (`/nutrition-hub` - Issue #53) has been completely redesigned with an improved UI and UX, including new statistical cards and analysis gateways.
*   **Database Asset Versioning**
    *   Implemented a robust versioning system for all internal asset databases (`vita_base_foods.db`, `vita_prep_de.db`, `vita_training.db`). This ensures that core app data is updated when the app version changes, preventing outdated database contents.
*   **Workout History Details**
    *   The Workout History screen now displays the **Total Volume** (in kg) and **Total Sets** for each logged workout, providing more context at a glance.
*   **Automatic Backup Check**
    *   The app now checks for and runs the automated daily backup process upon startup, increasing data security.
*   **New Routine Quick-Create Card**
    *   A new "Create Routine" card has been added to the Workout Hub for quick access.

### Fixed

*   **Critical: Database Name Display**
    *   Fixed a critical bug where localized food names (e.g., German, English) were not correctly retrieved from the product database, leading to the display of wrong or empty names in some parts of the app (Issue #56).
*   **Critical: Backup and Restore Stability**
    *   Fixed multiple critical issues related to the full backup/restore process (Issue #52), ensuring that **Supplements**, **Supplement Logs**, and detailed **Workout Set Logs** are correctly serialized, backed up, and restored.
*   **Workout History Filtering**
    *   Fixed a bug in the workout database helper that caused uncompleted/draft workout logs to be included in the history; only workouts with the status `completed` are now shown.
*   **Exercise Name Localization**
    *   Corrected the logic for displaying exercise names in the Exercise Catalog and Detail screens to correctly prioritize localized names (`name_de`, `name_en`).
*   **Profile Picture Deletion**
    *   Fixed an issue where deleting the profile picture did not work as intended (Issue #31).
*   **Fluid Log Processing**
    *   The calculation for Carbs and Sugar in fluid entries is now correctly scaled by the logged quantity.

### Changed

*   **Reworked Add Menu (FAB)**
    *   The Floating Action Button (FAB) menu on the main screen has been refined for better usability and visual feedback (Issue #50).
*   **Improved Water Section UI/UX**
    *   The Water section in the Diary screen has received general UI/UX enhancements (Issue #54).
*   **Routineless Workout Restoration**
    *   Restoring a workout that was not based on a routine now correctly determines the order of exercises based on the original log order.
*   **Enhanced Swipe-to-Delete Confirmation**
    *   Added explicit confirmation dialogues for the swipe-to-delete actions on Routines, Meals, and Nutrition/Fluid Logs to prevent accidental data loss.
*   **Improved Search Queries**
    *   Product search now searches across `name`, `name_de`, and `name_en` fields, significantly improving discoverability.
*   **UI/UX Refinements**
    *   Numerous minor style adjustments across the app (typography, button padding, list item shadows) for a cleaner, more consistent look.
## Release Notes – 0.4.0-alpha.11+4011

### Added
*   New wger exercise database integrated, providing even more details and laying the groundwork for upcoming advanced analytics features.
*   First set of curated base foods added to the food catalog. More will follow soon.

### Changed
*   Adjusted item labels in the bottom navigation bar to max. 1 line for a cleaner UI.

### Fixed
*   Resolved critical issues with database migration and access, fixing crashes when viewing workout history or adding exercises to routines.
*   Fixed localization issue in the base foods catalog, ensuring food names are displayed in the correct language.

## Release Notes - 0.4.0-alpha.10+4010

### ✨ New Features & Major Improvements

*   **Enhanced Fluid Tracking:**
    *   Any liquid can now be logged with a name, quantity, sugar, and caffeine content via the new "+" menu.
    *   When logging food items, you can now specify that it is a liquid ("Add to water intake"). The quantity is then correctly added to the daily water goal.
*   **Automatic Caffeine Tracking:**
    *   Daily caffeine intake is now automatically calculated and displayed in the nutrition summary.
    *   Caffeine can be specified in "mg per 100ml" for both custom liquids and food items marked as liquid.
    *   A new "Caffeine" entry has been added to the trackable supplements.
*   **Improved Nutrition Analysis:**
    *   Calculations in the nutrition analysis (`nutrition_screen.dart`) and on the dashboard (`diary_screen.dart`) now correctly include calories, carbs, and sugar from all logged fluids.
*   **Expanded "Add" Menu:**
    *   The central speed-dial menu has been expanded with "Add Liquid" and "Log Supplement" options for faster access.

### 🐛 Bugfixes & Improvements

*   **Data Integrity on Deletion:** Fixed a critical bug where deleting fluid or food entries did not remove associated supplement logs (e.g., for caffeine). The deletion logic has been revised to ensure data consistency.
*   **Database Structure:** The database has been updated to version 19 to enable linking between food, fluid, and supplement entries.
*   **UI Improvements in Diary:** Fluids are now displayed in their own section (`Water & Drinks`) on the diary page for better clarity.
*   **Data Backup Fixes:** The backup model (`LightweightBackup`) has been updated to correctly handle the new `FluidEntry` data.

## Release Notes - 0.4.0-alpha.9+4009

### ✨ New
- Glass-styled bottom sheet menu (blur removed; smooth dimmed backdrop).
- “Add fluid” flow merged into the new bottom sheet (amount + date + time).
- “Start workout” bottom sheet with:
  - **Start empty workout** action on top.
  - List of routines below, each with a **Start** button; tap on the tile opens **Edit Routine**.
- “Track supplement intake” fully inline in the bottom sheet (select supplement → dose & time).
- **Nutrition** tab added to the bottom bar (temporary hub / empty state).
- **Profile** moved from bottom bar to the **right side of the AppBar** as a large avatar (uses user photo when set).

### 🎨 UX / Polish
- Bottom sheet now respects the on-screen keyboard (slides up smoothly).
- Consistent glass styling (rounded corners, straight hard edge around curve).
- Restored instant tab switching on bottom bar tap (no intermediate swipe animation).

### 🐞 Fixes
- Meals: GlassFAB redirection corrected to open meal screen in edit mode.
- Category localization fixed (translated labels show correctly).


## [0.4.0-alpha.8] - 2025-10-05
### Added
- Haptic feedback when selecting chart points and pressing the Glass FAB.
- Meal Screen redesign: consistent typography, SummaryCards for ingredients, contextual FAB.
- Meals list swipe actions consistent with Nutrition screen.

### Changed
- Context-aware FAB in Meals tab (“Create Meal”), removed redundant header button.
- Meal editor visual consistency: non-filled top-right Save button.
- Ingredient layout updated (SummaryCards, editable amounts on right).
- TabBar text no longer changes size on selection.
- Diary meal headers show macro line (kcal · P · C · F) below title.

### Fixed
- Save button tap area and modal layering in Meal Editor.
- Scanner and Add Food refresh logic for recents/favorites.
- Defensive database handling during barcode scan.

### Notes
- No database migration required.
- Final alpha polish before beta.
EOF

## [0.4.0-alpha.7] - 2025-10-03
### Fixed
- Backup import failed with *“no such column is_liquid”* → caused Diary/Stats to hang
- Old backups without password could not be restored (fallback logic improved)
- App stuck in loading when DB initialization or restore failed

### Improved
- Import logic now automatically adapts to schema changes (ignores missing columns)

### Internal
- Defensive DB handling and better logging during import

## [0.4.0-alpha.6] - 2025-10-03
### Fixed
- **Database hotfix**: ensured that all core tables (`food_entries`, `water_entries`, `meals`, `supplement_logs`, etc.) and indices are always created on upgrade, preventing missing-table errors on fresh installs or after updates.
- Fixed `DiaryScreen` and `Statistics` not loading due to missing DB structures.
- Backup/restore flow more robust, no crashes when tables were absent.

### Notes
This is a hotfix release following alpha.4, focused only on database migration stability.  

## [0.4.0-alpha.5+4005] - 2025-10-03

### 🚀 New Features
- **Meals (Beta):**
  - Create and edit meals composed of multiple food items.
  - Add ingredients via search or base food catalog.
  - Adjust ingredient amounts before saving when logging a meal.
  - Select meal type (Breakfast, Lunch, Dinner, Snack) — entries are correctly assigned to the chosen category in the diary.
- **Combined Catalog & Search Tab:**
  - Replaced separate Search and Base Foods tabs with a unified Catalog & Search tab.
  - Expandable base categories visible when no search query is entered.
  - Search results prioritized: base foods first, then OFF/User entries.
  - Barcode scanner button included directly in the search field.
- **Caffeine Auto-Logging:**
  - Automatically log caffeine intake from drinks (liquid products) with a `caffeine_mg_per_100ml` value when added to the diary.
  - Linked directly to the built-in caffeine supplement (non-removable, unit locked to mg).
- **Enhanced Empty States:**
  - Meals tab shows “No meals yet” illustration and action button to create a meal.
  - Improved UI in Favorites & Recents with icons and contextual instructions.

### 🛠 Improvements
- **Base Food Database:**
  - Now ships empty by default (no prefilled, incorrect entries).
  - Completely removed the category “Mass Gainer Bulk”.
- **Database Handling:**
  - Safer `getProductByBarcode` implementation in `ProductDatabaseHelper`: recovers from `database_closed` by reopening databases.
  - Ensures correct handling of base vs. OFF product sources.
- **Diary Screen:**
  - Food entries from meals are now grouped under the correct meal type (Breakfast, Lunch, Dinner, Snack).
  - Macro calculations (calories, protein, carbs, fat) displayed per meal.
- **UI / UX Enhancements:**
  - Consistent use of `SummaryCard` across food lists and meal cards.
  - Added “Add Food” button inside each diary meal card header.
  - Improved barcode scanner integration for a smoother workflow.
  - Caffeine unit locked (mg) and explained via helper text.

### 🐛 Fixes
- Fixed missing meal type in logged meal entries (causing them not to show in Diary, though they appeared in Nutrition overview).
- Fixed ingredient list in meal editor showing barcodes instead of product names.
- Fixed crash when selecting meal type in the bottom sheet (`setSheetState` vs `StatefulBuilder.setState`).
- Fixed null-safety errors in Add Food & Meal logging bottom sheets.
- Fixed duplicated `Expanded`/`TabBarView` layout issues (RenderFlex overflow with unbounded constraints).
- Fixed initialization bug: after Hot Reload, some database migrations were not applied — required Hot Restart (documented).
- Fixed issue with “confirm” translation key missing — replaced with `l10n.save`.

### 🔎 Known Limitations
- **Meals are still in beta:**
  - No drag-and-drop reordering of ingredients yet.
  - No duplication/cloning of meals.
  - No optional photos or icons for meals.
  - Caffeine supplement logs are not yet directly linked to the specific FoodEntry ID (planned).
  - Base Food DB is currently empty — contribution workflow (community-curated entries, moderation, import) planned for future versions.

## 0.4.0-alpha.4 — 2025-10-02
### Added
- DEV-only editor in Food Detail Screen: allows editing base food entries directly on-device
- Export function for `vita_base_foods.db` via share (e.g., AirDrop, Mail, Drive)
- Search & category accordion in "Grundnahrungsmittel" tab with emoji headers

### Changed
- AppBar styling unified: Food Detail, Supplement Hub, and Settings now share large bold title style
- Minor OLED/dark mode polish for nutrient cards

### Fixed
- Database auto-reopen after hot reload (no more `database_closed` errors)
- Edits in base food database now persist correctly across re-entry

## 0.4.0-alpha.3 — 2025-10-01
### Added
- New bottom bar layout with detached GlassFab
- Running workout bar redesign (filled “Continue”, outlined red “Discard”)

### Changed
- Localized screen names (Diary/Workout/Stats/Profile; Heute/Gestern/Vorgestern)
- Weight chart: inline date next to big weight, hover updates value/date, no tooltip popup
- Routine & Measurements screens: swipe actions match Nutrition design

### Fixed
- Back button in Add Food
- “Done” moved to AppBar in add exercise flow
- App version alignment (minSdk 21, targetSdk 36, versionName/Code via local.properties)

### Known
- Play Store signing not configured (debug signing only for GitHub APK)

## [0.2.0] - 2025-09-24

This release focuses on massive stability improvements, UI consistency, and critical bug fixes. The user experience during workouts is now significantly more robust and visually polished.

### ✨ Added
- **Improved "Last Time" Performance Display:** The "Last Time" metric in the live workout screen now accurately shows the weight and reps for each individual set from the previous workout, providing better context for progressive overload.

### 🐛 Fixed
- **CRITICAL: Live Workout Persistence:** An active workout session now correctly persists even if the app is closed by the user or the operating system. All logged sets, exercise order, custom rest times, and in-progress values are restored upon reopening the app, preventing data loss. (Fixes #30)
- **Live Workout UI Bugs:**
    - Correctly highlights completed sets with a subtle green background without obscuring the text fields. (Fixes #29)
    - The alternating background colors for set rows now adapt properly to both light and dark modes. (Fixes #25)
- **State Management Stability:** Resolved `initState` errors by moving context-dependent logic to `didChangeDependencies`, improving app stability.
- **Localization (l10n) Fixes:**
    - The "Delete Profile Picture" button is now fully localized. (Fixes #27)
    - The "Detailed Nutrients" headline in the Goals Screen is now localized. (Fixes #26)

### ♻️ Changed
- **UI Refactoring (`EditRoutineScreen`):** The screen for editing routines has been completely redesigned to match the modern, seamless list-style of the live workout screen, ensuring a consistent user experience across all workout-related views. (Fixes #28)
- **Centralized State Logic:** All logic for managing a live workout session is now consolidated within the `WorkoutSessionManager`. The `LiveWorkoutScreen` is now primarily responsible for displaying the state, leading to cleaner and more maintainable code.
- **Optimized App Startup:** The workout recovery logic was moved from `main.dart` into the `WorkoutSessionManager` to streamline the app's initialization process.
## [0.1.0] - 2025-09-23

This is the first feature-complete, stable pre-release of Lightweight. It establishes a robust, offline-first foundation for tracking nutrition, workouts, and body measurements.

### ✨ Added
- **Consistency Calendar:** A visual calendar on the Statistics tab now displays days with logged workouts and nutrition entries to motivate users (#22).
- **Macronutrient Calculator:** The Goals screen now features interactive sliders to set macro targets as percentages, which automatically calculate the corresponding gram values (#18).
- **Full Localization:** The entire user interface is now available in both English and German.
- **Encrypted Backups:** Added functionality to create password-protected, encrypted backups for enhanced security.
- **Barcode Scanner:** Integrated a barcode scanner for quick logging of food items.

### 🐛 Fixed
- The app version displayed in the profile screen now correctly reflects the version from `pubspec.yaml` (#24).
- The weight history chart on the Home screen now correctly updates when the date range filter is changed.
- The Backup & Restore system now correctly processes workout routines, preventing data loss.

### ♻️ Changed
- **Database-Powered Exercise Mappings:** Exercise name mappings for imports are now stored robustly in the database instead of SharedPreferences, enabling automatic application during future imports (#23).
- **Unified UI/UX:** The application's design has been polished for a consistent user experience, especially regarding AppBars, dialogs, and buttons.
- **Improved Exercise Creation:** The "Create Exercise" screen now features an intelligent autocomplete field for categories and a chip-based selection for muscle groups, improving data quality and usability.