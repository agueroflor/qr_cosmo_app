import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/usecases/generate_qr/generate_qr_code_usecase.dart';

void main() {
  late GenerateQrCodeUseCase useCase;

  setUp(() {
    useCase = GenerateQrCodeUseCase();
  });

  group('GenerateQrCodeUseCase', () {
    test('debe generar código QR con formato COSMO-XXXXXXXX', () async {
      // Arrange
      final createdAt = DateTime.now();
      final params = GenerateQrCodeParams(
        guestId: 'guest-123',
        dni: '12345678',
        createdAt: createdAt,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (qrCode) {
          expect(qrCode, startsWith('COSMO-'));
          expect(qrCode.length, equals(14)); // COSMO- (6) + 8 caracteres
        },
      );
    });

    test('debe generar códigos únicos para diferentes inputs', () async {
      // Arrange
      final createdAt = DateTime.now();

      // Act
      final result1 = await useCase(GenerateQrCodeParams(
        guestId: 'guest-1',
        dni: '11111111',
        createdAt: createdAt,
      ));
      final result2 = await useCase(GenerateQrCodeParams(
        guestId: 'guest-2',
        dni: '22222222',
        createdAt: createdAt,
      ));

      // Assert
      expect(result1.isRight(), isTrue);
      expect(result2.isRight(), isTrue);

      final qrCode1 = result1.fold((_) => '', (code) => code);
      final qrCode2 = result2.fold((_) => '', (code) => code);

      expect(qrCode1, isNot(equals(qrCode2)));
    });

    test('debe generar el mismo código para los mismos inputs', () async {
      // Arrange
      final createdAt = DateTime(2024, 1, 15, 10, 30, 0);
      final params = GenerateQrCodeParams(
        guestId: 'guest-123',
        dni: '12345678',
        createdAt: createdAt,
      );

      // Act
      final result1 = await useCase(params);
      final result2 = await useCase(params);

      // Assert
      final qrCode1 = result1.fold((_) => '', (code) => code);
      final qrCode2 = result2.fold((_) => '', (code) => code);

      expect(qrCode1, equals(qrCode2));
    });

    test('debe generar códigos con caracteres hexadecimales válidos', () async {
      // Arrange
      final params = GenerateQrCodeParams(
        guestId: 'guest-123',
        dni: '12345678',
        createdAt: DateTime.now(),
      );

      // Act
      final result = await useCase(params);

      // Assert
      result.fold(
        (failure) => fail('No debería fallar'),
        (qrCode) {
          final hash = qrCode.substring(6); // Remover "COSMO-"
          // Verificar que solo contiene A-F y 0-9
          expect(RegExp(r'^[A-F0-9]{8}$').hasMatch(hash), isTrue);
        },
      );
    });

    test('GenerateQrCodeParams debe ser equatable', () {
      final createdAt = DateTime(2024, 1, 15);
      final params1 = GenerateQrCodeParams(
        guestId: 'guest-123',
        dni: '12345678',
        createdAt: createdAt,
      );
      final params2 = GenerateQrCodeParams(
        guestId: 'guest-123',
        dni: '12345678',
        createdAt: createdAt,
      );
      final params3 = GenerateQrCodeParams(
        guestId: 'guest-456',
        dni: '12345678',
        createdAt: createdAt,
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
