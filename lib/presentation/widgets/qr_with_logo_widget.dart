import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRWithLogoWidget extends StatelessWidget {
  final String qrCode;
  final double size;
  final double logoSize;

  const QRWithLogoWidget({
    super.key,
    required this.qrCode,
    this.size = 200.0,
    this.logoSize = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    // QR simple sin logo
    return QrImageView(
      data: qrCode,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }

}

