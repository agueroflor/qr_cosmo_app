// lib/core/constants/app_constants.dart
// Constantes globales de la aplicación

class AppConstants {
  AppConstants._();

  /// Tiempo en minutos para considerar un re-escaneo válido
  static const int rescanWindowMinutes = 5;

  /// Prefijo esperado en códigos QR válidos
  static const String qrCodePrefix = 'COSMO_';

  /// Colecciones de Firestore
  static const String guestsCollection = 'guests';
  static const String visitsCollection = 'visits';
  static const String usersCollection = 'users';
  static const String invitationsCollection = 'invitations';
  static const String accessLogsCollection = 'access_logs';

  /// Límites por defecto
  static const int defaultInvitationMaxUses = 10;
  static const int maxVisitsQueryLimit = 50;
}
