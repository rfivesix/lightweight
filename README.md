# Lightweight - Your Offline-First Fitness Tracker

<p align="center">
  <strong>A modern, privacy-first fitness and nutrition tracking app.<br>Offline-first, no cloud dependency, built with Flutter.</strong>
</p>

<p align="center">
  <img alt="GitHub License" src="https://img.shields.io/github/license/rfivesix/lightweight?style=for-the-badge">
  <img alt="GitHub Stars" src="https://img.shields.io/github/stars/rfivesix/lightweight?style=for-the-badge&logo=github">
</p>

---

## ✨ Features at a Glance

| | |
| :--- | :--- |
| 📊 **Modern Dashboard** | A central hub showing your daily calories, macros, water intake, and weight trend. |
| 🥗 **Advanced Nutrition Tracking** | Log meals via barcode scanner, a vast offline food database, or by creating custom food items. |
| 💪 **Flexible Workout Planner** | Build detailed workout routines with various set types (Normal, Warmup, Dropset, Failure) and track your sessions live. |
| 📅 **Consistency Calendar** | A beautiful heatmap calendar that visualizes your logged workout and nutrition days to keep you motivated. |
| 🎯 **Intuitive Goal Setting** | Set your targets for calories, body measurements, and macronutrients using either direct gram input or a percentage-based calculator. |
| 📦 **Full Data Control** | Your data stays on your device. Import your history from other apps (e.g., Hevy) and export all your data anytime as an unencrypted JSON backup or CSV files. |

## 📸 Screenshots

*Screenshots are taken from v0.1.0 and show both light and dark mode.*

| Home (Dark) | Routines (Dark) | Live Workout (Dark) |
| :---: | :---: | :---: |
| <img src="assets/screenshots/home_darkmode.png" width="250"> | <img src="assets/screenshots/Routines_darkmode.png" width="250"> | <img src="assets/screenshots/live_workout_darkmode.png" width="250"> |
| **Food (Light)** | **Stats (Light)** | **Goals (Dark)** |
| <img src="assets/screenshots/food_whitemode.png" width="250"> | <img src="assets/screenshots/Stats_whitemode.png" width="250"> | <img src="assets/screenshots/my_goals_darkmode.png" width="250"> |


## 🚀 Philosophy & Core Principles

Lightweight is developed with a clear vision:

-   🔒 **Offline-First & Privacy:** Your health data belongs to you. Everything is stored locally on your device. No registration, no cloud, no tracking.
-   🎨 **Modern & Adaptive Design:** The UI adapts to your system's theme and uses a clean, modern design language inspired by Material You.
-   💸 **Free, Open & No Ads:** The core of the app will always be free and open-source, without subscriptions or advertisements.
-   🚀 **Powerful & Intuitive:** A simple surface that hides powerful features usually found only in premium apps.

---

## 🛠️ Technical Architecture

-   **State Management:** `StatefulWidget` and `setState` are used for local state, with simple singleton services (`WorkoutSessionManager`, `ProfileService`) for global UI state.
-   **Database System (`sqflite`):** A unique three-database system ensures clean data separation:
    1.  **Food Products DB (`vita_prep_de.db`):** A large, read-only database from Open Food Facts.
    2.  **Workout & Exercise DB (`vita_training.db`):** Contains the static exercise catalog from wger, plus user-created routines and logs.
    3.  **User Data DB (`vita_user.db`):** The only dynamic database, storing all personal entries.

---

## 🤝 Contributing

Feedback, bug reports, and pull requests are warmly welcome! Please check the [open issues](https://github.com/rfivesix/lightweight/issues) to see what's next.

---

## 📄 License & Acknowledgements

The source code is licensed under the **[MIT License](LICENSE)**.

This project relies on the amazing work of these open-data communities:
-   **[Open Food Facts](https://de.openfoodfacts.org/)**: Food product database, licensed under ODbL.
-   **[wger Workout Manager](https://wger.de/)**: Exercise database and API, licensed under CC-BY-SA 3.0.