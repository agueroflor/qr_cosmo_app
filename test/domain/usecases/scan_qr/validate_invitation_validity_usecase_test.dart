import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/entities/invitation_validity_type.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_invitation_validity_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

void main() {
  late ValidateInvitationValidityUseCase useCase;

  setUp(() {
    useCase = ValidateInvitationValidityUseCase();
  });

  GuestModel _makeGuest({
    bool isInvitation = true,
    bool isActive = true,
    int totalVisits = 0,
    int maxUses = 5,
    InvitationValidityType validityType = InvitationValidityType.unlimited,
    DateTime? validForDate,
  }) {
    return GuestModel(
      id: 'inv-1',
      name: 'Test Invitation',
      dni: 'INV-123',
      qrCode: 'COSMO-INV12345',
      createdBy: 'user-1',
      createdByName: 'Admin',
      createdAt: DateTime(2024, 1, 1),
      isActive: isActive,
      totalVisits: totalVisits,
      isInvitation: isInvitation,
      maxUses: maxUses,
      validityType: validityType,
      validForDate: validForDate,
    );
  }

  group('Non-invitation guest', () {
    test('siempre retorna Right para guest no-invitación', () async {
      final guest = _makeGuest(isInvitation: false);
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 30, 20, 0),
      ));
      expect(result.isRight(), true);
    });
  });

  group('Guest inactivo', () {
    test('retorna QrFailure.deactivated para guest inactivo', () async {
      final guest = _makeGuest(isActive: false);
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 30, 20, 0),
      ));
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, 'QR_DEACTIVATED');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('Usos agotados', () {
    test('retorna QrFailure.maxUsesReached cuando no hay usos', () async {
      final guest = _makeGuest(totalVisits: 5, maxUses: 5);
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 30, 20, 0),
      ));
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, 'MAX_USES_REACHED');
        },
        (_) => fail('Should be Left'),
      );
    });
  });

  group('Unlimited', () {
    test('siempre retorna Right', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.unlimited,
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 3, 15, 14, 0), // Cualquier momento
      ));
      expect(result.isRight(), true);
    });

    test('retorna Right incluso sin validForDate', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.unlimited,
        validForDate: null,
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 6, 1, 10, 0),
      ));
      expect(result.isRight(), true);
    });
  });

  group('ExpirationDate', () {
    test('retorna Right cuando ahora es antes de la fecha', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.expirationDate,
        validForDate: DateTime(2025, 12, 31, 23, 59, 59),
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 6, 15, 20, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Left cuando ahora es después de la fecha', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.expirationDate,
        validForDate: DateTime(2025, 1, 15, 23, 59, 59),
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 16, 0, 0, 0),
      ));
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, 'INVITATION_EXPIRED');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('retorna Right cuando ahora es exactamente en la fecha', () async {
      final validDate = DateTime(2025, 1, 31, 23, 59, 59);
      final guest = _makeGuest(
        validityType: InvitationValidityType.expirationDate,
        validForDate: validDate,
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 31, 20, 0, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Right cuando validForDate es null', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.expirationDate,
        validForDate: null,
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 6, 15, 20, 0),
      ));
      expect(result.isRight(), true);
    });
  });

  group('OperationalDay', () {
    test('retorna Right cuando dia operativo coincide (viernes noche)', () async {
      // Invitación para el viernes 31 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 31), // Viernes
      );
      // Momento actual: viernes 31 de enero 2025, 22:00
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 31, 22, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Right cuando es madrugada del dia operativo (sab 03:00 -> viernes)', () async {
      // Invitación para el viernes 31 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 31), // Viernes
      );
      // Momento actual: sábado 1 de febrero 2025, 03:00 (aún pertenece al viernes)
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 2, 1, 3, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Left cuando dia operativo no coincide', () async {
      // Invitación para el viernes 31 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 31), // Viernes
      );
      // Momento actual: sábado 1 de febrero 2025, 22:00 (es noche de sábado)
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 2, 1, 22, 0),
      ));
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, 'NOT_FOR_TODAY');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('retorna Left cuando no hay dia operativo activo (lunes)', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 31), // Viernes
      );
      // Momento actual: lunes 3 de febrero 2025, 14:00
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 2, 3, 14, 0),
      ));
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, 'NO_ACTIVE_OPERATIONAL_DAY');
        },
        (_) => fail('Should be Left'),
      );
    });

    test('retorna Right cuando validForDate es null (backward compat)', () async {
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: null,
      );
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 31, 22, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Right para jueves noche con invitación del jueves', () async {
      // Invitación para el jueves 30 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 30), // Jueves
      );
      // Momento actual: jueves 30 de enero 2025, 23:00
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 30, 23, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Right para viernes 02:00 con invitación del jueves', () async {
      // Invitación para el jueves 30 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 30), // Jueves
      );
      // Momento actual: viernes 31 de enero 2025, 02:00 (antes cierre jueves)
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 1, 31, 2, 0),
      ));
      expect(result.isRight(), true);
    });

    test('retorna Left para sábado noche con invitación del viernes', () async {
      // Invitación para el viernes 31 de enero 2025
      final guest = _makeGuest(
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2025, 1, 31), // Viernes
      );
      // Momento actual: sábado 1 de febrero 2025, 22:00 (noche de sábado, no viernes)
      final result = await useCase(ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime(2025, 2, 1, 22, 0),
      ));
      expect(result.isLeft(), true);
    });
  });

  group('InvitationValidityType serialization', () {
    test('toFirestoreValue retorna name', () {
      expect(InvitationValidityType.operationalDay.toFirestoreValue(), 'operationalDay');
      expect(InvitationValidityType.expirationDate.toFirestoreValue(), 'expirationDate');
      expect(InvitationValidityType.unlimited.toFirestoreValue(), 'unlimited');
    });

    test('fromFirestoreValue con valores válidos', () {
      expect(InvitationValidityType.fromFirestoreValue('operationalDay'),
          InvitationValidityType.operationalDay);
      expect(InvitationValidityType.fromFirestoreValue('expirationDate'),
          InvitationValidityType.expirationDate);
      expect(InvitationValidityType.fromFirestoreValue('unlimited'),
          InvitationValidityType.unlimited);
    });

    test('fromFirestoreValue con null retorna unlimited (backward compat)', () {
      expect(InvitationValidityType.fromFirestoreValue(null),
          InvitationValidityType.unlimited);
    });

    test('fromFirestoreValue con valor desconocido retorna unlimited', () {
      expect(InvitationValidityType.fromFirestoreValue('unknown'),
          InvitationValidityType.unlimited);
    });

    test('displayName retorna texto correcto', () {
      expect(InvitationValidityType.operationalDay.displayName, 'Día específico');
      expect(InvitationValidityType.expirationDate.displayName, 'Fecha límite');
      expect(InvitationValidityType.unlimited.displayName, 'Sin vencimiento');
    });
  });
}
