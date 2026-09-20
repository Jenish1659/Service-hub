import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShLogoWidget extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const ShLogoWidget({
    super.key,
    this.size = 90,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Circle Aura
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // SH Emblem Container
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: Size(size * 0.6, size * 0.6),
                  painter: _ShLogoPainter(),
                ),
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'SERVICE ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavy,
                    letterSpacing: 1.5,
                  ),
                ),
                TextSpan(
                  text: 'HUB',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 1.5, color: AppColors.accentGold),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'MULTIPLE SERVICES, ONE TRUST',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Container(width: 16, height: 1.5, color: AppColors.accentGold),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navyPaint = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    final goldPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;

    // Draw 'S' curve
    final sPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.2)
      ..cubicTo(
        size.width * 0.15, size.height * 0.15,
        size.width * 0.1, size.height * 0.45,
        size.width * 0.35, size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.6, size.height * 0.55,
        size.width * 0.55, size.height * 0.85,
        size.width * 0.25, size.height * 0.8,
      );
    canvas.drawPath(sPath, navyPaint);

    // Draw 'H' vertical bars & wrench tool detail
    final hLeftBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.18, size.width * 0.14, size.height * 0.64),
      const Radius.circular(4),
    );
    final hRightBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.82, size.height * 0.18, size.width * 0.14, size.height * 0.64),
      const Radius.circular(4),
    );
    final hCross = Rect.fromLTWH(size.width * 0.6, size.height * 0.45, size.width * 0.36, size.height * 0.12);

    canvas.drawRRect(hLeftBar, Paint()..color = AppColors.primaryNavy);
    canvas.drawRRect(hRightBar, Paint()..color = AppColors.primaryNavy);
    canvas.drawRect(hCross, Paint()..color = AppColors.primaryNavy);

    // Gold Gear / Tool accent dot
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.2), size.width * 0.08, goldPaint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.8), size.width * 0.07, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
