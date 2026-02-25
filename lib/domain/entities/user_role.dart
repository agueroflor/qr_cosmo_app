/// Available roles in the system
enum UserRole {
  generator,
  reader,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.generator:
        return 'Generador QR';
      case UserRole.reader:
        return 'Lector QR';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  bool get canGenerateQR {
    return this == UserRole.generator || this == UserRole.admin;
  }

  bool get canReadQR {
    return this == UserRole.reader || this == UserRole.admin;
  }

  bool get canViewStatistics {
    return this == UserRole.admin;
  }

  /// Whether the role requires privileged access validation
  bool get requiresAdminValidation {
    return this == UserRole.generator || this == UserRole.admin;
  }
}
