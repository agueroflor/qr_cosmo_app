import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:qr_cosmo_app/data/repositories/guest_repository_impl.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

void main() {
  late GuestRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  final testGuest = GuestModel(
    id: 'test-id',
    name: 'Test Guest',
    dni: '12345678',
    qrCode: 'COSMO_TEST_QR',
    createdBy: 'creator-id',
    createdByName: 'Creator Name',
    createdAt: DateTime.now(),
    isActive: true,
    totalVisits: 0,
    isInvitation: false,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = GuestRepositoryImpl(fakeFirestore);
  });

  group('GuestRepositoryImpl', () {
    group('create', () {
      test('debe crear un guest y retornar el ID', () async {
        final result = await repository.create(testGuest);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (id) => expect(id, isNotEmpty),
        );
      });
    });

    group('getByQrCode', () {
      test('debe retornar guest cuando existe', () async {
        // Crear el guest primero
        await fakeFirestore.collection('guests').add(testGuest.toMap());

        final result = await repository.getByQrCode('COSMO_TEST_QR');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (guest) {
            expect(guest, isNotNull);
            expect(guest!.qrCode, equals('COSMO_TEST_QR'));
            expect(guest.name, equals('Test Guest'));
          },
        );
      });

      test('debe retornar null cuando no existe', () async {
        final result = await repository.getByQrCode('NONEXISTENT_QR');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (guest) => expect(guest, isNull),
        );
      });
    });

    group('getById', () {
      test('debe retornar guest cuando existe', () async {
        final docRef = await fakeFirestore.collection('guests').add(testGuest.toMap());

        final result = await repository.getById(docRef.id);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (guest) {
            expect(guest, isNotNull);
            expect(guest!.name, equals('Test Guest'));
          },
        );
      });

      test('debe retornar null cuando no existe', () async {
        final result = await repository.getById('nonexistent-id');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (guest) => expect(guest, isNull),
        );
      });
    });

    group('update', () {
      test('debe actualizar un guest existente', () async {
        final docRef = await fakeFirestore.collection('guests').add(testGuest.toMap());

        final updatedGuest = testGuest.copyWith(
          id: docRef.id,
          name: 'Updated Name',
        );

        final result = await repository.update(updatedGuest);

        expect(result.isRight(), isTrue);

        // Verificar que se actualizó
        final doc = await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['name'], equals('Updated Name'));
      });
    });

    group('toggleStatus', () {
      test('debe cambiar el estado de activo a inactivo', () async {
        final docRef = await fakeFirestore.collection('guests').add(testGuest.toMap());

        final result = await repository.toggleStatus(docRef.id, false);

        expect(result.isRight(), isTrue);

        final doc = await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['isActive'], isFalse);
      });
    });

    group('markAsUsed', () {
      test('debe incrementar totalVisits', () async {
        final docRef = await fakeFirestore.collection('guests').add(testGuest.toMap());

        final result = await repository.markAsUsed(docRef.id, count: 2);

        expect(result.isRight(), isTrue);

        final doc = await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['totalVisits'], equals(2));
        expect(doc.data()!['lastUsedDate'], isNotNull);
      });
    });

    group('delete', () {
      test('debe eliminar guest cuando el usuario es el dueño', () async {
        final guestWithOwner = testGuest.copyWith(ownerId: 'creator-id');
        final docRef = await fakeFirestore.collection('guests').add(guestWithOwner.toMap());

        final result = await repository.delete(docRef.id, 'creator-id');

        expect(result.isRight(), isTrue);

        final doc = await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.exists, isFalse);
      });

      test('debe fallar cuando el usuario no es el dueño', () async {
        final guestWithOwner = testGuest.copyWith(ownerId: 'creator-id');
        final docRef = await fakeFirestore.collection('guests').add(guestWithOwner.toMap());

        final result = await repository.delete(docRef.id, 'other-user-id');

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
