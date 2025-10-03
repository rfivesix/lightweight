// lib/services/ui_state_service.dart

class UiStateService {
  // Statische Instanz, die beim ersten Zugriff erstellt wird (Singleton-Pattern)
  static final UiStateService instance = UiStateService._internal();

  // Privater Konstruktor
  UiStateService._internal();

  // Der Zustand, den wir speichern wollen
  bool isNutritionSummaryExpanded = true; // Standardmäßig AN, wie gewünscht
}
