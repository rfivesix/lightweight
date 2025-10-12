// lib/models/daily_nutrition.dart

class DailyNutrition {
  // Verbrauchte Nährwerte
  int calories;
  int water;
  int protein;
  int carbs;
  int fat;
  double fiber;
  double sugar;
  double salt;
  double caffeine;

  // Ziele
  int targetCalories;
  int targetWater;
  int targetProtein;
  int targetCarbs;
  int targetFat;

  // DOC: NEUE ZIELFELDER
  int targetSugar;
  int targetFiber;
  int targetSalt;
  int targetCaffeine;

  DailyNutrition({
    this.calories = 0,
    this.water = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.salt = 0.0,
    this.caffeine = 0.0,
    this.targetCalories = 0,
    this.targetWater = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,

    // DOC: Initialisierung der neuen Ziele
    this.targetSugar = 0,
    this.targetFiber = 0,
    this.targetSalt = 0,
    this.targetCaffeine = 0,
  });
}
