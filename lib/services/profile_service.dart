// lib/services/profile_service.dart

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

  static const String _profileImageKey = 'profileImagePath';

  // Units
  bool _useKg = true;
  bool get useKg => _useKg;
  bool _useCm = true;
  bool get useCm => _useCm;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);
    _useKg = prefs.getBool('useKg') ?? true;
    _useCm = prefs.getBool('useCm') ?? true;
    notifyListeners();
  }

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

  Future<void> pickAndSaveProfileImage() async {
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
      notifyListeners();
    }
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);
    if (currentPath != null) {
      try {
        await File(currentPath).delete();
      } catch (e) {
        debugPrint('Fehler beim Löschen des Profilbildes: $e');
      }
      await prefs.remove(_profileImageKey);
      _profileImagePath = null;
      notifyListeners();
    }
  }
} // <-- Klasse hier schließen

// Extension außerhalb der Klasse deklarieren
extension UnitConverter on ProfileService {
  double toDisplayWeight(double kg) => useKg ? kg : kg * 2.20462;
  double toStorageWeight(double display) => useKg ? display : display / 2.20462;

  double toDisplayLength(double cm) => useCm ? cm : cm / 2.54;
  double toStorageLength(double display) => useCm ? display : display * 2.54;

  String weightLabel() => useKg ? 'kg' : 'lbs';
  String lengthLabel() => useCm ? 'cm' : 'in';
}
