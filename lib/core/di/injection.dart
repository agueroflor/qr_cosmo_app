import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Domain - Repositories (interfaces)
import 'package:qr_cosmo_app/domain/repositories/auth_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/invitation_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/statistics_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/admin_auth_repository.dart';

// Domain - UseCases
import 'package:qr_cosmo_app/domain/usecases/usecases.dart';
import 'package:qr_cosmo_app/domain/usecases/auth/validate_admin_access_usecase.dart';

// Data - Repository implementations
import 'package:qr_cosmo_app/data/repositories/auth_repository_impl.dart';
import 'package:qr_cosmo_app/data/repositories/guest_repository_impl.dart';
import 'package:qr_cosmo_app/data/repositories/visit_repository_impl.dart';
import 'package:qr_cosmo_app/data/repositories/invitation_repository_impl.dart';
import 'package:qr_cosmo_app/data/repositories/statistics_repository_impl.dart';
import 'package:qr_cosmo_app/data/repositories/admin_auth_repository_impl.dart';

// Presentation - Cubits
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/invitations/manage_invitations_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/generate_qr/generate_qr_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/admin_guests/admin_guests_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/generate_invitation/generate_invitation_cubit.dart';

// Presentation - Blocs
import 'package:qr_cosmo_app/presentation/blocs/scan_qr/scan_qr_bloc.dart';

/// Instancia global del contenedor de dependencias
final getIt = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación
/// Debe llamarse en main() antes de runApp()
Future<void> configureDependencies() async {
  // ══════════════════════════════════════════════════════════════════════════
  // EXTERNAL SERVICES (Firebase)
  // ══════════════════════════════════════════════════════════════════════════

  getIt.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // REPOSITORIES
  // ══════════════════════════════════════════════════════════════════════════

  // AuthRepository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  // GuestRepository
  getIt.registerLazySingleton<GuestRepository>(
    () => GuestRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  // VisitRepository
  getIt.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  // InvitationRepository
  getIt.registerLazySingleton<InvitationRepository>(
    () => InvitationRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  // StatisticsRepository
  getIt.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  // AdminAuthRepository
  // PLACEHOLDER: Reemplazar AdminAuthRepositoryImpl con implementación
  // backend real (Firebase Functions, Custom Claims, etc.)
  getIt.registerLazySingleton<AdminAuthRepository>(
    () => AdminAuthRepositoryImpl(),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // USE CASES - Scan QR
  // ══════════════════════════════════════════════════════════════════════════

  getIt.registerFactory<GetGuestByQrCodeUseCase>(
    () => GetGuestByQrCodeUseCase(getIt<GuestRepository>()),
  );

  getIt.registerFactory<ValidateQrCodeUseCase>(
    () => ValidateQrCodeUseCase(),
  );

  getIt.registerFactory<ValidateInvitationValidityUseCase>(
    () => ValidateInvitationValidityUseCase(),
  );

  getIt.registerFactory<ProcessGuestEntryUseCase>(
    () => ProcessGuestEntryUseCase(
      getIt<GuestRepository>(),
      getIt<VisitRepository>(),
      getIt<ValidateInvitationValidityUseCase>(),
    ),
  );

  getIt.registerFactory<GetLastScanCountUseCase>(
    () => GetLastScanCountUseCase(getIt<VisitRepository>()),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // USE CASES - Generate QR
  // ══════════════════════════════════════════════════════════════════════════

  getIt.registerFactory<CreateGuestUseCase>(
    () => CreateGuestUseCase(getIt<GuestRepository>()),
  );

  getIt.registerFactory<GenerateQrCodeUseCase>(
    () => GenerateQrCodeUseCase(),
  );

  getIt.registerFactory<ValidateGuestDataUseCase>(
    () => ValidateGuestDataUseCase(),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // USE CASES - Auth
  // ══════════════════════════════════════════════════════════════════════════

  getIt.registerFactory<ValidateAdminAccessUseCase>(
    () => ValidateAdminAccessUseCase(getIt<AdminAuthRepository>()),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BLOCS / CUBITS
  // ══════════════════════════════════════════════════════════════════════════

  // AuthCubit - Singleton para mantener estado global de auth
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      getIt<AuthRepository>(),
      getIt<ValidateAdminAccessUseCase>(),
    ),
  );

  // StatisticsCubit - Factory para nueva instancia por pantalla
  getIt.registerFactory<StatisticsCubit>(
    () => StatisticsCubit(getIt<StatisticsRepository>()),
  );

  // ManageInvitationsCubit - Factory para nueva instancia por pantalla
  getIt.registerFactory<ManageInvitationsCubit>(
    () => ManageInvitationsCubit(getIt<InvitationRepository>()),
  );

  // GenerateQrCubit - Factory para nueva instancia por pantalla
  getIt.registerFactory<GenerateQrCubit>(
    () => GenerateQrCubit(
      getIt<GuestRepository>(),
      getIt<CreateGuestUseCase>(),
      getIt<GenerateQrCodeUseCase>(),
    ),
  );

  // GenerateInvitationCubit - Factory para nueva instancia por pantalla
  getIt.registerFactory<GenerateInvitationCubit>(
    () => GenerateInvitationCubit(
      getIt<InvitationRepository>(),
      getIt<GenerateQrCodeUseCase>(),
    ),
  );

  // AdminGuestsCubit - Factory for new instance per screen
  getIt.registerFactory<AdminGuestsCubit>(
    () => AdminGuestsCubit(getIt<GuestRepository>()),
  );

  // ScanQrBloc - Factory para nueva instancia por pantalla
  getIt.registerFactory<ScanQrBloc>(
    () => ScanQrBloc(
      validateQrCodeUseCase: getIt<ValidateQrCodeUseCase>(),
      getGuestByQrCodeUseCase: getIt<GetGuestByQrCodeUseCase>(),
      processGuestEntryUseCase: getIt<ProcessGuestEntryUseCase>(),
      getLastScanCountUseCase: getIt<GetLastScanCountUseCase>(),
      validateInvitationValidityUseCase: getIt<ValidateInvitationValidityUseCase>(),
    ),
  );
}

/// Resetea todas las dependencias (útil para testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
