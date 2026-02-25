import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_qr_code_usecase.dart';

void main() {
  late ValidateQrCodeUseCase useCase;

  setUp(() {
    useCase = ValidateQrCodeUseCase();
  });

  group('ValidateQrCodeUseCase', () {
    test('debe retornar true para QR con formato válido COSMO-XXXXXXXX', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'COSMO-ABC12345'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isTrue),
      );
    });

    test('debe retornar true para QR con formato válido (letras mayúsculas y números)', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'COSMO-12345678'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isTrue),
      );
    });

    test('debe retornar false para QR sin prefijo COSMO-', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'ABC12345678'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('debe retornar false para QR con longitud incorrecta', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'COSMO-ABC'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('debe retornar false para QR vacío', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: ''),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('debe retornar false para QR con caracteres minúsculos', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'COSMO-abc12345'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('debe retornar false para QR con caracteres especiales', () async {
      final result = await useCase(
        const ValidateQrCodeParams(qrCode: 'COSMO-ABC@#345'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('ValidateQrCodeParams debe ser equatable', () {
      const params1 = ValidateQrCodeParams(qrCode: 'COSMO-ABC12345');
      const params2 = ValidateQrCodeParams(qrCode: 'COSMO-ABC12345');
      const params3 = ValidateQrCodeParams(qrCode: 'COSMO-DIFFERENT');

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
