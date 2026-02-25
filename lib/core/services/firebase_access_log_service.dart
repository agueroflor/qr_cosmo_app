
// lib/services/firebase_access_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_cosmo_app/data/models/access_log_model.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/domain/services/access_log_service.dart';
import 'package:qr_cosmo_app/core/services/night_id_service.dart';
import 'package:qr_cosmo_app/domain/services/error_reporting_service.dart';

/// Implementación de AccessLogService usando Firebase Firestore.
///
/// Guarda los logs de acceso en la colección 'access_logs'.
class FirebaseAccessLogService implements AccessLogService {
  final FirebaseFirestore _firestore;
  final ErrorReportingService? _errorReporting;

  /// Nombre de la colección en Firestore
  static const String collectionName = 'access_logs';

  FirebaseAccessLogService({
    FirebaseFirestore? firestore,
    ErrorReportingService? errorReporting,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _errorReporting = errorReporting;

  /// Singleton para acceso global
  static FirebaseAccessLogService? _instance;

  static FirebaseAccessLogService get instance {
    _instance ??= FirebaseAccessLogService();
    return _instance!;
  }

  /// Inicializa el singleton con un ErrorReportingService.
  static void initialize({ErrorReportingService? errorReporting}) {
    _instance = FirebaseAccessLogService(errorReporting: errorReporting);
  }

  @override
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
  }) async {
    try {
      final now = DateTime.now();
      final nightId = NightIdService.calculateNightId(now);

      // Determinar tipo de QR
      final qrType = guest?.isInvitation == true
          ? QRType.invitation
          : QRType.personal;

      // Crear el modelo de log
      final log = AccessLogModel(
        id: '', // Se asignará por Firestore
        nightId: nightId,
        timestamp: now,
        qrCode: qrCode,
        guestId: guest?.id,
        guestName: guest?.name,
        qrType: qrType,
        result: result,
        reason: reason,
        scannedBy: scannedBy,
        scannedByName: scannedByName,
        deviceId: deviceId,
        totalVisitsAfterScan: totalVisitsAfterScan,
        guestCount: guestCount,
        errorMessage: errorMessage,
      );

      // Guardar en Firestore
      await _firestore.collection(collectionName).add(log.toMap());
    } catch (e, stackTrace) {
      // Registrar el error en Crashlytics pero NO propagar la excepción
      // El logging no debe interrumpir el flujo principal
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error guardando access log',
      );
      // Log local para debugging
      print('Error guardando access log: $e');
    }
  }

  @override
  Future<List<AccessLogModel>> getLogsForNight(String nightId) async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('nightId', isEqualTo: nightId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => AccessLogModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo logs para noche $nightId',
      );
      return [];
    }
  }

  @override
  Future<List<AccessLogModel>> getLogsForGuest(String guestId,
      {int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(collectionName)
          .where('guestId', isEqualTo: guestId)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => AccessLogModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo logs para guest $guestId',
      );
      return [];
    }
  }

  @override
  Future<List<AccessLogModel>> getFailedAttemptsForNight(String nightId) async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('nightId', isEqualTo: nightId)
          .where('result', isEqualTo: 'denied')
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => AccessLogModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo intentos fallidos para noche $nightId',
      );
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getAccessStatsForNight(String nightId) async {
    try {
      final logs = await getLogsForNight(nightId);

      int grantedCount = 0;
      int deniedCount = 0;
      Map<String, int> reasonBreakdown = {};

      for (final log in logs) {
        if (log.result == AccessResult.granted) {
          grantedCount++;
        } else {
          deniedCount++;
        }

        final reasonKey = _reasonToString(log.reason);
        reasonBreakdown[reasonKey] = (reasonBreakdown[reasonKey] ?? 0) + 1;
      }

      return {
        'totalAttempts': logs.length,
        'grantedCount': grantedCount,
        'deniedCount': deniedCount,
        'reasonBreakdown': reasonBreakdown,
      };
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo estadísticas para noche $nightId',
      );
      return {
        'totalAttempts': 0,
        'grantedCount': 0,
        'deniedCount': 0,
        'reasonBreakdown': <String, int>{},
      };
    }
  }

  /// Obtiene logs filtrados por rango de tiempo.
  Future<List<AccessLogModel>> getLogsByTimeRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => AccessLogModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo logs por rango de tiempo',
      );
      return [];
    }
  }

  /// Obtiene los QR codes que fueron escaneados múltiples veces en una noche.
  Future<Map<String, int>> getMultipleScansForNight(String nightId) async {
    try {
      final logs = await getLogsForNight(nightId);

      // Contar escaneos por QR code
      Map<String, int> qrCounts = {};
      for (final log in logs) {
        qrCounts[log.qrCode] = (qrCounts[log.qrCode] ?? 0) + 1;
      }

      // Filtrar solo los que tienen más de 1 escaneo
      qrCounts.removeWhere((key, value) => value <= 1);

      return qrCounts;
    } catch (e, stackTrace) {
      await _errorReporting?.recordError(
        e,
        stackTrace: stackTrace,
        reason: 'Error obteniendo QRs con múltiples escaneos',
      );
      return {};
    }
  }

  String _reasonToString(AccessReason reason) {
    switch (reason) {
      case AccessReason.ok:
        return 'ok';
      case AccessReason.alreadyUsed:
        return 'already_used';
      case AccessReason.noRemainingUses:
        return 'no_remaining_uses';
      case AccessReason.inactive:
        return 'inactive';
      case AccessReason.invalid:
        return 'invalid';
      case AccessReason.noInternet:
        return 'no_internet';
      case AccessReason.exception:
        return 'exception';
    }
  }
}
