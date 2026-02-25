// lib/core/errors/exceptions.dart
// Excepciones técnicas (red, caché, servidor)

/// Excepción base para errores de servidor/API
class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Excepción para errores de caché local
class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción para errores de red
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Sin conexión a internet']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Excepción para errores de autenticación
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}
