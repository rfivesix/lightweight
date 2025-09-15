// lib/models/measurement_session.dart
import 'package:lightweight/models/measurement.dart';

class MeasurementSession {
  final int? id;
  final DateTime timestamp;
  final List<Measurement> measurements; // Hält die Detailwerte

  MeasurementSession({
    this.id,
    required this.timestamp,
    this.measurements = const [],
  });
}