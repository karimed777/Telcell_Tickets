import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Декоративный фон онбординга (теперь используется только в OnboardingScreen).
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter());
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.indigo);
    _blob(canvas, Offset(size.width * 0.85, size.height * 0.12),
        size.width * 0.55, AppColors.cyan.withOpacity(0.15));
    _blob(canvas, Offset(size.width * 0.15, size.height * 0.50),
        size.width * 0.60, const Color(0xFF6B3FA0).withOpacity(0.25));
    _blob(canvas, Offset(size.width * 0.70, size.height * 0.88),
        size.width * 0.45, AppColors.orange.withOpacity(0.12));
  }

  void _blob(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Логотип «T» — фирменный знак Telcell Tickets.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandPainter()),
    );
  }
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final barH = h * 0.18;
    final stemW = w * 0.22;

    // Горизонтальная перекладина (cyan)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, barH),
          Radius.circular(barH / 2)),
      Paint()..color = AppColors.cyan,
    );
    // Вертикальная стойка (белая)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH((w - stemW) / 2, 0, stemW, h),
          Radius.circular(stemW / 2)),
      Paint()..color = Colors.white,
    );
    // Снова cyan поверх перекладины
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, barH),
          Radius.circular(barH / 2)),
      Paint()..color = AppColors.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Градиентная обложка события.
class EventCoverGradient extends StatelessWidget {
  final Color color;
  const EventCoverGradient({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor();
    final darker  = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, darker],
        ),
      ),
    );
  }
}
