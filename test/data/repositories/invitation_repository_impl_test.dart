import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:qr_cosmo_app/data/repositories/invitation_repository_impl.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

void main() {
  late InvitationRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  final testInvitation = GuestModel(
    id: 'test-invitation-id',
    name: 'Test Invitation',
    dni: '12345678',
    qrCode: 'COSMO_INVITE_QR',
    createdBy: 'creator-id',
    createdByName: 'Creator Name',
    createdAt: DateTime.now(),
    isActive: true,
    totalVisits: 0,
    isInvitation: true,
    maxUses: 5,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = InvitationRepositoryImpl(fakeFirestore);
  });

  group('InvitationRepositoryImpl', () {
    group('create', () {
      test('debe crear una invitación y retornar el ID', () async {
        final result = await repository.create(testInvitation);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (id) => expect(id, isNotEmpty),
        );
      });

      test('debe asegurar que isInvitation sea true', () async {
        final result = await repository.create(testInvitation);

        result.fold(
          (failure) => fail('No debería fallar'),
          (id) async {
            final doc =
                await fakeFirestore.collection('guests').doc(id).get();
            expect(doc.data()!['isInvitation'], isTrue);
          },
        );
      });
    });

    group('getAll', () {
      test('debe retornar solo invitaciones', () async {
        // Crear una invitación
        await fakeFirestore.collection('guests').add(testInvitation.toMap());

        // Crear un guest regular (no invitación)
        final regularGuest = testInvitation.copyWith(
          isInvitation: false,
          qrCode: 'REGULAR_QR',
        );
        await fakeFirestore.collection('guests').add(regularGuest.toMap());

        final result = await repository.getAll();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (invitations) {
            expect(invitations.length, equals(1));
            expect(invitations.first.isInvitation, isTrue);
          },
        );
      });
    });

    group('getByUser', () {
      test('debe retornar invitaciones de un usuario específico', () async {
        // Crear invitación del usuario
        await fakeFirestore.collection('guests').add(testInvitation.toMap());

        // Crear invitación de otro usuario
        final otherUserInvitation = testInvitation.copyWith(
          createdBy: 'other-user-id',
          qrCode: 'OTHER_QR',
        );
        await fakeFirestore.collection('guests').add(otherUserInvitation.toMap());

        final result = await repository.getByUser('creator-id');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (invitations) {
            expect(invitations.length, equals(1));
            expect(invitations.first.createdBy, equals('creator-id'));
          },
        );
      });
    });

    group('getActiveByUser', () {
      test('debe retornar solo invitaciones activas del usuario', () async {
        // Crear invitación activa
        await fakeFirestore.collection('guests').add(testInvitation.toMap());

        // Crear invitación inactiva
        final inactiveInvitation = testInvitation.copyWith(
          isActive: false,
          qrCode: 'INACTIVE_QR',
        );
        await fakeFirestore.collection('guests').add(inactiveInvitation.toMap());

        final result = await repository.getActiveByUser('creator-id');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (invitations) {
            expect(invitations.length, equals(1));
            expect(invitations.first.isActive, isTrue);
          },
        );
      });
    });

    group('update', () {
      test('debe actualizar una invitación existente', () async {
        final docRef =
            await fakeFirestore.collection('guests').add(testInvitation.toMap());

        final updatedInvitation = testInvitation.copyWith(
          id: docRef.id,
          name: 'Updated Invitation Name',
          maxUses: 10,
        );

        final result = await repository.update(updatedInvitation);

        expect(result.isRight(), isTrue);

        // Verificar que se actualizó
        final doc =
            await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['name'], equals('Updated Invitation Name'));
        expect(doc.data()!['maxUses'], equals(10));
      });
    });

    group('toggleStatus', () {
      test('debe cambiar el estado de activo a inactivo', () async {
        final docRef =
            await fakeFirestore.collection('guests').add(testInvitation.toMap());

        final result = await repository.toggleStatus(docRef.id, false);

        expect(result.isRight(), isTrue);

        final doc =
            await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['isActive'], isFalse);
      });

      test('debe cambiar el estado de inactivo a activo', () async {
        final inactiveInvitation = testInvitation.copyWith(isActive: false);
        final docRef = await fakeFirestore
            .collection('guests')
            .add(inactiveInvitation.toMap());

        final result = await repository.toggleStatus(docRef.id, true);

        expect(result.isRight(), isTrue);

        final doc =
            await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.data()!['isActive'], isTrue);
      });
    });

    group('delete', () {
      test('debe eliminar invitación cuando el usuario es el dueño', () async {
        final invitationWithOwner =
            testInvitation.copyWith(ownerId: 'creator-id');
        final docRef = await fakeFirestore
            .collection('guests')
            .add(invitationWithOwner.toMap());

        final result = await repository.delete(docRef.id, 'creator-id');

        expect(result.isRight(), isTrue);

        final doc =
            await fakeFirestore.collection('guests').doc(docRef.id).get();
        expect(doc.exists, isFalse);
      });

      test('debe fallar cuando el usuario no es el dueño', () async {
        final invitationWithOwner =
            testInvitation.copyWith(ownerId: 'creator-id');
        final docRef = await fakeFirestore
            .collection('guests')
            .add(invitationWithOwner.toMap());

        final result = await repository.delete(docRef.id, 'other-user-id');

        expect(result.isLeft(), isTrue);
      });

      test('debe eliminar visitas relacionadas al eliminar la invitación',
          () async {
        final invitationWithOwner =
            testInvitation.copyWith(ownerId: 'creator-id');
        final docRef = await fakeFirestore
            .collection('guests')
            .add(invitationWithOwner.toMap());

        // Crear visitas relacionadas
        await fakeFirestore.collection('visits').add({
          'guestId': docRef.id,
          'guestName': 'Test Guest',
          'scannedAt': DateTime.now(),
        });
        await fakeFirestore.collection('visits').add({
          'guestId': docRef.id,
          'guestName': 'Test Guest',
          'scannedAt': DateTime.now(),
        });

        final result = await repository.delete(docRef.id, 'creator-id');

        expect(result.isRight(), isTrue);

        // Verificar que las visitas fueron eliminadas
        final visitsSnapshot = await fakeFirestore
            .collection('visits')
            .where('guestId', isEqualTo: docRef.id)
            .get();
        expect(visitsSnapshot.docs.length, equals(0));
      });

      test('debe fallar cuando la invitación no existe', () async {
        final result =
            await repository.delete('nonexistent-id', 'creator-id');

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
