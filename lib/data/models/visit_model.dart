import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String id;
  final String guestId;
  final String guestName;
  final String dni;
  final String scannedBy;
  final String scannedByName;
  final DateTime scannedAt;
  final bool isFirstTime;
  final String? notes;

  VisitModel({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.dni,
    required this.scannedBy,
    required this.scannedByName,
    required this.scannedAt,
    required this.isFirstTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guestId': guestId,
      'guestName': guestName,
      'dni': dni,
      'scannedBy': scannedBy,
      'scannedByName': scannedByName,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'isFirstTime': isFirstTime,
      'notes': notes,
    };
  }

  factory VisitModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VisitModel(
      id: documentId,
      guestId: map['guestId'] ?? '',
      guestName: map['guestName'] ?? '',
      dni: map['dni'] ?? '',
      scannedBy: map['scannedBy'] ?? '',
      scannedByName: map['scannedByName'] ?? '',
      scannedAt: (map['scannedAt'] as Timestamp).toDate(),
      isFirstTime: map['isFirstTime'] ?? false,
      notes: map['notes'],
    );
  }

  VisitModel copyWith({
    String? id,
    String? guestId,
    String? guestName,
    String? dni,
    String? scannedBy,
    String? scannedByName,
    DateTime? scannedAt,
    bool? isFirstTime,
    String? notes,
  }) {
    return VisitModel(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      dni: dni ?? this.dni,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedByName: scannedByName ?? this.scannedByName,
      scannedAt: scannedAt ?? this.scannedAt,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      notes: notes ?? this.notes,
    );
  }

  // Formatear fecha para mostrar
  String get formattedDate {
    return '${scannedAt.day.toString().padLeft(2, '0')}/${scannedAt.month.toString().padLeft(2, '0')}/${scannedAt.year}';
  }

  String get formattedTime {
    return '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }
}
