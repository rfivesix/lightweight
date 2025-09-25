// lib/services/profile_service.dart
// VEREINFACHTE UND KORRIGIERTE VERSION

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;
  int _cacheBuster = 0;

  bool _isPickerActive = false;
  static const String _profileImageKey = 'profileImagePath';

  bool _useKg = true;
  bool get useKg => _useKg;
  bool _useCm = true;
  bool get useCm => _useCm;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);
    // NEU: Lade die Einheiten-Präferenzen
    _useKg = prefs.getBool('useKg') ?? true;
    _useCm = prefs.getBool('useCm') ?? true;
    notifyListeners();
  }

  // NEU: Methoden zum Setzen und Speichern der Einheiten
  Future<void> setUseKg(bool value) async {
    _useKg = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useKg', value);
  }

  Future<void> setUseCm(bool value) async {
    _useCm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCm', value);
  }

// Ersetze diese Methode in lib/services/profile_service.dart
  Future<void> pickAndSaveProfileImage() async {
    if (_isPickerActive) return;
    _isPickerActive = true;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        const fileName = 'profile_image.jpg';
        final localPath = '${appDir.path}/$fileName';

        final newImage = await File(pickedFile.path).copy(localPath);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImageKey, newImage.path);
        _profileImagePath = newImage.path;

        // Erhöhe den Cache-Buster, um einen Rebuild zu erzwingen
        _cacheBuster++;
        notifyListeners();
      }
    } finally {
      _isPickerActive = false;
    }
  }

// REVISED METHOD
  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);

    if (currentPath != null) {
      // 1. Immediately remove the reference from persistent storage.
      await prefs.remove(_profileImageKey);

      // 2. Immediately update the internal state and notify the UI.
      _profileImagePath = null;
      notifyListeners();

      // 3. Try to delete the actual file from disk in the background.
      try {
        final imageFile = File(currentPath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        // Log the error, but the app's state is already corrected.
        debugPrint('Failed to delete profile image file: $e');
      }
    }
  }
}

// NEU: Extension für die Konvertierungslogik
extension UnitConverter on ProfileService {
  // Konvertiert einen in KG gespeicherten Wert in die Anzeige-Einheit
  double toDisplayWeight(double kg) => useKg ? kg : kg * 2.20462;
  // Konvertiert einen in der Anzeige-Einheit eingegebenen Wert zurück in KG zur Speicherung
  double toStorageWeight(double displayValue) =>
      useKg ? displayValue : displayValue / 2.20462;

  // Konvertiert einen in CM gespeicherten Wert in die Anzeige-Einheit
  double toDisplayLength(double cm) => useCm ? cm : cm / 2.54;
  // Konvertiert einen in der Anzeige-Einheit eingegebenen Wert zurück in CM zur Speicherung
  double toStorageLength(double displayValue) =>
      useCm ? displayValue : displayValue * 2.54;

  // Gibt das korrekte Label für die Einheit zurück
  String weightUnitLabel() => useKg ? 'kg' : 'lbs';
  String lengthUnitLabel() => useCm ? 'cm' : 'in';
}
