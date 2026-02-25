import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:qr_cosmo_app/data/repositories/visit_repository_impl.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';

void main() {
  late VisitRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  final testVisit = VisitModel(
    id: 'test-visit-id',
    guestId: 'guest-id',
    guestName: 'Test Guest',
    dni: '12345678',
    scannedBy: 'scanner-id',
    scannedByName: 'Scanner Name',
    scannedAt: DateTime.now(),
    isFirstTime: true,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = VisitRepositoryImpl(fakeFirestore);
  });

  group('VisitRepositoryImpl', () {
    group('create', () {
      test('debe crear una visita y retornar el ID', () async {
        final result = await repository.create(testVisit);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (id) => expect(id, isNotEmpty),
        );
      });
    });

    group('createBatch', () {
      test('debe crear múltiples visitas', () async {
        final visits = [
          testVisit.copyWith(id: 'visit-1'),
          testVisit.copyWith(id: 'visit-2'),
          testVisit.copyWith(id: 'visit-3'),
        ];

        final result = await repository.createBatch(visits);

        expect(result.isRight(), isTrue);

        // Verificar que se crearon
        final snapshot = await fakeFirestore.collection('visits').get();
        expect(snapshot.docs.length, equals(3));
      });

      test('debe retornar éxito con lista vacía', () async {
        final result = await repository.createBatch([]);

        expect(result.isRight(), isTrue);
      });
    });

    group('getLastVisits', () {
      test('debe retornar visitas de un guest', () async {
        // Crear visitas
        await fakeFirestore.collection('visits').add(testVisit.toMap());
        await fakeFirestore.collection('visits').add(
              testVisit.copyWith(guestId: 'other-guest').toMap(),
            );

        final result = await repository.getLastVisits('guest-id');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (visits) {
            expect(visits.length, equals(1));
            expect(visits.first.guestId, equals('guest-id'));
          },
        );
      });

      test('debe respetar el límite', () async {
        // Crear 5 visitas
        for (int i = 0; i < 5; i++) {
          await fakeFirestore.collection('visits').add(
                testVisit.copyWith(id: 'visit-$i').toMap(),
              );
        }

        final result = await repository.getLastVisits('guest-id', limit: 3);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (visits) => expect(visits.length, lessThanOrEqualTo(3)),
        );
      });
    });

    group('getTodayVisits', () {
      test('debe retornar solo visitas de hoy', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        // Visita de hoy
        await fakeFirestore.collection('visits').add(testVisit.toMap());

        // Visita de ayer
        await fakeFirestore.collection('visits').add(
              testVisit.copyWith(scannedAt: yesterday).toMap(),
            );

        final result = await repository.getTodayVisits();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (visits) => expect(visits.length, equals(1)),
        );
      });
    });

    group('getVisitsByHour', () {
      test('debe retornar mapa con conteo por hora', () async {
        final today = DateTime.now();

        // Crear visitas a diferentes horas
        await fakeFirestore.collection('visits').add(
              testVisit
                  .copyWith(
                    scannedAt:
                        DateTime(today.year, today.month, today.day, 10, 0),
                  )
                  .toMap(),
            );
        await fakeFirestore.collection('visits').add(
              testVisit
                  .copyWith(
                    scannedAt:
                        DateTime(today.year, today.month, today.day, 10, 30),
                  )
                  .toMap(),
            );
        await fakeFirestore.collection('visits').add(
              testVisit
                  .copyWith(
                    scannedAt:
                        DateTime(today.year, today.month, today.day, 22, 0),
                  )
                  .toMap(),
            );

        final result = await repository.getVisitsByHour(today);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (hourlyVisits) {
            expect(hourlyVisits[10], equals(2));
            expect(hourlyVisits[22], equals(1));
            expect(hourlyVisits[0], equals(0)); // Sin visitas a medianoche
          },
        );
      });
    });
  });
}
