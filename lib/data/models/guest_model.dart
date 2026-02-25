import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_cosmo_app/domain/entities/invitation_validity_type.dart';
import 'package:qr_cosmo_app/domain/entities/operational_day.dart';

class GuestModel {
  final String id;
  final String name;
  final String dni;
  final String qrCode;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isActive;
  final int totalVisits;
  final DateTime? lastVisit;
  final DateTime? lastUsedDate; // Last date the QR was used
  final String? ownerId; // ID del dueño del QR (quien puede eliminarlo)
  final DateTime? lastSuccessfulEntry;

  // Campos para invitaciones con usos limitados
  final bool isInvitation; // Si es una invitación (no un invitado personal)
  final int? maxUses; // Cantidad máxima de usos permitidos
  final DateTime?
  validUntil; // Fecha de referencia (legacy, mantenido para compat)
  final InvitationValidityType validityType; // Tipo de validez de la invitación
  final DateTime?
  validForDate; // Fecha para la cual es válida (según validityType)

  GuestModel({
    required this.id,
    required this.name,
    required this.dni,
    required this.qrCode,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isActive = true,
    this.totalVisits = 0,
    this.lastVisit,
    this.lastUsedDate,
    this.ownerId,
    this.isInvitation = false,
    this.maxUses,
    this.validUntil,
    this.validityType = InvitationValidityType.unlimited,
    this.validForDate,
    this.lastSuccessfulEntry,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dni': dni,
      'qrCode': qrCode,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'totalVisits': totalVisits,
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
      'lastUsedDate': lastUsedDate != null
          ? Timestamp.fromDate(lastUsedDate!)
          : null,
      'ownerId':
          ownerId ??
          createdBy, // Si no tiene ownerId, usar createdBy como fallback
      'isInvitation': isInvitation,
      'maxUses': maxUses,
      'validUntil': validForDate != null
          ? Timestamp.fromDate(validForDate!)
          : (validUntil != null ? Timestamp.fromDate(validUntil!) : null),
      'validityType': validityType.toFirestoreValue(),
      'validForDate': validForDate != null
          ? Timestamp.fromDate(validForDate!)
          : null,
      'lastSuccessfulEntry': lastSuccessfulEntry != null
          ? Timestamp.fromDate(lastSuccessfulEntry!)
          : null,
    };
  }

  factory GuestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GuestModel(
      id: documentId,
      name: map['name'] ?? '',
      dni: map['dni'] ?? '',
      qrCode: map['qrCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      totalVisits: map['totalVisits'] ?? 0,
      lastVisit: map['lastVisit'] != null
          ? (map['lastVisit'] as Timestamp).toDate()
          : null,
      lastUsedDate: map['lastUsedDate'] != null
          ? (map['lastUsedDate'] as Timestamp).toDate()
          : null,
      ownerId:
          map['ownerId'] ??
          map['createdBy'], // Si no tiene ownerId, usar createdBy como fallback
      isInvitation: map['isInvitation'] ?? false,
      maxUses: map['maxUses'],
      validUntil: map['validUntil'] != null
          ? (map['validUntil'] as Timestamp).toDate()
          : null,
      validityType: InvitationValidityType.fromFirestoreValue(
        map['validityType'] as String?,
      ),
      validForDate: map['validForDate'] != null
          ? (map['validForDate'] as Timestamp).toDate()
          : null,
      lastSuccessfulEntry: map['lastSuccessfulEntry'] != null
          ? (map['lastSuccessfulEntry'] as Timestamp).toDate()
          : null,
    );
  }

