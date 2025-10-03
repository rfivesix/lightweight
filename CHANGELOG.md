# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
## 0.4.0-alpha.5+4005 — 2025-10-03
### Neu
- **Mahlzeiten (Beta):** Mahlzeiten erstellen/bearbeiten, Zutaten aus Suche & Grundnahrungsmitteln hinzufügen, Mengen im „Zum Tagebuch hinzufügen“-Sheet anpassen, MealType auswählen.
- **Kombinierter Tab:** „Katalog & Suche“ zeigt zunächst Kategorien aus der Base-DB, bei Suchbegriffen zuerst Base-Treffer, dann OFF/User-Treffer.
- **Koffein-Autologik:** Flüssige Produkte mit hinterlegtem Koffein (mg/100ml) loggen automatisch das Koffein-Supplement mit.

### Änderungen
- **Base-Food-Datenbank** jetzt initial leer; Kategorie „Mass Gainer Bulk“ entfernt.
- Diverse UI-Verbesserungen (Empty States, SummaryCards, Scanner-Button in Suche).

### Fixes
- Datenbank-Zugriffe robuster (Re-Open bei `database_closed`).
- MealType wird korrekt mitgeschrieben, Einträge erscheinen im Tagebuch je Mahlzeit.
- Diverse kleine NPE/Null-Safety-Fixes im Add-Food-Flow.

### Bekannte Einschränkungen
- Mahlzeiten sind Beta: Umbenennen/Neuanordnen der Zutaten ist basic (kein Drag’n’Drop).
- Koffein-Verlinkung zu konkreter FoodEntry-ID erfolgt später.

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