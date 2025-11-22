// lib/services/profile_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
// Wichtig für ImageCache
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;

  // CacheBuster hilft dem Widget, aber wir brauchen auch evict() für den ImageProvider
  int cacheBuster = 0;

  bool _isPickerActive = false;
  static const String _profileImageKey = 'profileImagePath';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);

    // Validierung: Existiert die Datei wirklich noch?
    if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (!await file.exists()) {
        _profileImagePath = null;
        await prefs.remove(_profileImageKey);
      }
    }
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
        final targetFile = File(localPath);

        // 1. WICHTIG: Das alte Bild aus dem Flutter-Cache werfen,
        // bevor wir das neue schreiben.
        try {
          await FileImage(targetFile).evict();
        } catch (e) {
          // Ignorieren, falls es nicht im Cache war
        }

        // 2. Datei kopieren/überschreiben
        await File(pickedFile.path).copy(localPath);

        // 3. Pfad speichern
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImageKey, localPath);

        _profileImagePath = localPath;
        cacheBuster++; // Zwingt das Widget zum Neu-Zeichnen
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fehler beim Bild-Upload: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);

    if (currentPath != null) {
      // 1. Aus Cache entfernen (WICHTIG!)
      try {
        await FileImage(File(currentPath)).evict();
      } catch (e) {
        // Egal, wenn es nicht im Cache war
      }

      // 2. UI sofort aktualisieren (Optimistic UI update)
      _profileImagePath = null;
      await prefs.remove(_profileImageKey);
      cacheBuster++;
      notifyListeners();

      // 3. Datei physisch löschen
      try {
        final imageFile = File(currentPath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        debugPrint('Fehler beim Löschen der Datei: $e');
      }
    }
  }
}
