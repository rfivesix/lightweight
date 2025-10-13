// lib/screens/measurement_session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/measurement_session.dart';
import 'package:lightweight/util/design_constants.dart';

class MeasurementSessionDetailScreen extends StatelessWidget {
  final MeasurementSession session;

  const MeasurementSessionDetailScreen({super.key, required this.session});

  // Wir kopieren die Helfer-Methode hierher, um die Namen zu übersetzen.
  String _getLocalizedMeasurementName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'weight':
        return l10n.measurementWeight;
      case 'fat_percent':
        return l10n.measurementFatPercent;
      case 'neck':
        return l10n.measurementNeck;
      // ... (füge hier alle anderen 'case' Anweisungen aus dem measurements_screen.dart ein)
      case 'right_calf':
        return l10n.measurementRightCalf;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // zeigt den Zurück-Pfeil
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          DateFormat.yMMMMd('de_DE').format(session.timestamp),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          ...session.measurements.map((measurement) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  _getLocalizedMeasurementName(measurement.type, l10n),
                ),
                trailing: Text(
                  "${measurement.value.toStringAsFixed(1)} ${measurement.unit}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
