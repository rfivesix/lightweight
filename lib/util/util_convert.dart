// lib/util/unit_convert.dart
double convert(double value, String from, String to) {
  if (from == to) return value;
  if (from == 'g' && to == 'mg') return value * 1000.0;
  if (from == 'mg' && to == 'g') return value / 1000.0;
  if (from == 'l' && to == 'ml') return value * 1000.0;
  if (from == 'ml' && to == 'l') return value / 1000.0;
  // sonst keine Konvertierung
  return value;
}

// Empfehlungs-Liste zulässiger Einheiten:
const allowedUnits = <String>['mg', 'g', 'IU', 'ml', 'l'];
