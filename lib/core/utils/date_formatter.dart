class DateFormatter {
  DateFormatter._();

  /// Formatea una fecha en formato DD/MM/YYYY
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  /// Formatea una fecha y hora en formato DD/MM/YYYY HH:MM
  static String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Formatea solo la hora en formato HH:MM
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Verifica si dos fechas son el mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Calcula la diferencia en minutos entre dos fechas
  static int minutesDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inMinutes.abs();
  }
}

/// Formatea una fecha en formato DD/MM/YYYY
String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

/// Formatea una fecha y hora en formato DD/MM/YYYY HH:MM
String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
