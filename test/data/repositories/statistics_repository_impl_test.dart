import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:qr_cosmo_app/data/repositories/statistics_repository_impl.dart';

void main() {
  late StatisticsRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = StatisticsRepositoryImpl(fakeFirestore);
  });

  group('StatisticsRepositoryImpl', () {
    group('getStatistics', () {
      test('debe retornar estadísticas con valores correctos', () async {
        // Crear algunos guests
        await fakeFirestore.collection('guests').add({
          'name': 'Guest 1',
          'dni': '11111111',
          'totalVisits': 5,
          'isActive': true,
          'lastVisit': Timestamp.fromDate(DateTime.now()),
        });
        await fakeFirestore.collection('guests').add({
          'name': 'Guest 2',
          'dni': '22222222',
          'totalVisits': 0,
          'isActive': true,
        });

        // Crear algunas visitas
        final today = DateTime.now();
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-1',
          'guestName': 'Guest 1',
          'scannedAt': Timestamp.fromDate(today),
        });

        final result = await repository.getStatistics();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (stats) {
            expect(stats.totalGuests, equals(2));
            expect(stats.totalVisits, equals(1));
            expect(stats.activeGuests, equals(1)); // Solo el que tiene visitas > 0
            expect(stats.todayVisits, equals(1));
          },
        );
      });

      test('debe retornar estadísticas vacías cuando no hay datos', () async {
        final result = await repository.getStatistics();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (stats) {
            expect(stats.totalGuests, equals(0));
            expect(stats.totalVisits, equals(0));
            expect(stats.activeGuests, equals(0));
            expect(stats.todayVisits, equals(0));
            expect(stats.averageVisitsPerGuest, equals(0.0));
          },
        );
      });
    });

    group('getVisitsByHour', () {
      test('debe retornar mapa con conteo por hora', () async {
        final today = DateTime.now();

        // Crear visitas a diferentes horas
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-1',
          'scannedAt': Timestamp.fromDate(
            DateTime(today.year, today.month, today.day, 10, 0),
          ),
        });
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-2',
          'scannedAt': Timestamp.fromDate(
            DateTime(today.year, today.month, today.day, 10, 30),
          ),
        });
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-3',
          'scannedAt': Timestamp.fromDate(
            DateTime(today.year, today.month, today.day, 22, 0),
          ),
        });

        final result = await repository.getVisitsByHour(today);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (hourlyVisits) {
            expect(hourlyVisits[10], equals(2));
            expect(hourlyVisits[22], equals(1));
            expect(hourlyVisits[0], equals(0)); // Sin visitas a medianoche
            expect(hourlyVisits.length, equals(24)); // Todas las horas
          },
        );
      });

      test('debe retornar mapa vacío para día sin visitas', () async {
        final futureDate = DateTime.now().add(const Duration(days: 30));

        final result = await repository.getVisitsByHour(futureDate);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (hourlyVisits) {
            expect(hourlyVisits.values.every((count) => count == 0), isTrue);
          },
        );
      });
    });

    group('getTopGuests', () {
      test('debe retornar top guests ordenados por visitas', () async {
        // Crear guests con diferentes cantidades de visitas
        await fakeFirestore.collection('guests').add({
          'name': 'Guest Low',
          'dni': '11111111',
          'totalVisits': 2,
          'lastVisit': Timestamp.fromDate(DateTime.now()),
        });
        await fakeFirestore.collection('guests').add({
          'name': 'Guest High',
          'dni': '22222222',
          'totalVisits': 10,
          'lastVisit': Timestamp.fromDate(DateTime.now()),
        });
        await fakeFirestore.collection('guests').add({
          'name': 'Guest Medium',
          'dni': '33333333',
          'totalVisits': 5,
          'lastVisit': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.getTopGuests(limit: 3);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (topGuests) {
            expect(topGuests.length, equals(3));
            expect(topGuests[0].name, equals('Guest High'));
            expect(topGuests[0].visitCount, equals(10));
            expect(topGuests[1].name, equals('Guest Medium'));
            expect(topGuests[2].name, equals('Guest Low'));
          },
        );
      });

      test('debe respetar el límite', () async {
        // Crear 5 guests
        for (int i = 0; i < 5; i++) {
          await fakeFirestore.collection('guests').add({
            'name': 'Guest $i',
            'dni': '${i}1111111',
            'totalVisits': i + 1,
            'lastVisit': Timestamp.fromDate(DateTime.now()),
          });
        }

        final result = await repository.getTopGuests(limit: 3);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (topGuests) => expect(topGuests.length, lessThanOrEqualTo(3)),
        );
      });

      test('debe excluir guests sin visitas', () async {
        await fakeFirestore.collection('guests').add({
          'name': 'Guest With Visits',
          'dni': '11111111',
          'totalVisits': 5,
          'lastVisit': Timestamp.fromDate(DateTime.now()),
        });
        await fakeFirestore.collection('guests').add({
          'name': 'Guest Without Visits',
          'dni': '22222222',
          'totalVisits': 0,
        });

        final result = await repository.getTopGuests();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (topGuests) {
            expect(topGuests.length, equals(1));
            expect(topGuests.first.name, equals('Guest With Visits'));
          },
        );
      });
    });

    group('getDailyVisitsLastWeek', () {
      test('debe retornar visitas de los últimos 7 días', () async {
        final today = DateTime.now();

        // Crear visitas para hoy y ayer
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-1',
          'scannedAt': Timestamp.fromDate(today),
        });
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-2',
          'scannedAt': Timestamp.fromDate(
            today.subtract(const Duration(days: 1)),
          ),
        });
        await fakeFirestore.collection('visits').add({
          'guestId': 'guest-3',
          'scannedAt': Timestamp.fromDate(
            today.subtract(const Duration(days: 1)),
          ),
        });

        final result = await repository.getDailyVisitsLastWeek();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (dailyVisits) {
            expect(dailyVisits.length, equals(7));
            // El último día (hoy) debería tener 1 visita
            expect(dailyVisits.last.visitCount, equals(1));
            // Ayer debería tener 2 visitas
            expect(dailyVisits[dailyVisits.length - 2].visitCount, equals(2));
          },
        );
      });
    });

    group('getWeekendStats', () {
      test('debe retornar estadísticas de fines de semana', () async {
        // Encontrar el próximo viernes o sábado dentro de los últimos 30 días
        final today = DateTime.now();
        DateTime? friday;
        DateTime? saturday;

        for (int i = 0; i < 30; i++) {
          final checkDate = today.subtract(Duration(days: i));
          if (checkDate.weekday == 5 && friday == null) {
            friday = checkDate;
          }
          if (checkDate.weekday == 6 && saturday == null) {
            saturday = checkDate;
          }
          if (friday != null && saturday != null) break;
        }

        // Crear visitas de viernes
        if (friday != null) {
          await fakeFirestore.collection('visits').add({
            'guestId': 'guest-1',
            'scannedAt': Timestamp.fromDate(friday),
          });
          await fakeFirestore.collection('visits').add({
            'guestId': 'guest-2',
            'scannedAt': Timestamp.fromDate(friday),
          });
        }

        // Crear visitas de sábado
        if (saturday != null) {
          await fakeFirestore.collection('visits').add({
            'guestId': 'guest-1',
            'scannedAt': Timestamp.fromDate(saturday),
          });
        }

        final result = await repository.getWeekendStats();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (stats) {
            expect(stats.totalWeekendVisits, greaterThanOrEqualTo(0));
            // Friday visits + Saturday visits should match total
            expect(
              stats.fridayVisits + stats.saturdayVisits,
              equals(stats.totalWeekendVisits),
            );
          },
        );
      });
    });

    group('getUnusedQrGuests', () {
      test('debe retornar guests con QR no utilizado', () async {
        // Guest activo sin visitas
        await fakeFirestore.collection('guests').add({
          'name': 'Unused Guest',
          'dni': '11111111',
          'totalVisits': 0,
          'isActive': true,
        });

        // Guest activo con visitas
        await fakeFirestore.collection('guests').add({
          'name': 'Used Guest',
          'dni': '22222222',
          'totalVisits': 5,
          'isActive': true,
        });

        // Guest inactivo sin visitas (no debería incluirse)
        await fakeFirestore.collection('guests').add({
          'name': 'Inactive Guest',
          'dni': '33333333',
          'totalVisits': 0,
          'isActive': false,
        });

        final result = await repository.getUnusedQrGuests();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (unusedGuests) {
            expect(unusedGuests.length, equals(1));
            expect(unusedGuests.first.name, equals('Unused Guest'));
            expect(unusedGuests.first.visitCount, equals(0));
          },
        );
      });
    });

    group('getFrequentWeekendGuests', () {
      test('debe retornar guests frecuentes en fines de semana', () async {
        // Encontrar un viernes o sábado reciente
        final today = DateTime.now();
        DateTime? weekendDay;

        for (int i = 0; i < 30; i++) {
          final checkDate = today.subtract(Duration(days: i));
          if (checkDate.weekday == 5 || checkDate.weekday == 6) {
            weekendDay = checkDate;
            break;
          }
        }

        if (weekendDay != null) {
          // Crear múltiples visitas del mismo guest en fin de semana
          for (int i = 0; i < 3; i++) {
            await fakeFirestore.collection('visits').add({
              'guestId': 'frequent-guest',
              'guestName': 'Frequent Guest',
              'dni': '11111111',
              'scannedAt': Timestamp.fromDate(weekendDay),
            });
          }

          // Crear una visita de otro guest
          await fakeFirestore.collection('visits').add({
            'guestId': 'other-guest',
            'guestName': 'Other Guest',
            'dni': '22222222',
            'scannedAt': Timestamp.fromDate(weekendDay),
          });

          final result = await repository.getFrequentWeekendGuests(limit: 10);

          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('No debería fallar'),
            (frequentGuests) {
              expect(frequentGuests.isNotEmpty, isTrue);
              // El guest más frecuente debería ser el primero
              expect(frequentGuests.first.guestId, equals('frequent-guest'));
              expect(frequentGuests.first.visitCount, equals(3));
            },
          );
        }
      });
    });
  });
}
