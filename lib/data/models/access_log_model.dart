import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de QR que pueden ser escaneados
enum QRType {
  personal,
  invitation,
}

/// Resultado del intento de escaneo
enum AccessResult {
  granted,
  denied,
}

/// Razón del resultado del escaneo
enum AccessReason {
  ok,
  alreadyUsed,
  noRemainingUses,
  inactive,
  invalid,
  noInternet,
  exception,
}

/// Modelo para registrar cada intento de escaneo de QR.
/// Este modelo es independiente de VisitModel y registra TODOS los intentos,
/// exitosos o fallidos.
class AccessLogModel {
  final String id;

  /// ID de la noche operativa (formato: "YYYY-MM-DD")
  /// Para escaneos entre 00:00-06:00, corresponde al día anterior
  /// SIEMPRE debe ser viernes o sábado
  final String nightId;

  /// Timestamp exacto del intento de escaneo
  final DateTime timestamp;

  /// Código QR escaneado
  final String qrCode;

  /// ID del invitado (null si el QR es inválido o no existe)
  final String? guestId;

  /// Nombre del invitado (null si el QR es inválido o no existe)
  final String? guestName;

  /// Tipo de QR: "personal" o "invitation"
  final QRType qrType;

  /// Resultado: "granted" o "denied"
  final AccessResult result;

  /// Razón del resultado
  final AccessReason reason;

  /// ID del usuario que realizó el escaneo
  final String scannedBy;

  /// Nombre del usuario que realizó el escaneo
  final String scannedByName;

  /// ID del dispositivo (opcional)
  final String? deviceId;

  /// Total de visitas del invitado después del escaneo (opcional)
  /// Solo aplica para escaneos exitosos
  final int? totalVisitsAfterScan;

  /// Cantidad de invitados registrados (para invitaciones)
  final int? guestCount;

  /// Mensaje de error adicional (para exceptions)
  final String? errorMessage;

  AccessLogModel({
    required this.id,
    required this.nightId,
    required this.timestamp,
    required this.qrCode,
    this.guestId,
    this.guestName,
    required this.qrType,
    required this.result,
    required this.reason,
    required this.scannedBy,
    required this.scannedByName,
    this.deviceId,
    this.totalVisitsAfterScan,
    this.guestCount,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nightId': nightId,
      'timestamp': Timestamp.fromDate(timestamp),
      'qrCode': qrCode,
      'guestId': guestId,
      'guestName': guestName,
      'qrType': qrType.name,
      'result': result.name,
      'reason': _reasonToString(reason),
      'scannedBy': scannedBy,
      'scannedByName': scannedByName,
      'deviceId': deviceId,
      'totalVisitsAfterScan': totalVisitsAfterScan,
      'guestCount': guestCount,
      'errorMessage': errorMessage,
    };
  }

  factory AccessLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AccessLogModel(
      id: documentId,
      nightId: map['nightId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      qrCode: map['qrCode'] ?? '',
      guestId: map['guestId'],
      guestName: map['guestName'],
      qrType: _parseQRType(map['qrType']),
      result: _parseAccessResult(map['result']),
      reason: _parseAccessReason(map['reason']),
      scannedBy: map['scannedBy'] ?? '',
      scannedByName: map['scannedByName'] ?? '',
      deviceId: map['deviceId'],
      totalVisitsAfterScan: map['totalVisitsAfterScan'],
      guestCount: map['guestCount'],
      errorMessage: map['errorMessage'],
    );
  }

  static QRType _parseQRType(String? value) {
    switch (value) {
      case 'invitation':
        return QRType.invitation;
      case 'personal':
      default:
        return QRType.personal;
    }
  }

  static AccessResult _parseAccessResult(String? value) {
    switch (value) {
      case 'granted':
        return AccessResult.granted;
      case 'denied':
      default:
        return AccessResult.denied;
    }
  }

  static AccessReason _parseAccessReason(String? value) {
    switch (value) {
      case 'ok':
        return AccessReason.ok;
      case 'already_used':
        return AccessReason.alreadyUsed;
      case 'no_remaining_uses':
        return AccessReason.noRemainingUses;
      case 'inactive':
        return AccessReason.inactive;
      case 'invalid':
        return AccessReason.invalid;
      case 'no_internet':
        return AccessReason.noInternet;
      case 'exception':
      default:
        return AccessReason.exception;
    }
  }

  static String _reasonToString(AccessReason reason) {
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

  AccessLogModel copyWith({
    String? id,
    String? nightId,
    DateTime? timestamp,
    String? qrCode,
    String? guestId,
    String? guestName,
    QRType? qrType,
    AccessResult? result,
    AccessReason? reason,
    String? scannedBy,
    String? scannedByName,
    String? deviceId,
    int? totalVisitsAfterScan,
    int? guestCount,
    String? errorMessage,
  }) {
    return AccessLogModel(
      id: id ?? this.id,
      nightId: nightId ?? this.nightId,
      timestamp: timestamp ?? this.timestamp,
      qrCode: qrCode ?? this.qrCode,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      qrType: qrType ?? this.qrType,
      result: result ?? this.result,
      reason: reason ?? this.reason,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedByName: scannedByName ?? this.scannedByName,
      deviceId: deviceId ?? this.deviceId,
      totalVisitsAfterScan: totalVisitsAfterScan ?? this.totalVisitsAfterScan,
      guestCount: guestCount ?? this.guestCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
