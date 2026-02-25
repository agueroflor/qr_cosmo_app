// lib/domain/services/access_log_service.dart
import 'package:qr_cosmo_app/data/models/access_log_model.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

/// Interfaz abstracta para el servicio de logging de accesos.
///
/// Define las operaciones necesarias para registrar y consultar
/// los intentos de escaneo de QR.
abstract class AccessLogService {
  /// Registra un intento de escaneo de QR.
  ///
  /// Este método debe ser llamado para CADA intento de escaneo,
  /// independientemente de si fue exitoso o no.
  ///
  /// [qrCode] - El código QR escaneado
  /// [guest] - El modelo del invitado (null si el QR es inválido/no existe)
  /// [result] - Resultado del intento (granted/denied)
  /// [reason] - Razón del resultado
  /// [scannedBy] - ID del usuario que escaneó
  /// [scannedByName] - Nombre del usuario que escaneó
  /// [guestCount] - Cantidad de invitados (para invitaciones)
  /// [totalVisitsAfterScan] - Total de visitas después del escaneo
  /// [errorMessage] - Mensaje de error adicional
  /// [deviceId] - ID del dispositivo (opcional)
  Future<void> logAccess({
    required String qrCode,
    GuestModel? guest,
    required AccessResult result,
    required AccessReason reason,
    required String scannedBy,
    required String scannedByName,
    int? guestCount,
    int? totalVisitsAfterScan,
    String? errorMessage,
    String? deviceId,
  });

  /// Obtiene los logs de acceso para una noche específica.
  ///
  /// [nightId] - ID de la noche operativa (formato: "YYYY-MM-DD")
  Future<List<AccessLogModel>> getLogsForNight(String nightId);

  /// Obtiene los logs de acceso para un invitado específico.
  ///
  /// [guestId] - ID del invitado
  /// [limit] - Límite de resultados (opcional)
  Future<List<AccessLogModel>> getLogsForGuest(String guestId, {int? limit});

  /// Obtiene los intentos fallidos para una noche específica.
  ///
  /// [nightId] - ID de la noche operativa
  Future<List<AccessLogModel>> getFailedAttemptsForNight(String nightId);

  /// Obtiene estadísticas de acceso para una noche específica.
  ///
  /// Retorna un Map con:
  /// - 'totalAttempts': int
  /// - 'grantedCount': int
  /// - 'deniedCount': int
  /// - 'reasonBreakdown': Map<String, int>
  Future<Map<String, dynamic>> getAccessStatsForNight(String nightId);
}
