
// lib/services/night_id_service.dart

/// Servicio para calcular el nightId según las reglas operativas del boliche.
///
/// REGLAS DE HORARIOS:
/// - El bar opera viernes y sábados
/// - Viernes: abre 19:00, cierra 06:00 del sábado
/// - Sábado: abre 19:00, cierra 06:00 del domingo
///
/// REGLAS DE QR:
/// - Los QR solo se escanean a partir de las 00:00
/// - Madrugada del sábado (00:00-06:00) → noche del viernes
/// - Madrugada del domingo (00:00-06:00) → noche del sábado
///
/// DEFINICIÓN DE nightId:
/// - Para escaneos entre 00:00-06:00: nightId = día calendario anterior
/// - nightId SIEMPRE debe ser viernes (5) o sábado (6)
/// - NUNCA debe ser domingo
class NightIdService {
  /// Hora de corte: 06:00 AM
  /// Cualquier escaneo antes de esta hora pertenece a la noche anterior
  static const int cutoffHour = 6;

  /// Calcula el nightId para un timestamp dado.
  ///
  /// Retorna el nightId en formato "YYYY-MM-DD" representando la noche operativa.
  ///
  /// Ejemplos:
  /// - 2026-01-17 01:30 (sábado madrugada) → "2026-01-16" (viernes)
  /// - 2026-01-18 03:45 (domingo madrugada) → "2026-01-17" (sábado)
  /// - 2026-01-16 23:30 (viernes noche) → "2026-01-16" (viernes)
  /// - 2026-01-17 23:30 (sábado noche) → "2026-01-17" (sábado)
  static String calculateNightId(DateTime timestamp) {
    DateTime nightDate;

    // Si es entre 00:00 y 05:59, pertenece a la noche del día anterior
    if (timestamp.hour < cutoffHour) {
      nightDate = timestamp.subtract(const Duration(days: 1));
    } else {
      nightDate = timestamp;
    }

    // Formatear como YYYY-MM-DD
    return _formatDate(nightDate);
  }

  /// Calcula el nightId para el momento actual.
  static String getCurrentNightId() {
    return calculateNightId(DateTime.now());
  }

  /// Verifica si el nightId corresponde a un día válido de operación (viernes o sábado).
  ///
  /// Retorna true si el nightId es viernes (5) o sábado (6).
  static bool isValidOperatingNight(String nightId) {
    try {
      final date = _parseDate(nightId);
      // weekday: 5 = viernes, 6 = sábado
      return date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el nombre del día de la semana para un nightId.
  static String getNightDayName(String nightId) {
    try {
      final date = _parseDate(nightId);
      switch (date.weekday) {
        case DateTime.monday:
          return 'Lunes';
        case DateTime.tuesday:
          return 'Martes';
        case DateTime.wednesday:
          return 'Miércoles';
        case DateTime.thursday:
          return 'Jueves';
        case DateTime.friday:
          return 'Viernes';
        case DateTime.saturday:
          return 'Sábado';
        case DateTime.sunday:
          return 'Domingo';
        default:
          return 'Desconocido';
      }
    } catch (e) {
      return 'Desconocido';
    }
  }

  /// Formatea un DateTime a string "YYYY-MM-DD"
  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parsea un string "YYYY-MM-DD" a DateTime
  static DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) {
      throw FormatException('Formato de fecha inválido: $dateStr');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Verifica si un timestamp está dentro del horario operativo de QR (00:00 - 06:00).
  ///
  /// NOTA: Esta función es solo informativa. El sistema registra logs
  /// independientemente del horario, pero esta información puede ser útil
  /// para análisis.
  static bool isWithinQROperatingHours(DateTime timestamp) {
    return timestamp.hour >= 0 && timestamp.hour < cutoffHour;
  }

  /// Obtiene el rango de timestamps para una noche operativa específica.
  ///
  /// Para una noche (ej: viernes 2026-01-16):
  /// - Inicio: 2026-01-16 00:00:00 (inicio de la operación de QR)
  /// - Fin: 2026-01-17 06:00:00 (fin de la madrugada)
  ///
  /// Retorna un Map con 'start' y 'end' como DateTime.
  static Map<String, DateTime> getNightTimeRange(String nightId) {
    final nightDate = _parseDate(nightId);
    final nextDay = nightDate.add(const Duration(days: 1));

    return {
      'start': DateTime(nightDate.year, nightDate.month, nightDate.day, 0, 0, 0),
      'end': DateTime(nextDay.year, nextDay.month, nextDay.day, cutoffHour, 0, 0),
    };
  }
}
