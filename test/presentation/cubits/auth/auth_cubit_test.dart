import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';
import 'package:qr_cosmo_app/domain/repositories/admin_auth_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/auth/validate_admin_access_usecase.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

class MockAdminAuthRepository extends Mock implements AdminAuthRepository {}

class FakeValidateAdminAccessParams extends Fake
    implements ValidateAdminAccessParams {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAdminAuthRepository mockAdminAuthRepository;
  late ValidateAdminAccessUseCase validateAdminAccessUseCase;

  final testUser = UserModel(
    id: 'test-id',
    email: 'test@example.com',
    name: 'Test User',
    role: UserRole.reader,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeValidateAdminAccessParams());
    registerFallbackValue(UserRole.reader);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAdminAuthRepository = MockAdminAuthRepository();
    validateAdminAccessUseCase =
        ValidateAdminAccessUseCase(mockAdminAuthRepository);
  });

  group('AuthCubit', () {
    late AuthCubit authCubit;

    setUp(() {
      // Configurar el stream de cambios de auth
      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      authCubit = AuthCubit(mockAuthRepository, validateAdminAccessUseCase);
    });

    tearDown(() {
      authCubit.close();
    });

    test('estado cambia a AuthUnauthenticated cuando stream emite null',
        () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(authCubit.state, isA<AuthUnauthenticated>());
    });

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando signIn es exitoso',
      build: () {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Right(testUser));
        return authCubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'test@example.com',
        password: 'password123',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthError] cuando signIn falla',
      build: () {
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer(
                (_) async => Left(AuthFailure.invalidCredentials()));
        return authCubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'test@example.com',
        password: 'wrongpassword',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthUnauthenticated] cuando signOut es exitoso',
      build: () {
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        return authCubit;
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signOut()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emite AuthError cuando se intenta registrar con rol admin sin código de acceso',
      build: () => authCubit,
      act: (cubit) => cubit.register(
        email: 'admin@example.com',
        password: 'password123',
        name: 'Admin User',
        role: UserRole.admin,
        adminPassword: null,
      ),
      expect: () => [
        isA<AuthError>().having(
          (e) => e.code,
          'code',
          'ADMIN_PASSWORD_REQUIRED',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite AuthError cuando se intenta registrar con código de acceso vacío',
      build: () => authCubit,
      act: (cubit) => cubit.register(
        email: 'admin@example.com',
        password: 'password123',
        name: 'Admin User',
        role: UserRole.admin,
        adminPassword: '',
      ),
      expect: () => [
        isA<AuthError>().having(
          (e) => e.code,
          'code',
          'ADMIN_PASSWORD_REQUIRED',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite AuthError cuando el repositorio rechaza el código de acceso',
      build: () {
        when(() => mockAdminAuthRepository.validateAdminAccess(
              accessCode: any(named: 'accessCode'),
              requestedRole: any(named: 'requestedRole'),
            )).thenAnswer((_) async => const Left(AuthFailure(
              'Código de acceso inválido',
              code: 'INVALID_ADMIN_PASSWORD',
            )));
        return authCubit;
      },
      act: (cubit) => cubit.register(
        email: 'admin@example.com',
        password: 'password123',
        name: 'Admin User',
        role: UserRole.admin,
        adminPassword: 'wrongcode',
      ),
      expect: () => [
        isA<AuthError>().having(
          (e) => e.code,
          'code',
          'INVALID_ADMIN_PASSWORD',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando registro con rol admin es exitoso',
      build: () {
        when(() => mockAdminAuthRepository.validateAdminAccess(
              accessCode: any(named: 'accessCode'),
              requestedRole: any(named: 'requestedRole'),
            )).thenAnswer((_) async => const Right(UserRole.admin));
        when(() => mockAuthRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
            )).thenAnswer((_) async => Right(testUser.copyWith(
              role: UserRole.admin,
            )));
        return authCubit;
      },
      act: (cubit) => cubit.register(
        email: 'admin@example.com',
        password: 'password123',
        name: 'Admin User',
        role: UserRole.admin,
        adminPassword: 'validcode',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockAdminAuthRepository.validateAdminAccess(
              accessCode: 'validcode',
              requestedRole: UserRole.admin,
            )).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'no valida acceso admin para rol reader',
      build: () {
        when(() => mockAuthRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
            )).thenAnswer((_) async => Right(testUser));
        return authCubit;
      },
      act: (cubit) => cubit.register(
        email: 'reader@example.com',
        password: 'password123',
        name: 'Reader User',
        role: UserRole.reader,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verifyNever(() => mockAdminAuthRepository.validateAdminAccess(
              accessCode: any(named: 'accessCode'),
              requestedRole: any(named: 'requestedRole'),
            ));
      },
    );

    test('currentUser retorna null cuando no está autenticado', () {
      expect(authCubit.currentUser, isNull);
    });

    test('isAuthenticated retorna false cuando no está autenticado', () {
      expect(authCubit.isAuthenticated, isFalse);
    });
  });

  group('AuthAuthenticated state', () {
    test('canGenerateQR es true para rol generator', () {
      final state = AuthAuthenticated(UserModel(
        id: '1',
        email: 'gen@test.com',
        name: 'Generator',
        role: UserRole.generator,
        createdAt: DateTime.now(),
      ));
      expect(state.canGenerateQR, isTrue);
    });

    test('canReadQR es true para rol reader', () {
      final state = AuthAuthenticated(UserModel(
        id: '1',
        email: 'reader@test.com',
        name: 'Reader',
        role: UserRole.reader,
        createdAt: DateTime.now(),
      ));
      expect(state.canReadQR, isTrue);
    });

    test('canViewStatistics es true solo para admin', () {
      final adminState = AuthAuthenticated(UserModel(
        id: '1',
        email: 'admin@test.com',
        name: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      ));
      expect(adminState.canViewStatistics, isTrue);

      final readerState = AuthAuthenticated(UserModel(
        id: '2',
        email: 'reader@test.com',
        name: 'Reader',
        role: UserRole.reader,
        createdAt: DateTime.now(),
      ));
      expect(readerState.canViewStatistics, isFalse);
    });
  });

  group('ValidateAdminAccessUseCase', () {
    test('retorna rol directamente si no requiere validación admin', () async {
      final result = await validateAdminAccessUseCase(
        const ValidateAdminAccessParams(
          accessCode: '',
          requestedRole: UserRole.reader,
        ),
      );

      expect(result, const Right(UserRole.reader));
      verifyNever(() => mockAdminAuthRepository.validateAdminAccess(
            accessCode: any(named: 'accessCode'),
            requestedRole: any(named: 'requestedRole'),
          ));
    });

    test('retorna error si código vacío para rol privilegiado', () async {
      final result = await validateAdminAccessUseCase(
        const ValidateAdminAccessParams(
          accessCode: '',
          requestedRole: UserRole.admin,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.code, 'ADMIN_PASSWORD_REQUIRED'),
        (_) => fail('Debería haber fallado'),
      );
    });

    test('delega al repositorio cuando código no vacío y rol privilegiado',
        () async {
      when(() => mockAdminAuthRepository.validateAdminAccess(
            accessCode: 'mycode',
            requestedRole: UserRole.generator,
          )).thenAnswer((_) async => const Right(UserRole.generator));

      final result = await validateAdminAccessUseCase(
        const ValidateAdminAccessParams(
          accessCode: 'mycode',
          requestedRole: UserRole.generator,
        ),
      );

      expect(result, const Right(UserRole.generator));
      verify(() => mockAdminAuthRepository.validateAdminAccess(
            accessCode: 'mycode',
            requestedRole: UserRole.generator,
          )).called(1);
    });
  });

  group('UserRole', () {
    test('requiresAdminValidation es true para admin y generator', () {
      expect(UserRole.admin.requiresAdminValidation, isTrue);
      expect(UserRole.generator.requiresAdminValidation, isTrue);
      expect(UserRole.reader.requiresAdminValidation, isFalse);
    });

    test('permisos de roles son correctos', () {
      expect(UserRole.admin.canGenerateQR, isTrue);
      expect(UserRole.admin.canReadQR, isTrue);
      expect(UserRole.admin.canViewStatistics, isTrue);

      expect(UserRole.generator.canGenerateQR, isTrue);
      expect(UserRole.generator.canReadQR, isFalse);
      expect(UserRole.generator.canViewStatistics, isFalse);

      expect(UserRole.reader.canGenerateQR, isFalse);
      expect(UserRole.reader.canReadQR, isTrue);
      expect(UserRole.reader.canViewStatistics, isFalse);
    });
  });
}
