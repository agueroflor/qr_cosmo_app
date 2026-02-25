// lib/services/qr_service.dart
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class QRService {
  // Generar código QR único
  static String generateQRCode({
    required String guestId,
    required String dni,
    required DateTime createdAt,
  }) {
    // Crear un hash único basado en los datos del invitado
    final data = '$guestId-$dni-${createdAt.millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    // Tomar los primeros 8 caracteres del hash y agregar un prefijo
    final shortHash = digest.toString().substring(0, 8).toUpperCase();
    return 'COSMO-$shortHash';
  }

  // Validar formato de código QR
  static bool isValidQRCode(String qrCode) {
    final regex = RegExp(r'^COSMO-[A-F0-9]{8}$');
    return regex.hasMatch(qrCode);
  }

  // Extraer información del código QR (si necesitas decodificar)
  static Map<String, String> decodeQRInfo(String qrCode) {
    if (!isValidQRCode(qrCode)) {
      throw ArgumentError('Código QR inválido');
    }

    return {
      'prefix': 'COSMO',
      'hash': qrCode.substring(6), // Después de "COSMO-"
      'isValid': 'true',
    };
  }

  // Generar DNI de prueba (solo para testing)
  static String generateTestDNI() {
    final random = Random();
    final dni = random.nextInt(90000000) + 10000000; // DNI de 8 dígitos
    return dni.toString();
  }

  // Crear widget QR con logo personalizado para la app
  static Widget buildQRWithLogo(String qrCode, {double size = 200.0}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título del QR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'COSMO VIP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // QR con logo
          QrImageView(
            data: qrCode,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            // Logo desde assets
            embeddedImage: const AssetImage('assets/images/logo.jpeg'),
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: Size(size * 0.25, size * 0.25), // 25% del tamaño del QR
            ),
            errorCorrectionLevel: QrErrorCorrectLevel.H, // Alto nivel para logos
          ),
          
          const SizedBox(height: 8),
          const Text(
            'Pase VIP Exclusivo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Crear widget QR simple con logo (sin decoración extra)
  static Widget buildSimpleQRWithLogo(String qrCode, {double size = 200.0}) {
    return QrImageView(
      data: qrCode,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      embeddedImage: const AssetImage('assets/images/logo.jpeg'),
      embeddedImageStyle: QrEmbeddedImageStyle(
        size: Size(size * 0.2, size * 0.2), // 20% del tamaño del QR
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
  }
}