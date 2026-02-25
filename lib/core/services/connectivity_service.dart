
// lib/services/connectivity_service.dart
import 'dart:async';
import 'dart:io';

/// Servicio para verificar la conectividad a Internet.
///
/// Este servicio verifica la conectividad real intentando una conexión
/// a servidores DNS conocidos, lo cual es más confiable que solo verificar
/// el estado de la conexión WiFi/móvil.
class ConnectivityService {
  /// Timeout para verificación de conectividad (en segundos)
  static const int _connectivityTimeoutSeconds = 5;

  /// Hosts DNS conocidos para verificar conectividad
  static const List<String> _dnsHosts = [
    '8.8.8.8',       // Google DNS
    '8.8.4.4',       // Google DNS secundario
    '1.1.1.1',       // Cloudflare DNS
  ];

  /// Verifica si hay conexión a Internet disponible.
  ///
  /// Intenta realizar una conexión a servidores DNS conocidos.
  /// Retorna true si hay conexión, false si no hay.
  ///
  /// Este método NO lanza excepciones, siempre retorna un booleano.
  static Future<bool> hasInternetConnection() async {
    try {
      for (final host in _dnsHosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: _connectivityTimeoutSeconds));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          // Continuar con el siguiente host
          continue;
        }
      }
      // Si ningún host responde, no hay conexión
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica conectividad específica a Firebase/Google Cloud.
  ///
  /// Intenta resolver el dominio de Firestore.
  /// Retorna true si hay conexión a Firebase, false si no.
  static Future<bool> hasFirebaseConnection() async {
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: _connectivityTimeoutSeconds));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Verifica conectividad con un callback de error detallado.
  ///
  /// Retorna un Map con:
  /// - 'connected': bool indicando si hay conexión
  /// - 'error': String? con el mensaje de error si no hay conexión
  static Future<Map<String, dynamic>> checkConnectivityWithDetails() async {
    try {
      final hasConnection = await hasInternetConnection();
      if (hasConnection) {
        return {
          'connected': true,
          'error': null,
        };
      } else {
        return {
          'connected': false,
          'error': 'No se detectó conexión a Internet',
        };
      }
    } catch (e) {
      return {
        'connected': false,
        'error': 'Error verificando conectividad: $e',
      };
    }
  }
}
