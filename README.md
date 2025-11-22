# Lightweight - Your Offline-First Fitness Tracker

<p align="center">
  <strong>A modern, privacy-first fitness and nutrition tracking app.<br>Offline-first, no cloud dependency, built with Flutter.</strong>
</p>

<p align="center">
  <img alt="GitHub License" src="https://img.shields.io/github/license/rfivesix/lightweight?style=for-the-badge">
  <img alt="GitHub Stars" src="https://img.shields.io/github/stars/rfivesix/lightweight?style=for-the-badge&logo=github">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android%20|%20iOS-blue?style=for-the-badge">
</p>

---

## 🚀 Philosophy

**Lightweight** is built on a simple premise: **Your health data belongs to you.**
We believe in software that is fast, beautiful, and respects your privacy.

-   🔒 **Offline-First:** No registration, no cloud accounts, no tracking. Your data stays on your device.
-   💎 **Liquid Glass Design:** A unique, modern UI aesthetic featuring frosted glass elements and fluid animations.
-   💸 **Open & Free:** The core is open-source. No ads, no paywalls for basic features.

---

## ✨ Key Features

### 💪 Training
-   **Workout Logger:** Track sets, reps, weight, and RPE with an intuitive interface.
-   **Set Types:** Support for Normal, Warmup, Dropset, and Failure sets.
-   **Live Activity:** Your active workout session persists even if you close the app.
-   **Custom Routines:** Build your own plans or start an empty "Freestyle" workout.
-   **Exercise Database:** Built-in catalog (powered by wger) + ability to create **custom exercises**.

### 🥗 Nutrition & Hydration
-   **Food Diary:** Log meals via barcode scanner (Open Food Facts) or manual entry.
-   **Meal Grouping:** Create reusable "Meals" (e.g., "My Standard Breakfast") for quick logging.
-   **Fluid & Caffeine:** Dedicated tracking for water and caffeine intake (mg).
-   **Macro Goals:** Set dynamic targets for Calories, Protein, Carbs, Fat, Sugar, and Fiber.

### 💊 Supplement Hub
-   **Stack Manager:** Keep track of your daily supplements.
-   **Dosing:** Log intake with one tap and monitor daily limits or goals.
-   **Integration:** Caffeine intake automatically syncs with your nutrition summary.

### 📊 Data & Analysis
-   **Consistency Calendar:** Visual heatmap of your workout and nutrition streaks.
-   **Measurements:** Track body weight and circumference with interactive charts.
-   **Full Export:** Export your data as **CSV** for analysis or create an **encrypted JSON backup** to move to another device.

---

## 🛠️ Tech Stack

Built with ❤️ using **Flutter**.

-   **Database:** `sqflite` (Multi-DB architecture for User Data, Products, and Exercises).
-   **State Management:** `provider` & `ChangeNotifier`.
-   **UI Rendering:** Custom `liquid_glass_renderer` for the frosted glass effects.
-   **Theming:** `dynamic_color` for Material 3 support.

---

## 📥 Installation

To build the project locally:

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/rfivesix/lightweight.git
    cd lightweight
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🤝 Contributing

Feedback, bug reports, and pull requests are warmly welcome!
Please check the [open issues](https://github.com/rfivesix/lightweight/issues) to see what's currently in development.

---

## 📄 License & Acknowledgements

The source code is licensed under the **[MIT License](LICENSE)**.

This project relies on the amazing work of these open-data communities:
-   **[Open Food Facts](https://world.openfoodfacts.org/)**: Food product database, licensed under ODbL.
-   **[wger Workout Manager](https://wger.de/)**: Exercise database and API, licensed under CC-BY-SA 3.0.
