// lib/screens/scan_qr/widgets/scanner_overlay.dart
// Widget puro para el overlay del scanner con instrucciones
// NO contiene lógica de negocio - solo recibe datos por constructor

import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

/// Instrucciones que aparecen debajo del área de escaneo
class ScannerInstructions extends StatelessWidget {
  const ScannerInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Enfocá el código QR',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Se escaneará automáticamente',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shape personalizado para el overlay del scanner QR
/// Crea un recorte cuadrado con bordes redondeados y esquinas decorativas
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    Path getRightTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right - borderRadius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + borderRadius)
        ..lineTo(rect.right, rect.bottom);
    }

    Path getRightBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - borderRadius)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right - borderRadius, rect.bottom)
        ..lineTo(rect.left, rect.bottom);
    }

    Path getLeftBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.left + borderRadius, rect.bottom)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - borderRadius)
        ..lineTo(rect.left, rect.top);
    }

    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutSizeWithOffset = cutOutSize + borderOffset;

    final cutOutRect = Rect.fromLTWH(
      rect.left + borderWidthSize - (cutOutSizeWithOffset / 2),
      rect.top + (height / 2) - (cutOutSizeWithOffset / 2),
      cutOutSizeWithOffset,
      cutOutSizeWithOffset,
    );

    final topLeftRect = Rect.fromLTRB(
      cutOutRect.left,
      cutOutRect.top,
      cutOutRect.left + borderLength,
      cutOutRect.top + borderLength,
    );

    final topRightRect = Rect.fromLTRB(
      cutOutRect.right - borderLength,
      cutOutRect.top,
      cutOutRect.right,
      cutOutRect.top + borderLength,
    );

    final bottomLeftRect = Rect.fromLTRB(
      cutOutRect.left,
      cutOutRect.bottom - borderLength,
      cutOutRect.left + borderLength,
      cutOutRect.bottom,
    );

    final bottomRightRect = Rect.fromLTRB(
      cutOutRect.right - borderLength,
      cutOutRect.bottom - borderLength,
      cutOutRect.right,
      cutOutRect.bottom,
    );

    final innerCutOutRect = Rect.fromLTWH(
      cutOutRect.left + borderOffset,
      cutOutRect.top + borderOffset,
      cutOutRect.width - borderOffset * 2,
      cutOutRect.height - borderOffset * 2,
    );

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()
        ..addRRect(RRect.fromRectAndRadius(innerCutOutRect, Radius.circular(borderRadius)))
        ..addPath(getLeftTopPath(topLeftRect), Offset.zero)
        ..addPath(getRightTopPath(topRightRect), Offset.zero)
        ..addPath(getRightBottomPath(bottomRightRect), Offset.zero)
        ..addPath(getLeftBottomPath(bottomLeftRect), Offset.zero),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutSizeWithOffset = cutOutSize + borderOffset;

    final cutOutRect = Rect.fromLTWH(
      rect.left + borderWidthSize - (cutOutSizeWithOffset / 2),
      rect.top + (height / 2) - (cutOutSizeWithOffset / 2),
      cutOutSizeWithOffset,
      cutOutSizeWithOffset,
    );

    final topLeftRect = Rect.fromLTRB(
      cutOutRect.left,
      cutOutRect.top,
      cutOutRect.left + borderLength,
      cutOutRect.top + borderLength,
    );

    final topRightRect = Rect.fromLTRB(
      cutOutRect.right - borderLength,
      cutOutRect.top,
      cutOutRect.right,
      cutOutRect.top + borderLength,
    );

    final bottomLeftRect = Rect.fromLTRB(
      cutOutRect.left,
      cutOutRect.bottom - borderLength,
      cutOutRect.left + borderLength,
      cutOutRect.bottom,
    );

    final bottomRightRect = Rect.fromLTRB(
      cutOutRect.right - borderLength,
      cutOutRect.bottom - borderLength,
      cutOutRect.right,
      cutOutRect.bottom,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(topLeftRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(topRightRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(bottomLeftRect, Radius.circular(borderRadius)))
      ..addRRect(RRect.fromRectAndRadius(bottomRightRect, Radius.circular(borderRadius)));

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
