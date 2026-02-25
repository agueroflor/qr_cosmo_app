/// Validity types an invitation can have
enum InvitationValidityType {
  /// Valid only for a specific operational day (e.g. Friday night)
  operationalDay,

  /// Valid until an expiration date
  expirationDate,

  /// No expiration (only exhausted by uses)
  unlimited;

  /// Serializes to Firestore value
  String toFirestoreValue() => name;

  /// Deserializes from Firestore value
  /// null -> unlimited (backward compat with old documents)
  static InvitationValidityType fromFirestoreValue(String? value) {
    if (value == null) return InvitationValidityType.unlimited;
    return InvitationValidityType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => InvitationValidityType.unlimited,
    );
  }

  /// Display name for UI
  String get displayName => switch (this) {
        InvitationValidityType.operationalDay => 'Día específico',
        InvitationValidityType.expirationDate => 'Fecha límite',
        InvitationValidityType.unlimited => 'Sin vencimiento',
      };
}
