import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing the application's theme and visual style.
///
/// Persists the user's preference for light/dark mode and visual presets.
class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _styleKey = 'visual_style'; // NEU
  ThemeMode _themeMode = ThemeMode.system;
  int _visualStyle = 0; // NEU: 0 = Standard, 1 = Liquid

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// The current visual style index.
  int get visualStyle => _visualStyle; // NEU

  /// Creates a [ThemeService] and loads saved preferences.
  ThemeService() {
    _loadThemeMode();
    _loadVisualStyle(); // NEU
  }
  // Im Konstruktor aufrufen:
  //_loadVisualStyle();

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // --- NEUE METHODE ---
  Future<void> _loadVisualStyle() async {
    final prefs = await SharedPreferences.getInstance();
    _visualStyle = prefs.getInt(_styleKey) ?? 0;
    notifyListeners();
  }

  /// Sets the visual style and persists it to storage.
  Future<void> setVisualStyle(int style) async {
    if (style == _visualStyle) return;
    _visualStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, style);
  }

  /// Sets the theme mode and persists it to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}
