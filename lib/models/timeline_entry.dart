// lib/models/timeline_entry.dart

import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/models/water_entry.dart';

// DOC: Dies ist eine "abstrakte" Klasse. Sie dient als gemeinsame
// Schablone für alle Arten von Einträgen in unserem Tagebuch.
// Jedes Timeline-Item MUSS einen Zeitstempel haben, damit wir es sortieren können.
abstract class TimelineEntry {
  DateTime get timestamp;
}

// Ein Eintrag für ein Lebensmittel
class FoodTimelineEntry extends TimelineEntry {
  final TrackedFoodItem trackedItem;
  FoodTimelineEntry(this.trackedItem);

  @override
  DateTime get timestamp => trackedItem.entry.timestamp;
}

// Ein Eintrag für Wasser
class WaterTimelineEntry extends TimelineEntry {
  final WaterEntry waterEntry;
  WaterTimelineEntry(this.waterEntry);

  @override
  DateTime get timestamp => waterEntry.timestamp;
}