  GuestModel copyWith({
    String? id,
    String? name,
    String? dni,
    String? qrCode,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    bool? isActive,
    int? totalVisits,
    DateTime? lastVisit,
    DateTime? lastUsedDate,
    String? ownerId,
    bool? isInvitation,
    int? maxUses,
    DateTime? validUntil,
    InvitationValidityType? validityType,
    DateTime? validForDate,
    DateTime? lastSuccessfulEntry,
  }) {
    return GuestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dni: dni ?? this.dni,
      qrCode: qrCode ?? this.qrCode,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      totalVisits: totalVisits ?? this.totalVisits,
      lastVisit: lastVisit ?? this.lastVisit,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      ownerId: ownerId ?? this.ownerId,
      isInvitation: isInvitation ?? this.isInvitation,
      maxUses: maxUses ?? this.maxUses,
      validUntil: validUntil ?? this.validUntil,
      validityType: validityType ?? this.validityType,
      validForDate: validForDate ?? this.validForDate,
      lastSuccessfulEntry: lastSuccessfulEntry ?? this.lastSuccessfulEntry,
    );
  }

  // Verificar si el usuario actual es el dueño del QR
  bool isOwner(String? userId) {
    if (userId == null) return false;
    // Si no tiene ownerId, usar createdBy como fallback
    final effectiveOwnerId = ownerId ?? createdBy;
    return effectiveOwnerId == userId;
  }

  // Métodos de utilidad
  bool get hasVisited => totalVisits > 0;

  bool canRetryAfterFailure(Duration window) {
    if (lastUsedDate == null) return false;
    if (lastSuccessfulEntry != null &&
        lastUsedDate!.isBefore(lastSuccessfulEntry!)) {
      return false; // ya hubo entrada confirmada
    }

    return DateTime.now().difference(lastUsedDate!).inSeconds <
        window.inSeconds;
  }

  /// Indica si el QR fue usado recientemente.
  /// SOLO para permitir retry técnico (timeouts, doble scan, offline).
  /// NO habilita acceso ni saltea validaciones.
  bool get wasUsedRecently {
    if (lastUsedDate == null) return false;
    final now = DateTime.now();
    return now.difference(lastUsedDate!).inSeconds < 180;
  }

  /// True si el QR personal ya tuvo una entrada exitosa en el mismo "día de uso":
  /// - En día operativo (jue/vie/sáb): mismo día operativo.
  /// - En día no operativo: mismo día civil (evita múltiples entradas el mismo día).
  bool get wasUsedThisOperationalDay {
    if (lastSuccessfulEntry == null) return false;

    final now = DateTime.now();
    final currentOp = getOperationalDay(now);
    final lastOp = getOperationalDay(lastSuccessfulEntry!);

    if (currentOp != null && lastOp != null) {
      return currentOp == lastOp;
    }

    // Mismo día civil (días no operativos o cuando una fecha no tiene día operativo)
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastSuccessfulEntry!.year,
      lastSuccessfulEntry!.month,
      lastSuccessfulEntry!.day,
    );
    return today == lastDay;
  }

  // Obtener los minutos transcurridos desde el último uso
  int? get minutesSinceLastUse {
    if (lastUsedDate == null) return null;
    final now = DateTime.now();
    final difference = now.difference(lastUsedDate!);
    return difference.inMinutes;
  }

  bool get canEnter {
    if (!isActive) return false;

    if (!isInvitation) {
      // QR PERSONAL
      return !wasUsedThisOperationalDay;
    }

    // INVITACIONES
    return isValidInvitation;
  }

  /// Semántica explícita para QR personal: no usado hoy, activo, no expirado.
  bool get canEnterPersonalQr {
    if (isInvitation) return false;
    return isActive && !wasUsedThisOperationalDay && !isExpired;
  }

  /// Semántica explícita para invitaciones: activa, con usos y no expirada.
  bool get isInvitationValid {
    if (!isInvitation) return false;
    return isActive && hasRemainingUses && !isExpired;
  }

  String get formattedDni {
    // Formatear DNI con puntos (ej: 12.345.678)
    if (dni.length >= 7) {
      return dni.replaceAllMapped(
        RegExp(r'(\d{1,2})(\d{3})(\d{3})'),
        (Match m) => '${m[1]}.${m[2]}.${m[3]}',
      );
    }
    return dni;
  }

  // Validaciones para invitaciones
  bool get isExpired {
    if (!isInvitation) return false;
    switch (validityType) {
      case InvitationValidityType.unlimited:
        return false;
      case InvitationValidityType.expirationDate:
      case InvitationValidityType.operationalDay:
        if (validForDate == null) return false;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final validDay = DateTime(
          validForDate!.year,
          validForDate!.month,
          validForDate!.day,
        );
        return today.isAfter(validDay);
    }
  }

  bool get hasRemainingUses {
    if (!isInvitation || maxUses == null) return true;
    return totalVisits < maxUses!;
  }

  bool get isValidInvitation {
    if (!isInvitation) return true;
    return isActive && hasRemainingUses && !isExpired;
  }

  int get remainingUses {
    if (!isInvitation || maxUses == null) return 0;
    return maxUses! - totalVisits;
  }

  bool wasUsedOnDate(DateTime date) {
  if (lastUsedDate == null) return false;

  return lastUsedDate!.year == date.year &&
      lastUsedDate!.month == date.month &&
      lastUsedDate!.day == date.day;
}

}
