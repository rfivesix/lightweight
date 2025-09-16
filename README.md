<!-- ADD YOUR LOGO HERE, e.g. <p align="center"><img src=".github/assets/logo.png" width="200"></p> -->

<h1 align="center">Lightweight</h1>

<p align="center">
  <strong>A modern, privacy-first fitness and nutrition tracking app.<br>Offline-first, no cloud dependency, built with Flutter.</strong>
</p>

<p align="center">
  <img alt="GitHub License" src="https://img.shields.io/github/license/rfivesix/lightweight?style=for-the-badge">
  <img alt="GitHub Stars" src="https://img.shields.io/github/stars/rfivesix/lightweight?style=for-the-badge&logo=github">
</p>

---

## ✨ Core Philosophy

Lightweight is developed based on four clear principles that set it apart from many other fitness apps:

*   🔒 **Data Sovereignty & Offline-First:** Your personal health data belongs to you. All your entries (nutrition, workouts, measurements) are stored **exclusively locally on your device**. There is no registration, no cloud, and no tracking.
*   🎨 **Modern, Adaptive Design:** The user interface dynamically adapts to your system's theme and utilizes a clean, modern design language for a seamless and aesthetic integration, inspired by Material You.
*   💸 **No Subscriptions, No Ads:** Lightweight is designed as a tool for the user, not as a data or money-collecting platform. The core of the app will always remain free and open source.
*   🚀 **Powerful & Intuitive:** Beneath its simple surface lies a powerful app with features usually found only in expensive premium apps – from a vast exercise catalog to detailed analysis tools.

---

## 🚀 Features

Lightweight is divided into three core modules that work seamlessly together:

### 🥗 Nutrition
*   **Comprehensive Tracking:** Log calories and macronutrients (protein, carbohydrates, fat) as well as micronutrients (sugar, fiber, salt).
*   **Vast Food Database:** Search through hundreds of thousands of products from the German **Open Food Facts** database.
*   **Rapid Entry:** (Future: Barcode scanner), favorites lists, "recently used" lists, and the ability to create your own custom food items.
*   **Detailed Analysis:** A dedicated analysis screen with dynamic daily and multi-day views, filter chips, and an expandable nutrition summary.

### 💪 Workout
*   **Extensive Exercise Catalog:** Over 380+ exercises with bilingual descriptions and images, based on the **wger** database, including filtering by muscle groups/categories.
*   **Flexible Workout Planner (`RoutinesScreen` & `EditRoutineScreen`):**
    *   Create and edit an unlimited number of workout routines.
    *   Add exercises from the catalog or create your own.
    *   Plan each set individually with type (normal, warmup, etc.), target weight, and target repetitions.
    *   Define individual rest times for each exercise.
    *   Intuitively sort exercises via **drag-and-drop**.
*   **Interactive Live Tracking (`LiveWorkoutScreen`):**
    *   Log your workout in real-time with an always-on timer.
    *   View your previous performance for progressive overload.
    *   Automatic rest timer.
    *   Adapt your workout spontaneously: add or remove sets/exercises, or reorder them.
*   **Complete Workout History:**
    *   View every completed workout in detail.
    *   Edit any value, date, or notes post-workout.

### 📏 Measurements
*   **Holistic Tracking:** Log over 15 different body measurements, from weight and body fat to circumferences.
*   **Visual Progress Analysis:** An interactive graph shows your progress over time. Navigate through your data using arrow buttons or filter chips.
*   **Dashboard Integration:** Your weight trend is prominently displayed on the dashboard for daily motivation.

---

## 🗺️ Roadmap (Version 0.0.2 - Pre-Alpha)

This is an early preview. The current version (0.0.2) lays the foundation for a powerful fitness tracker. Key areas of focus for future releases include:

*   **Robust & Atomic Data Import/Export:** Implementing a foolproof backup/restore mechanism to prevent data loss.
*   **Offline Barcode Scanner:** Directly scan food products without internet access.
*   **Advanced Analytics & AI:** Introducing scientific analysis tools, AI-powered recommendations, and adherence scores.
*   **Workout Persistence:** Ensuring live workout sessions can be resumed even after app closure.
*   **Integrations:** Connecting with platforms like Health Connect and Strava (opt-in).
*   **Cloud Sync (Premium Tier):** Offering an optional, secure cloud synchronization as a premium feature.

---

## 🛠️ Technical Architecture

For developers interested in contributing to the project, here's a brief overview:

*   **State Management:** The app consciously uses Flutter's built-in approach with `StatefulWidget` and `setState` to keep the code simple, understandable, and free from external dependencies. A simple singleton service (`WorkoutSessionManager`, `ProfileService`) is used for global, persistent UI state.

*   **Database System (`sqflite`):** Lightweight utilizes a unique **three-database system** to ensure clean data separation:
    1.  **`vita_prep_de.db` (Food Products):** A large, read-only database generated from Open Food Facts data and copied from the app's assets.
    2.  **`vita_training.db` (Workout Data):** Contains the static exercise catalog (from wger) as well as user-created routines and logs. Also copied from assets.
    3.  **`vita_user.db` (User Data):** The only dynamic database, created empty on the user's device. It stores all personal entries such as meals, water intake, and measurements.

*   **Data Pipelines:** The static databases are prepared offline using **Python scripts** that download, filter, clean, and convert raw data from Open Food Facts and the wger API into an optimized SQLite format.

---

## 🤝 Contributing

Feedback, bug reports, and pull requests are warmly welcome!

*   **Report Bugs:** If you find a bug, please create an [Issue](https://github.com/rfivesix/lightweight/issues) and describe the problem as detailed as possible.
*   **Suggest Features:** Have an idea for a new feature? Also create an [Issue](https://github.com/rfivesix/lightweight/issues) and describe your vision.

---

## 📄 License & Acknowledgements

The source code for this project is licensed under the **[MIT License](LICENSE)**.

This project would not be possible without the fantastic work of the following open-data communities:

*   **[Open Food Facts](https://de.openfoodfacts.org/)**: Food product database, licensed under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/).
*   **[wger Workout Manager](https://wger.de/)**: Exercise database and API, licensed under [CC-BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

---

## 📬 Contact

Questions or feedback? Create an Issue or contact me at `richard@schotte.me`.