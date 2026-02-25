
// lib/services/scan_observer_service.dart
import 'package:qr_cosmo_app/data/models/access_log_model.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/domain/services/access_log_service.dart';
import 'package:qr_cosmo_app/core/services/firebase_access_log_service.dart';
import 'package:qr_cosmo_app/domain/services/error_reporting_service.dart';
import 'package:qr_cosmo_app/core/services/firebase_crashlytics_service.dart';
import 'package:qr_cosmo_app/core/services/connectivity_service.dart';

/// Servicio observador para registrar todos los intentos de escaneo de QR.
///
/// Este servicio actúa como un observador del flujo de escaneo existente,
/// sin modificar la lógica de validación actual.
///
/// IMPORTANTE: Este servicio NO afecta el resultado de la validación.
/// Solo registra los eventos para auditoría.
class ScanObserverService {
  final AccessLogService _accessLogService;
  final ErrorReportingService _errorReportingService;

  ScanObserverService({
    AccessLogService? accessLogService,
    ErrorReportingService? errorReportingService,
  })  : _accessLogService = accessLogService ?? FirebaseAccessLogService.instance,
        _errorReportingService =
            errorReportingService ?? FirebaseCrashlyticsService.instance;

  /// Singleton para acceso global
  static ScanObserverService? _instance;

  static ScanObserverService get instance {
    _instance ??= ScanObserverService();
    return _instance!;
  }

  /// Inicializa el singleton con servicios personalizados.
  static void initialize({
    AccessLogService? accessLogService,
    ErrorReportingService? errorReportingService,
  }) {
    _instance = ScanObserverService(
      accessLogService: accessLogService,
      errorReportingService: errorReportingService,
    );
  }

  /// Registra un intento de escaneo exitoso (acceso concedido).
  ///
  /// Llamar este método cuando el QR es válido y el acceso fue autorizado.
  Future<void> onAccessGranted({
    required String qrCode,
    required GuestModel guest,
    required String scannedBy,
    required String scannedByName,
    int guestCount = 1,
    int? totalVisitsAfterScan,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: guest,
      result: AccessResult.granted,
      reason: AccessReason.ok,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      guestCount: guestCount,
      totalVisitsAfterScan: totalVisitsAfterScan,
      deviceId: deviceId,
    );
  }

  /// Registra un intento de escaneo fallido porque el QR ya fue usado hoy.
  Future<void> onAlreadyUsedToday({
    required String qrCode,
    required GuestModel guest,
    required String scannedBy,
    required String scannedByName,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: guest,
      result: AccessResult.denied,
      reason: AccessReason.alreadyUsed,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      deviceId: deviceId,
    );
  }

  /// Registra un intento de escaneo fallido porque la invitación no tiene usos restantes.
  Future<void> onNoRemainingUses({
    required String qrCode,
    required GuestModel guest,
    required String scannedBy,
    required String scannedByName,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: guest,
      result: AccessResult.denied,
      reason: AccessReason.noRemainingUses,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      deviceId: deviceId,
    );
  }

  /// Registra un intento de escaneo fallido porque el QR está inactivo.
  Future<void> onInactiveQR({
    required String qrCode,
    required GuestModel guest,
    required String scannedBy,
    required String scannedByName,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: guest,
      result: AccessResult.denied,
      reason: AccessReason.inactive,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      deviceId: deviceId,
    );
  }

  /// Registra un intento de escaneo fallido porque el QR es inválido o no existe.
  Future<void> onInvalidQR({
    required String qrCode,
    required String scannedBy,
    required String scannedByName,
    String? errorMessage,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: null,
      result: AccessResult.denied,
      reason: AccessReason.invalid,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      errorMessage: errorMessage,
      deviceId: deviceId,
    );
  }

  /// Registra un intento de escaneo fallido por falta de conexión a Internet.
  ///
  /// Este método primero verifica la conectividad antes de registrar.
  Future<void> onNoInternet({
    required String qrCode,
    required String scannedBy,
    required String scannedByName,
    String? deviceId,
  }) async {
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: null,
      result: AccessResult.denied,
      reason: AccessReason.noInternet,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      errorMessage: 'No hay conexión a Internet',
      deviceId: deviceId,
    );
  }

  /// Registra un error técnico (exception) durante el escaneo.
  ///
  /// IMPORTANTE: Este método también reporta el error a Crashlytics.
  Future<void> onException({
    required String qrCode,
    required String scannedBy,
    required String scannedByName,
    required dynamic error,
    StackTrace? stackTrace,
    GuestModel? guest,
    String? deviceId,
  }) async {
    // Reportar a Crashlytics
    await _errorReportingService.recordError(
      error,
      stackTrace: stackTrace,
      reason: 'Error durante escaneo de QR: $qrCode',
    );

    // Registrar en access_logs
    await _accessLogService.logAccess(
      qrCode: qrCode,
      guest: guest,
      result: AccessResult.denied,
      reason: AccessReason.exception,
      scannedBy: scannedBy,
      scannedByName: scannedByName,
      errorMessage: error.toString(),
      deviceId: deviceId,
    );
  }

  /// Verifica la conectividad y retorna true si hay conexión.
  ///
  /// Útil para verificar antes de intentar operaciones de red.
  Future<bool> checkConnectivity() async {
    return await ConnectivityService.hasInternetConnection();
  }

  /// Verifica la conectividad y registra un error si no hay conexión.
  ///
  /// Retorna true si hay conexión, false si no hay.
  /// Si no hay conexión, registra el intento con reason = "no_internet".
  Future<bool> checkConnectivityAndLog({
    required String qrCode,
    required String scannedBy,
    required String scannedByName,
    String? deviceId,
  }) async {
    final hasConnection = await ConnectivityService.hasInternetConnection();

    if (!hasConnection) {
      await onNoInternet(
        qrCode: qrCode,
        scannedBy: scannedBy,
        scannedByName: scannedByName,
        deviceId: deviceId,
      );
    }

    return hasConnection;
  }
}
