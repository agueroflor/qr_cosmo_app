// lib/domain/entities/operational_day.dart
// Operational day logic for nocturnal bar schedules

import 'package:intl/intl.dart';

/// Result of computing the current operational day
class OperationalDayResult {
  /// Day of the week (DateTime.thursday, DateTime.friday, DateTime.saturday)
  final int weekday;

  /// Calendar date of the opening day (e.g. Friday January 31st)
  final DateTime calendarDate;

  final String key;

  OperationalDayResult({
    required this.weekday,
    required this.calendarDate,

  }) : key = DateFormat('yyyy-MM-dd').format(calendarDate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationalDayResult &&
          weekday == other.weekday &&
          calendarDate.year == other.calendarDate.year &&
          calendarDate.month == other.calendarDate.month &&
          calendarDate.day == other.calendarDate.day;

  @override
  int get hashCode => Object.hash(weekday, calendarDate.year, calendarDate.month, calendarDate.day);

  @override
  String toString() =>
      'OperationalDayResult(weekday: $weekday, calendarDate: ${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')})';
}

/// Closing hours per operational day
/// - Thursday: closes Friday 03:00
/// - Friday: closes Saturday 06:00
/// - Saturday: closes Sunday 06:00
const Map<int, int> _closingHours = {
  DateTime.thursday: 3, // Thursday closes Friday 03:00
  DateTime.friday: 6,   // Friday closes Saturday 06:00
  DateTime.saturday: 6, // Saturday closes Sunday 06:00
};

/// Bar operational days
const Set<int> _operationalWeekdays = {
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
};

/// Computes the operational day for a given moment.
///
/// Pure function: receives DateTime, does not use DateTime.now().
///
/// Logic:
/// - If the time is before the previous operational day's closing, it belongs to the previous day
/// - If it is an operational day (Thu/Fri/Sat), returns that day
/// - If it is not an operational day, returns null
OperationalDayResult? getOperationalDay(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // First: are we in the early morning of the previous operational day?
  final previousWeekday = today.weekday == 1 ? 7 : today.weekday - 1;

  if (_operationalWeekdays.contains(previousWeekday)) {
    final closingHour = _closingHours[previousWeekday]!;
    final closingDateTime = today.add(Duration(hours: closingHour));

    if (now.isBefore(closingDateTime)) {
      return OperationalDayResult(
        weekday: previousWeekday,
        calendarDate: yesterday,
      );
    }
  }

  // Second: is today an operational day?
  if (_operationalWeekdays.contains(today.weekday)) {
    return OperationalDayResult(
      weekday: today.weekday,
      calendarDate: today,
    );
  }

  return null;
}


/// Computes the operational day from a calendar date.
///
/// Given a date (e.g. Friday January 31st), returns the corresponding
/// OperationalDayResult. Useful for comparing with the operational day stored in an invitation.
OperationalDayResult? getOperationalDayFromDate(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  if (!_operationalWeekdays.contains(dateOnly.weekday)) return null;
  return OperationalDayResult(
    weekday: dateOnly.weekday,
    calendarDate: dateOnly,
  );
}
