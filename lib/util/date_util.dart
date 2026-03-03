// lib/util/date_util.dart

/// Extension providing date-only comparison for [DateTime] objects.
extension DateOnlyCompare on DateTime {
  /// Returns true if this [DateTime] falls on the same calendar day as [other].
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
