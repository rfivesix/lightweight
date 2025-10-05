# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
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