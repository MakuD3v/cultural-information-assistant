import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MekongIllustration extends StatelessWidget {
  final double height;
  final bool showSunAndBoat;

  const MekongIllustration({
    Key? key,
    this.height = 140,
    this.showSunAndBoat = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: MekongPainter(showSunAndBoat: showSunAndBoat),
      ),
    );
  }
}

class MekongPainter extends CustomPainter {
  final bool showSunAndBoat;

  MekongPainter({required this.showSunAndBoat});

  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    final skyPaint = Paint()..color = const Color(0xFFF7E8C8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    if (showSunAndBoat) {
      // Golden Sun
      final sunPaint = Paint()..color = MekongColors.mustard;
      canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), size.height * 0.22, sunPaint);

      // Green landscape band
      final landPaint = Paint()..color = const Color(0xFF869E7B);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.1), landPaint);

      // River Hau
      final riverPaint = Paint()..color = MekongColors.deltaBlue;
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38), riverPaint);

      // Palm / Foliage tree on the left
      final foliagePaint = Paint()..color = MekongColors.riverGreen;
      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.48), 24, foliagePaint);
      canvas.drawCircle(Offset(size.width * 0.23, size.height * 0.52), 18, foliagePaint);
      canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.50), 22, foliagePaint);

      // River wave lines
      final wavePaint = Paint()
        ..color = const Color(0xFFB0CDDE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path1 = Path();
      path1.moveTo(0, size.height * 0.72);
      path1.quadraticBezierTo(size.width * 0.25, size.height * 0.69, size.width * 0.5, size.height * 0.73);
      path1.quadraticBezierTo(size.width * 0.75, size.height * 0.76, size.width, size.height * 0.71);
      canvas.drawPath(path1, wavePaint);

      // Wooden Boat 1 (Left)
      final boatPaint = Paint()..color = const Color(0xFF8D532F);
      final boatPath = Path();
      boatPath.moveTo(size.width * 0.08, size.height * 0.80);
      boatPath.lineTo(size.width * 0.36, size.height * 0.80);
      boatPath.lineTo(size.width * 0.32, size.height * 0.94);
      boatPath.lineTo(size.width * 0.12, size.height * 0.94);
      boatPath.close();
      canvas.drawPath(boatPath, boatPaint);

      // Awning (Red & White striped)
      final awningPaint = Paint()..color = MekongColors.clay;
      canvas.drawRect(Rect.fromLTWH(size.width * 0.10, size.height * 0.62, size.width * 0.24, size.height * 0.14), awningPaint);
      final stripePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(size.width * 0.17, size.height * 0.62, size.width * 0.05, size.height * 0.14), stripePaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.26, size.height * 0.62, size.width * 0.05, size.height * 0.14), stripePaint);

      // Boat 2 (Right - Vendor with Conical Hat & Beo pole)
      final boat2Path = Path();
      boat2Path.moveTo(size.width * 0.52, size.height * 0.84);
      boat2Path.lineTo(size.width * 0.92, size.height * 0.84);
      boat2Path.lineTo(size.width * 0.84, size.height * 0.96);
      boat2Path.lineTo(size.width * 0.58, size.height * 0.96);
      boat2Path.close();
      canvas.drawPath(boat2Path, boatPaint);

      // Beo Pole
      final polePaint = Paint()
        ..color = const Color(0xFF5A3821)
        ..strokeWidth = 3;
      canvas.drawLine(Offset(size.width * 0.60, size.height * 0.84), Offset(size.width * 0.60, size.height * 0.40), polePaint);
      canvas.drawLine(Offset(size.width * 0.54, size.height * 0.42), Offset(size.width * 0.66, size.height * 0.42), polePaint);
      // Produce hanging
      canvas.drawCircle(Offset(size.width * 0.54, size.height * 0.50), 6, Paint()..color = MekongColors.mustard);
      canvas.drawCircle(Offset(size.width * 0.66, size.height * 0.52), 6, Paint()..color = MekongColors.clay);

      // Figure with Conical Hat (Nón Lá)
      final bodyPaint = Paint()..color = MekongColors.clay;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.72, 14, 20), const Radius.circular(6)), bodyPaint);
      // Head
      canvas.drawCircle(Offset(size.width * 0.75 + 7, size.height * 0.70), 5, Paint()..color = const Color(0xFFD49E78));
      // Conical hat
      final hatPaint = Paint()..color = MekongColors.straw;
      final hatPath = Path();
      hatPath.moveTo(size.width * 0.75 + 7, size.height * 0.56);
      hatPath.lineTo(size.width * 0.75 - 7, size.height * 0.68);
      hatPath.lineTo(size.width * 0.75 + 21, size.height * 0.68);
      hatPath.close();
      canvas.drawPath(hatPath, hatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
