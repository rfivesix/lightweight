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
  int cacheBuster = 0;

  bool _isPickerActive = false;
  static const String _profileImageKey = 'profileImagePath';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);
    notifyListeners();
  }

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
        cacheBuster++;
        notifyListeners();
      }
    } finally {
      _isPickerActive = false;
    }
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);

    if (currentPath != null) {
      // 1. Immediately remove the reference from persistent storage.
      await prefs.remove(_profileImageKey);

      // 2. Immediately update the internal state and notify the UI.
      _profileImagePath = null;
      cacheBuster++;
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
