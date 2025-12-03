# Hypertrack

**The modern, privacy-first fitness & nutrition tracker.**

Hypertrack (formerly *Lightweight*) is an open-source, offline-first application built with Flutter. It aims to replace fragmented fitness tools by combining advanced workout logging, nutrition tracking, and body metrics into a single, cohesive ecosystem—without compromising your data privacy.

> **Note:** This project is currently in **Active Beta**.

---

## ⚠️ **Important Disclaimer: Early Access**

**Please read before using:**

Hypertrack is currently undergoing a massive architectural refactoring (moving from v0.4 to v0.5). We are transitioning the database foundation from integer-based IDs to UUIDs and changing the local storage engine to prepare for cloud synchronization.

* **Data Compatibility:** While we strive to provide migration tools, **breaking changes to the database structure are expected** in the upcoming updates.
* **Data Safety:** There is a non-zero risk that local data created with current versions might need to be manually exported/imported or could be lost during the transition to v1.0.
* **Recommendation:** Please use the built-in **Backup (JSON)** feature regularly if you use the app for daily tracking.

---

## 🌟 Current Features (v0.4+)

Hypertrack is already a fully functional daily driver for fitness enthusiasts.

### 🏋️‍♂️ Workout Tracking
* **Routines:** Create custom workout plans with specific exercises, sets, and targets.
* **Live Logging:** Track your sessions in real-time with an integrated rest timer, RPE tracking, and previous performance references.
* **Flexible Sets:** Support for Normal, Warmup, Dropset, and Failure sets.
* **History:** Detailed log of all past workouts, volume, and personal records.

### 🍎 Nutrition & Hydration
* **Food Database:** Integrated with **Open Food Facts** for barcode scanning and product search.
* **Meals:** Group foods into meals (Breakfast, Lunch, etc.) or create custom reusable recipes.
* **Fluid Tracking:** dedicated logging for water, coffee, and sugary drinks.
* **Smart Analysis:** Automatically tracks caffeine intake based on logged beverages.
* **Macro Goals:** Set daily targets for Calories, Protein, Carbs, Fats, Fiber, Sugar, and Salt.

### 📈 Body Metrics & Health
* **Measurements:** Track weight, body fat percentage, and tape measurements (biceps, waist, etc.).
* **Charts:** Visualize your progress over time.
* **Supplements:** Manage your inventory and track daily intake of supplements like Creatine or Vitamins.

### 🛡️ Privacy & Tech
* **Offline-First:** All data stays on your device by default. No account required.
* **No Ads, No Bloat:** Just the tools you need.
* **Export:** Full JSON export and encrypted backup options.

---

## 🗺️ Roadmap: The Path to v1.0 & Beyond

We are building a platform that gives you the convenience of cloud-based apps with the freedom of open source.

### 🚧 Upcoming: v0.5 (The Architecture Update)
* **Database Rewrite:** Migration to **Drift** (SQLite ORM) and **UUIDs** to enable conflict-free synchronization.
* **HealthKit Integration:** Syncing workouts and weight with Apple Health.
* **Preparation:** Laying the groundwork for optional cloud features.

### ☁️ Planned: v1.0 (The Silent Launch)
* **Hybrid Cloud:** Optional, encrypted cloud backup running in the background.
* **Cross-Device:** Seamlessly switch between devices without manual exports.
* **Self-Hosting:** Official Docker support for users who want to host their own backend (BYOB - Bring Your Own Backend).

### 🤝 Vision: v2.0 (Social & Connectivity)
* **Social Feed:** Share workouts, PRs, and streaks with friends.
* **Profiles:** Public profiles to showcase your stats (opt-in).
* **Competition:** Leaderboards and group challenges.

---

## 🛠️ Tech Stack

* **Framework:** Flutter
* **Local Database:** SQLite (migrating to Drift)
* **State Management:** Provider
* **Backend (Future):** Supabase (PostgreSQL)

## ❤️ Contributing

Contributions, issues, and feature requests are welcome!
Since we are currently in a heavy refactoring phase (v0.5), please open an issue to discuss major changes before submitting a PR.

## 📄 License

[MIT](LICENSE)