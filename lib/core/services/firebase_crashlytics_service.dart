
// lib/services/firebase_crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:qr_cosmo_app/domain/services/error_reporting_service.dart';

/// Implementación de ErrorReportingService usando Firebase Crashlytics.
///
/// Esta clase actúa como wrapper de Firebase Crashlytics para facilitar
/// el testing y desacoplar la dependencia.
class FirebaseCrashlyticsService implements ErrorReportingService {
  final FirebaseCrashlytics _crashlytics;

  FirebaseCrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  /// Singleton para acceso global
  static FirebaseCrashlyticsService? _instance;

  static FirebaseCrashlyticsService get instance {
    _instance ??= FirebaseCrashlyticsService();
    return _instance!;
  }

  @override
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  @override
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Habilita o deshabilita la recolección de datos de Crashlytics.
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Verifica si Crashlytics está habilitado.
  bool get isCrashlyticsCollectionEnabled =>
      _crashlytics.isCrashlyticsCollectionEnabled;
}
