// lib/services/profile_service.dart (Korrigiert)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  // KORREKTUR: Konstruktor ist jetzt leer und synchron.
  ProfileService._internal();

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;

  static const String _profileImageKey = 'profileImagePath';

  // HINZUGEFÜGT: Eine explizite Initialisierungsmethode
  Future<void> initialize() async {
    await _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);
    notifyListeners();
  }

  Future<void> pickAndSaveProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      const String fileName = 'profile_image.jpg';
      final String localPath = '${appDir.path}/$fileName';

      final File newImage = await File(pickedFile.path).copy(localPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, newImage.path);

      _profileImagePath = newImage.path;
      notifyListeners();
    }
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentPath = prefs.getString(_profileImageKey);

    if (currentPath != null) {
      try {
        await File(currentPath).delete();
      } catch (e) {
        debugPrint("Fehler beim Löschen des Profilbildes: $e");
      }
      await prefs.remove(_profileImageKey);
      _profileImagePath = null;
      notifyListeners();
    }
  }
}
