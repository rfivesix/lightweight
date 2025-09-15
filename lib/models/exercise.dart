// lib/models/exercise.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';

class Exercise {
  final int? id;
  final String nameDe;
  final String nameEn;
  final String descriptionDe;
  final String descriptionEn;
  final String categoryName;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  Exercise({
    this.id,
    required this.nameDe,
    required this.nameEn,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.categoryName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
  });

  String getLocalizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'de' ? nameDe : nameEn;
  }

  String getLocalizedDescription(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final desc = locale.languageCode == 'de' ? descriptionDe : descriptionEn;
    // Fallback, falls eine Beschreibung leer ist
    if (desc.trim().isEmpty) {
      return AppLocalizations.of(context)!.noDescriptionAvailable;
    }
    return desc;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_de': nameDe,
      'name_en': nameEn,
      'description_de': descriptionDe,
      'description_en': descriptionEn,
      'category_name': categoryName,
      'primaryMuscles': jsonEncode(primaryMuscles),
      'secondaryMuscles': jsonEncode(secondaryMuscles),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    // Diese Hilfsfunktion wandelt den JSON-String aus der DB in eine List<String> um
    List<String> parseMuscles(String? jsonString) {
      if (jsonString == null || jsonString.isEmpty) return [];
      try {
        // jsonDecode kann eine List<dynamic> zurückgeben, daher der cast.
        return (jsonDecode(jsonString) as List).map((item) => item.toString()).toList();
      } catch (e) {
        return []; // Im Fehlerfall leere Liste zurückgeben
      }
    }

    return Exercise(
      id: map['id'],
      nameDe: map['name_de'] ?? '',
      nameEn: map['name_en'] ?? '',
      descriptionDe: map['description_de'] ?? '',
      descriptionEn: map['description_en'] ?? '',
      categoryName: map['category_name'] ?? '',
      // KORREKTUR: Schlüsselnamen auf camelCase ('primaryMuscles') geändert
      primaryMuscles: parseMuscles(map['primaryMuscles']),
      secondaryMuscles: parseMuscles(map['secondaryMuscles']),
    );
  }
  
  Exercise copyWith({ int? id }) {
      return Exercise(
        id: id ?? this.id,
        nameDe: nameDe,
        nameEn: nameEn,
        descriptionDe: descriptionDe,
        descriptionEn: descriptionEn,
        categoryName: categoryName,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
      );
    }
}