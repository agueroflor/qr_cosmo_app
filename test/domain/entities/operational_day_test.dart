import 'package:flutter_test/flutter_test.dart';
import 'package:qr_cosmo_app/domain/entities/operational_day.dart';

void main() {
  group('getOperationalDay', () {
    // Jueves
    test('jueves 20:00 -> jueves', () {
      // Jueves 30 de enero 2025, 20:00
      final dt = DateTime(2025, 1, 30, 20, 0);
      expect(dt.weekday, DateTime.thursday);

      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.thursday);
      expect(result.calendarDate, DateTime(2025, 1, 30));
    });

    test('jueves 23:59 -> jueves', () {
      final dt = DateTime(2025, 1, 30, 23, 59);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.thursday);
      expect(result.calendarDate, DateTime(2025, 1, 30));
    });

    // Viernes madrugada (antes del cierre del jueves a las 03:00)
    test('viernes 02:00 -> jueves (antes cierre jue 03:00)', () {
      // Viernes 31 de enero 2025, 02:00
      final dt = DateTime(2025, 1, 31, 2, 0);
      expect(dt.weekday, DateTime.friday);

      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.thursday);
      expect(result.calendarDate, DateTime(2025, 1, 30)); // Jueves 30
    });

    test('viernes 02:59 -> jueves (antes cierre jue 03:00)', () {
      final dt = DateTime(2025, 1, 31, 2, 59);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.thursday);
    });

    // Viernes después del cierre del jueves
    test('viernes 03:00 -> viernes (jueves ya cerró)', () {
      final dt = DateTime(2025, 1, 31, 3, 0);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
      expect(result.calendarDate, DateTime(2025, 1, 31));
    });

    test('viernes 20:00 -> viernes', () {
      final dt = DateTime(2025, 1, 31, 20, 0);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
      expect(result.calendarDate, DateTime(2025, 1, 31));
    });

    // Sábado madrugada (antes del cierre del viernes a las 06:00)
    test('sábado 01:00 -> viernes', () {
      // Sábado 1 de febrero 2025, 01:00
      final dt = DateTime(2025, 2, 1, 1, 0);
      expect(dt.weekday, DateTime.saturday);

      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
      expect(result.calendarDate, DateTime(2025, 1, 31)); // Viernes 31
    });

    test('sábado 05:59 -> viernes (antes cierre vie 06:00)', () {
      final dt = DateTime(2025, 2, 1, 5, 59);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
    });

    // Sábado después del cierre del viernes
    test('sábado 06:00 -> sábado (viernes ya cerró)', () {
      final dt = DateTime(2025, 2, 1, 6, 0);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
      expect(result.calendarDate, DateTime(2025, 2, 1));
    });

    test('sábado 06:01 -> sábado', () {
      final dt = DateTime(2025, 2, 1, 6, 1);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
    });

    test('sábado 20:00 -> sábado', () {
      final dt = DateTime(2025, 2, 1, 20, 0);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
      expect(result.calendarDate, DateTime(2025, 2, 1));
    });

    // Domingo madrugada (antes del cierre del sábado a las 06:00)
    test('domingo 04:00 -> sábado', () {
      // Domingo 2 de febrero 2025, 04:00
      final dt = DateTime(2025, 2, 2, 4, 0);
      expect(dt.weekday, DateTime.sunday);

      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
      expect(result.calendarDate, DateTime(2025, 2, 1)); // Sábado 1
    });

    test('domingo 05:59 -> sábado (antes cierre sab 06:00)', () {
      final dt = DateTime(2025, 2, 2, 5, 59);
      final result = getOperationalDay(dt);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
    });

    // Domingo después del cierre -> no operativo
    test('domingo 06:01 -> null (no operativo)', () {
      final dt = DateTime(2025, 2, 2, 6, 1);
      final result = getOperationalDay(dt);
      expect(result, isNull);
    });

    test('domingo 14:00 -> null (no operativo)', () {
      final dt = DateTime(2025, 2, 2, 14, 0);
      final result = getOperationalDay(dt);
      expect(result, isNull);
    });

    // Días no operativos
    test('lunes 14:00 -> null', () {
      // Lunes 3 de febrero 2025
      final dt = DateTime(2025, 2, 3, 14, 0);
      expect(dt.weekday, DateTime.monday);
      final result = getOperationalDay(dt);
      expect(result, isNull);
    });

    test('martes 20:00 -> null', () {
      final dt = DateTime(2025, 2, 4, 20, 0);
      expect(dt.weekday, DateTime.tuesday);
      final result = getOperationalDay(dt);
      expect(result, isNull);
    });

    test('miércoles 22:00 -> null', () {
      final dt = DateTime(2025, 2, 5, 22, 0);
      expect(dt.weekday, DateTime.wednesday);
      final result = getOperationalDay(dt);
      expect(result, isNull);
    });
  });

  group('getOperationalDayFromDate', () {
    test('viernes -> retorna OperationalDayResult con weekday viernes', () {
      final date = DateTime(2025, 1, 31); // Viernes
      final result = getOperationalDayFromDate(date);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
      expect(result.calendarDate, DateTime(2025, 1, 31));
    });

    test('jueves -> retorna OperationalDayResult con weekday jueves', () {
      final date = DateTime(2025, 1, 30); // Jueves
      final result = getOperationalDayFromDate(date);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.thursday);
    });

    test('sábado -> retorna OperationalDayResult con weekday sábado', () {
      final date = DateTime(2025, 2, 1); // Sábado
      final result = getOperationalDayFromDate(date);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.saturday);
    });

    test('lunes -> null (no operativo)', () {
      final date = DateTime(2025, 2, 3); // Lunes
      final result = getOperationalDayFromDate(date);
      expect(result, isNull);
    });

    test('domingo -> null (no operativo)', () {
      final date = DateTime(2025, 2, 2); // Domingo
      final result = getOperationalDayFromDate(date);
      expect(result, isNull);
    });
  });

  group('OperationalDayResult equality', () {
    test('dos resultados con misma fecha y weekday son iguales', () {
      final a = OperationalDayResult(
        weekday: DateTime.friday,
        calendarDate: DateTime(2025, 1, 31),
      );
      final b = OperationalDayResult(
        weekday: DateTime.friday,
        calendarDate: DateTime(2025, 1, 31),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('dos resultados con diferente fecha no son iguales', () {
      final a = OperationalDayResult(
        weekday: DateTime.friday,
        calendarDate: DateTime(2025, 1, 31),
      );
      final b = OperationalDayResult(
        weekday: DateTime.friday,
        calendarDate: DateTime(2025, 2, 7),
      );
      expect(a, isNot(equals(b)));
    });
  });
}
