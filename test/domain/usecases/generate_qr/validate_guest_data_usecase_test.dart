import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/usecases/generate_qr/validate_guest_data_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

void main() {
  late ValidateGuestDataUseCase useCase;

  GuestModel createGuest({
    String name = 'Test Guest',
    String dni = '12345678',
    String createdBy = 'creator-id',
    String createdByName = 'Creator Name',
    bool isInvitation = false,
    int? maxUses,
    DateTime? validUntil,
  }) {
    return GuestModel(
      id: '',
      name: name,
      dni: dni,
      qrCode: 'COSMO-ABC12345',
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      isActive: true,
      totalVisits: 0,
      isInvitation: isInvitation,
      maxUses: maxUses,
      validUntil: validUntil,
    );
  }

  setUp(() {
    useCase = ValidateGuestDataUseCase();
  });

  group('ValidateGuestDataUseCase', () {
    group('Validación de nombre', () {
      test('debe retornar lista vacía para datos válidos', () async {
        final guest = createGuest();

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe retornar error si nombre está vacío', () async {
        final guest = createGuest(name: '');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('nombre es requerido')), isTrue);
          },
        );
      });

      test('debe retornar error si nombre tiene menos de 2 caracteres', () async {
        final guest = createGuest(name: 'A');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('al menos 2 caracteres')), isTrue);
          },
        );
      });

      test('debe retornar error si nombre tiene más de 100 caracteres', () async {
        final guest = createGuest(name: 'A' * 101);

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('más de 100 caracteres')), isTrue);
          },
        );
      });
    });

    group('Validación de DNI', () {
      test('debe retornar error si DNI está vacío', () async {
        final guest = createGuest(dni: '');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('DNI es requerido')), isTrue);
          },
        );
      });

      test('debe aceptar DNI de 7 dígitos', () async {
        final guest = createGuest(dni: '1234567');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe aceptar DNI de 8 dígitos', () async {
        final guest = createGuest(dni: '12345678');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe aceptar DNI con puntos (formato argentino)', () async {
        final guest = createGuest(dni: '12.345.678');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe retornar error si DNI tiene menos de 7 dígitos', () async {
        final guest = createGuest(dni: '123456');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('7 y 8 dígitos')), isTrue);
          },
        );
      });

      test('debe retornar error si DNI tiene más de 8 dígitos', () async {
        final guest = createGuest(dni: '123456789');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('7 y 8 dígitos')), isTrue);
          },
        );
      });

      test('debe retornar error si DNI contiene letras', () async {
        final guest = createGuest(dni: '1234567A');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('dígitos numéricos')), isTrue);
          },
        );
      });
    });

    group('Validación de creador', () {
      test('debe retornar error si createdBy está vacío', () async {
        final guest = createGuest(createdBy: '');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('ID del creador')), isTrue);
          },
        );
      });

      test('debe retornar error si createdByName está vacío', () async {
        final guest = createGuest(createdByName: '');

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('nombre del creador')), isTrue);
          },
        );
      });
    });

    group('Validación de invitaciones', () {
      test('debe retornar error si maxUses es menor a 1', () async {
        final guest = createGuest(
          isInvitation: true,
          maxUses: 0,
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('al menos 1')), isTrue);
          },
        );
      });

      test('debe aceptar maxUses de 1 o más', () async {
        final guest = createGuest(
          isInvitation: true,
          maxUses: 1,
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe retornar error si validUntil es anterior a hoy', () async {
        final guest = createGuest(
          isInvitation: true,
          validUntil: DateTime.now().subtract(const Duration(days: 1)),
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors, isNotEmpty);
            expect(errors.any((e) => e.contains('anterior a hoy')), isTrue);
          },
        );
      });

      test('debe aceptar validUntil de hoy', () async {
        final guest = createGuest(
          isInvitation: true,
          validUntil: DateTime.now(),
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });

      test('debe aceptar validUntil futuro', () async {
        final guest = createGuest(
          isInvitation: true,
          validUntil: DateTime.now().add(const Duration(days: 7)),
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) => expect(errors, isEmpty),
        );
      });
    });

    group('Múltiples errores', () {
      test('debe retornar todos los errores cuando hay múltiples problemas', () async {
        final guest = createGuest(
          name: '',
          dni: 'invalid',
          createdBy: '',
        );

        final result = await useCase(ValidateGuestDataParams(guest: guest));

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('No debería fallar'),
          (errors) {
            expect(errors.length, greaterThanOrEqualTo(3));
          },
        );
      });
    });

    test('ValidateGuestDataParams debe ser equatable', () {
      final guest1 = createGuest(name: 'Guest 1');
      final guest2 = createGuest(name: 'Guest 1');
      final guest3 = createGuest(name: 'Guest 3');

      final params1 = ValidateGuestDataParams(guest: guest1);
      final params2 = ValidateGuestDataParams(guest: guest2);
      final params3 = ValidateGuestDataParams(guest: guest3);

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
