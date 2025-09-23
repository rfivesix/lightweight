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

// Ersetze diese Methode in lib/services/profile_service.dart
  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);
    if (currentPath != null) {
      try {
        await File(currentPath).delete();
      } catch (e) {
        debugPrint('Fehler beim Löschen der Profildatei: $e');
      }
      await prefs.remove(_profileImageKey);
      _profileImagePath = null;
      
      // Erhöhe den Cache-Buster, um einen Rebuild zu erzwingen
      _cacheBuster++;
      notifyListeners();
    }
  }
}

extension UnitConverter on ProfileService {
  double toDisplayWeight(double kg) => useKg ? kg : kg * 2.20462;
  double toStorageWeight(double display) => useKg ? display : display / 2.20462;

  double toDisplayLength(double cm) => useCm ? cm : cm / 2.54;
  double toStorageLength(double display) => useCm ? display : display * 2.54;

  String weightLabel() => useKg ? 'kg' : 'lbs';
  String lengthLabel() => useCm ? 'cm' : 'in';
}