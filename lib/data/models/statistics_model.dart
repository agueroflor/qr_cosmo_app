class StatisticsModel {
  final int totalGuests;
  final int totalVisits;
  final int activeGuests;
  final int todayVisits;
  final int thisWeekVisits;
  final int thisMonthVisits;
  final double averageVisitsPerGuest;
  final List<GuestFrequency> topFrequentGuests;
  final List<DailyVisits> dailyVisitsLastWeek;
  
  // Nuevas estadísticas específicas para días de operación (viernes y sábados)
  final WeekendStats weekendStats;
  final List<GuestFrequency> unusedQrGuests;
  final List<FailedAttempt> failedAttempts;
  final List<GuestFrequency> frequentWeekendGuests;

  StatisticsModel({
    required this.totalGuests,
    required this.totalVisits,
    required this.activeGuests,
    required this.todayVisits,
    required this.thisWeekVisits,
    required this.thisMonthVisits,
    required this.averageVisitsPerGuest,
    required this.topFrequentGuests,
    required this.dailyVisitsLastWeek,
    required this.weekendStats,
    required this.unusedQrGuests,
    required this.failedAttempts,
    required this.frequentWeekendGuests,
  });
}

class GuestFrequency {
  final String guestId;
  final String name;
  final String dni;
  final int visitCount;
  final DateTime lastVisit;

  GuestFrequency({
    required this.guestId,
    required this.name,
    required this.dni,
    required this.visitCount,
    required this.lastVisit,
  });
}

class DailyVisits {
  final DateTime date;
  final int visitCount;

  DailyVisits({
    required this.date,
    required this.visitCount,
  });
}

// Estadísticas específicas para fines de semana (viernes y sábados)
class WeekendStats {
  final int totalWeekendVisits;
  final int fridayVisits;
  final int saturdayVisits;
  final int uniqueWeekendGuests;
  final double averageWeekendVisits;
  final List<WeekendDayStats> lastWeekends;

  WeekendStats({
    required this.totalWeekendVisits,
    required this.fridayVisits,
    required this.saturdayVisits,
    required this.uniqueWeekendGuests,
    required this.averageWeekendVisits,
    required this.lastWeekends,
  });
}

class WeekendDayStats {
  final DateTime date;
  final int visitCount;
  final String dayName; // "Viernes" o "Sábado"

  WeekendDayStats({
    required this.date,
    required this.visitCount,
    required this.dayName,
  });
}

// Intentos fallidos de acceso
class FailedAttempt {
  final String qrCode;
  final String reason;
  final DateTime attemptedAt;
  final String? guestName; // Si se puede identificar al dueño del QR

  FailedAttempt({
    required this.qrCode,
    required this.reason,
    required this.attemptedAt,
    this.guestName,
  });
}