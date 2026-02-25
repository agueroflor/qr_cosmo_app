import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_cosmo_app/presentation/utils/snackbar_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ShareService {
  // Compartir QR con opciones específicas
  static Future<void> shareQR({
    required String qrCode,
    required String guestName,
    required String guestDni,
    required BuildContext context,
  }) async {
    try {
      // Crear el mensaje personalizado
      final message = _createShareMessage(guestName, guestDni, qrCode);
      
      // Mostrar opciones de compartir
      await Share.share(
        message,
        subject: 'QR Cosmopolitan - $guestName',
        sharePositionOrigin: _shareOrigin(context),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Error al compartir: ${e.toString()}');
      }
    }
  }

  // Compartir QR con imagen
  static Future<void> shareQRWithImage({
    required String qrCode,
    required String guestName,
    required String guestDni,
    required BuildContext context,
    bool isInvitation = false,
  }) async {
    try {
      // Crear el mensaje personalizado
      final message = _createShareMessage(guestName, guestDni, qrCode);

      // Generar imagen del QR con logo
      final qrImage = await _generateQRImageWithLogo(qrCode, guestName, isInvitation);

      // Guardar imagen temporalmente
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(qrImage);

      // Compartir con imagen
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
        subject: 'QR Cosmopolitan - $guestName',
        sharePositionOrigin: _shareOrigin(context),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Error al compartir: ${e.toString()}');
      }
    }
  }

  // Compartir directamente con imagen
  static Future<void> showShareOptions({
    required String qrCode,
    required String guestName,
    required String guestDni,
    required BuildContext context,
    bool isInvitation = false,
  }) async {
    await shareQRWithImage(
      qrCode: qrCode,
      guestName: guestName,
      guestDni: guestDni,
      context: context,
      isInvitation: isInvitation,
    );
  }

  static Rect _shareOrigin(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  // Crear mensaje personalizado para compartir
  static String _createShareMessage(String guestName, String guestDni, String qrCode) {
    return '''
    ''';
  }

      // Generar imagen del QR con diseño vertical y fondo negro
      static Future<Uint8List> _generateQRImageWithLogo(String qrCode, String guestName, bool isInvitation) async {
        try {
          // Validar QR
          final qrValidationResult = QrValidator.validate(
            data: qrCode,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
          );

          if (qrValidationResult.status == QrValidationStatus.valid) {
            final qrCodeData = qrValidationResult.qrCode!;
        
            // Cargar el logo negro desde assets
            ui.Image? logoImage;
            try {
              final logoBytes = await rootBundle.load('assets/images/logo-black.png');
              logoImage = await decodeImageFromList(logoBytes.buffer.asUint8List());
            } catch (e) {
              log('Error cargando logo: $e');
              // Continuar sin logo si no se puede cargar
            }
        
        // Crear el painter del QR simple
        final qrPainter = QrPainter.withQr(
          qr: qrCodeData,
          color: const Color(0xFFFFFFFF), // QR blanco
          emptyColor: const Color(0xFF000000), // Fondo negro
          gapless: false,
        );

        // Crear imagen completa con diseño vertical
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
            // Dimensiones verticales 16:9 (formato celular)
            const double imageWidth = 400.0;
            const double imageHeight = 711.0; // 16:9 ratio
            const double qrSize = 300.0;
            const double logoHeight = 80.0;
        
        // Fondo negro
        final backgroundPaint = Paint()..color = Colors.black;
        canvas.drawRect(const Rect.fromLTWH(0, 0, imageWidth, imageHeight), backgroundPaint);

        // Dibujar logo arriba - 80% del ancho de la pantalla
        if (logoImage != null) {
          final logoWidth = imageWidth * 0.8; // 80% del ancho de la pantalla
          final logoOffset = Offset(
            (imageWidth - logoWidth) / 2,
            50,
          );
          
          canvas.drawImageRect(
            logoImage,
            Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
            Rect.fromLTWH(logoOffset.dx, logoOffset.dy, logoWidth, logoHeight),
            Paint(),
          );
        }

        // Dibujar texto "FREE PASS" o "INVITACION ESPECIAL" debajo del logo
        final passText = isInvitation ? 'INVITACION ESPECIAL' : 'FREE PASS';
        final passTextSize = isInvitation ? 20.0 : 24.0; // Tamaño más pequeño para invitación
        final freePassTextPainter = TextPainter(
          text: TextSpan(
            text: passText,
            style: TextStyle(
              color: Colors.white,
              fontSize: passTextSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        freePassTextPainter.layout();
        freePassTextPainter.paint(
          canvas,
          Offset(
            (imageWidth - freePassTextPainter.width) / 2,
            50 + logoHeight + 20, // Debajo del logo con margen
          ),
        );

        // Dibujar QR en el centro
        final qrOffset = const Offset(
          (imageWidth - qrSize) / 2,
          (imageHeight - qrSize) / 2,
        );
        canvas.save();
        canvas.translate(qrOffset.dx, qrOffset.dy);
        qrPainter.paint(canvas, const Size(qrSize, qrSize));
        canvas.restore();

        // Texto abajo
        final instructionTextPainter = TextPainter(
          text: const TextSpan(
            text: 'ESCANEA ESTE QR EN LA ENTRADA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        instructionTextPainter.layout();
        instructionTextPainter.paint(
          canvas,
          Offset(
            (imageWidth - instructionTextPainter.width) / 2,
            imageHeight - 80,
          ),
        );
        
        // Convertir a imagen final
        final picture = recorder.endRecording();
        final image = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        return byteData!.buffer.asUint8List();
          } else {
            throw Exception('QR code validation failed');
          }
        } catch (e) {
          // Fallback: generar QR simple si hay error
          return await _generateQRImageFallback(qrCode);
        }
      }

  // Generar imagen QR sin logo como fallback
  static Future<Uint8List> _generateQRImageFallback(String qrCode) async {
    final qrValidationResult = QrValidator.validate(
      data: qrCode,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCodeData = qrValidationResult.qrCode!;
      final qrPainter = QrPainter.withQr(
        qr: qrCodeData,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      const double imageHeight = 350.0;
      const double imageWidth = 300.0;
      
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, imageWidth, imageHeight), backgroundPaint);
      
      qrPainter.paint(canvas, const Size(imageWidth, imageWidth));
      
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Escanea este código en la entrada',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset((imageWidth - textPainter.width) / 2, 320));
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData!.buffer.asUint8List();
    } else {
      throw Exception('QR code validation failed');
    }
  }
}