// lib/models/tracked_supplement.dart
import 'package:lightweight/models/supplement.dart';

class TrackedSupplement {
  final Supplement supplement;
  final double totalDosedToday;

  const TrackedSupplement({
    required this.supplement,
    required this.totalDosedToday,
  });
}
