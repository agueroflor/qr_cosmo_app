// lib/domain/services/error_reporting_service.dart

/// Interfaz abstracta para servicios de reporte de errores.
///
/// Permite desacoplar la implementación concreta (Firebase Crashlytics)
/// del código que la utiliza.
abstract class ErrorReportingService {
  /// Reporta un error técnico (exception).
  ///
  /// [error] - El error o exception a reportar
  /// [stackTrace] - Stack trace opcional
  /// [reason] - Descripción opcional del contexto del error
  /// [fatal] - Si el error es fatal (crashea la app)
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  });

  /// Registra un mensaje informativo (no error).
  ///
  /// Útil para contexto adicional antes de un error.
  Future<void> log(String message);

  /// Establece un identificador de usuario para los reportes.
  Future<void> setUserId(String userId);

  /// Establece una clave-valor personalizada para los reportes.
  Future<void> setCustomKey(String key, dynamic value);
}
