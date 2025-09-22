// lib/util/l10n_ext.dart
import 'package:flutter/widgets.dart';
import 'package:lightweight/generated/app_localizations.dart';

// Bestehende Extension für den BuildContext
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// NEU: Extension für die AppLocalizations-Klasse
extension AppLocalizationsX on AppLocalizations {
  String getLocalizedMeasurementName(String key) {
    switch (key) {
      case 'weight':
        return measurementWeight;
      case 'fat_percent':
        return measurementFatPercent;
      case 'neck':
        return measurementNeck;
      case 'shoulder':
        return measurementShoulder;
      case 'chest':
        return measurementChest;
      case 'left_bicep':
        return measurementLeftBicep;
      case 'right_bicep':
        return measurementRightBicep;
      case 'left_forearm':
        return measurementLeftForearm;
      case 'right_forearm':
        return measurementRightForearm;
      case 'abdomen':
        return measurementAbdomen;
      case 'waist':
        return measurementWaist;
      case 'hips':
        return measurementHips;
      case 'left_thigh':
        return measurementLeftThigh;
      case 'right_thigh':
        return measurementRightThigh;
      case 'left_calf':
        return measurementLeftCalf;
      case 'right_calf':
        return measurementRightCalf;
      default:
        return key;
    }
  }
}
