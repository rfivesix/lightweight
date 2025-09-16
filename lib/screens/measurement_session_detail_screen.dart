// lib/screens/measurement_session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/measurement_session.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        // Zeigt das Datum der Sitzung als Titel an
        title: Text(DateFormat.yMMMMd('de_DE').format(session.timestamp)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: session.measurements.length,
        itemBuilder: (context, index) {
          final measurement = session.measurements[index];
          return Card(
            elevation: 2,
            child: ListTile(
              title: Text(_getLocalizedMeasurementName(measurement.type, l10n)),
              trailing: Text(
                "${measurement.value.toStringAsFixed(1)} ${measurement.unit}",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
