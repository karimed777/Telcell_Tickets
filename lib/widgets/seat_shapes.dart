import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ══════════════════════════════════════════════════════════════════════════
///  SeatShapes — рисованные «модельки» кресел (CustomPaint).
///
///  Виды соответствуют enum SeatType на backend (общий с админ-панелью):
///    Standard · VIP · Sofa · Standing · Disabled
///
///  Использование:
///    SeatShape(kind: SeatKind.vip, size: 44)
///    SeatShape.forTicketName('Фан-зона')   // эвристика по названию типа
///    SeatTypeBadge(kind: SeatKind.sofa)    // иконка в цветной подложке
/// ══════════════════════════════════════════════════════════════════════════

/// Вид кресла — зеркало backend-enum `SeatType`.
enum SeatKind { standard, vip, sofa, standing, disabled }

extension SeatKindX on SeatKind {
  /// Фирменный акцентный цвет вида кресла.
  Color get accent {
    switch (this) {
      case SeatKind.standard:
        return AppColors.indigo;
      case SeatKind.vip:
        return const Color(0xFFC9930A); // золото
      case SeatKind.sofa:
        return AppColors.orange;
      case SeatKind.standing:
        return AppColors.cyan;
      case SeatKind.disabled:
        return const Color(0xFF2E7CF6); // доступная среда — синий
    }
  }

  /// Пастельная подложка под иконку.
  Color get accentSoft {
    switch (this) {
      case SeatKind.standard:
        return AppColors.indigoLight;
      case SeatKind.vip:
        return const Color(0xFFFFF6DE);
      case SeatKind.sofa:
        return AppColors.orangeLight;
      case SeatKind.standing:
        return const Color(0xFFE2F9FF);
      case SeatKind.disabled:
        return const Color(0xFFE8F1FF);
    }
  }
}

/// Определяет вид кресла по названию типа билета («VIP», «Фан-зона», …).
SeatKind seatKindForTicketName(String name) {
  final n = name.toLowerCase();
  if (n.contains('vip')) return SeatKind.vip;
  if (n.contains('диван') || n.contains('ложа') || n.contains('sofa') ||
      n.contains('բազմոց')) {
    return SeatKind.sofa;
  }
  if (n.contains('фан') || n.contains('танц') || n.contains('стоя') ||
      n.contains('standing') || n.contains('ֆան') || n.contains('պարա')) {
    return SeatKind.standing;
  }
  if (n.contains('инвалид') || n.contains('доступ') || n.contains('disabled')) {
    return SeatKind.disabled;
  }
  return SeatKind.standard;
}

/// Рисованное кресло. [color] переопределяет фирменный цвет вида
/// (нужно для схемы зала: выбрано/продано/свободно).
class SeatShape extends StatelessWidget {
  final SeatKind kind;
  final double size;
  final Color? color;

  const SeatShape({
    super.key,
    required this.kind,
    this.size = 40,
    this.color,
  });

  /// Кресло по названию типа билета.
  factory SeatShape.forTicketName(String name, {double size = 40, Color? color}) =>
      SeatShape(kind: seatKindForTicketName(name), size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final c = color ?? kind.accent;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _painterFor(kind, c)),
    );
  }

  static CustomPainter _painterFor(SeatKind kind, Color c) {
    switch (kind) {
      case SeatKind.standard:
        return _StandardSeatPainter(c);
      case SeatKind.vip:
        return _VipSeatPainter(c);
      case SeatKind.sofa:
        return _SofaPainter(c);
      case SeatKind.standing:
        return _StandingPainter(c);
      case SeatKind.disabled:
        return _DisabledPainter(c);
    }
  }
}

/// Кресло на цветной пастельной подложке — для списков и легенд.
class SeatTypeBadge extends StatelessWidget {
  final SeatKind kind;
  final double size;

  const SeatTypeBadge({super.key, required this.kind, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kind.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(child: SeatShape(kind: kind, size: size * 0.62)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Painters
// ─────────────────────────────────────────────────────────────────────────

Paint _fill(Color c) => Paint()
  ..color = c
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

/// СТАНДАРТ — классическое кресло анфас: спинка, сиденье, подлокотники, ножки.
class _StandardSeatPainter extends CustomPainter {
  final Color c;
  _StandardSeatPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = _fill(c);
    final pSoft = _fill(c.withOpacity(0.45));

    // Спинка
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.06, w * 0.52, h * 0.52),
        Radius.circular(w * 0.13),
      ),
      p,
    );
    // Подушка сиденья
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.52, w * 0.64, h * 0.22),
        Radius.circular(w * 0.09),
      ),
      p,
    );
    // Подлокотники
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.38, w * 0.14, h * 0.36),
        Radius.circular(w * 0.07),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.80, h * 0.38, w * 0.14, h * 0.36),
        Radius.circular(w * 0.07),
      ),
      pSoft,
    );
    // Ножки
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.78, w * 0.10, h * 0.16),
        Radius.circular(w * 0.05),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.78, w * 0.10, h * 0.16),
        Radius.circular(w * 0.05),
      ),
      pSoft,
    );
  }

  @override
  bool shouldRepaint(covariant _StandardSeatPainter old) => old.c != c;
}

/// VIP — мягкое кресло с «каретной» стяжкой и короной сверху.
class _VipSeatPainter extends CustomPainter {
  final Color c;
  _VipSeatPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = _fill(c);
    final pSoft = _fill(c.withOpacity(0.45));
    final pDot = _fill(Colors.white.withOpacity(0.85));

    // Корона (три зубца)
    final crown = Path()
      ..moveTo(w * 0.32, h * 0.16)
      ..lineTo(w * 0.36, h * 0.04)
      ..lineTo(w * 0.44, h * 0.12)
      ..lineTo(w * 0.50, h * 0.01)
      ..lineTo(w * 0.56, h * 0.12)
      ..lineTo(w * 0.64, h * 0.04)
      ..lineTo(w * 0.68, h * 0.16)
      ..close();
    canvas.drawPath(crown, p);

    // Спинка (шире и выше стандартной)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.20, w * 0.60, h * 0.44),
        Radius.circular(w * 0.15),
      ),
      p,
    );
    // Стяжка — 3 «пуговицы»
    final r = w * 0.028;
    canvas.drawCircle(Offset(w * 0.36, h * 0.40), r, pDot);
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), r, pDot);
    canvas.drawCircle(Offset(w * 0.64, h * 0.40), r, pDot);

    // Сиденье
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.58, w * 0.72, h * 0.22),
        Radius.circular(w * 0.10),
      ),
      p,
    );
    // Подлокотники
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.02, h * 0.44, w * 0.14, h * 0.36),
        Radius.circular(w * 0.07),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.84, h * 0.44, w * 0.14, h * 0.36),
        Radius.circular(w * 0.07),
      ),
      pSoft,
    );
    // Ножки
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.84, w * 0.10, h * 0.13),
        Radius.circular(w * 0.05),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.68, h * 0.84, w * 0.10, h * 0.13),
        Radius.circular(w * 0.05),
      ),
      pSoft,
    );
  }

  @override
  bool shouldRepaint(covariant _VipSeatPainter old) => old.c != c;
}

/// ДИВАН — широкий двухместный: общая спинка, две подушки, подлокотники.
class _SofaPainter extends CustomPainter {
  final Color c;
  _SofaPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = _fill(c);
    final pSoft = _fill(c.withOpacity(0.45));

    // Спинка во всю ширину
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.16, w * 0.80, h * 0.40),
        Radius.circular(w * 0.11),
      ),
      p,
    );
    // Две подушки сиденья
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.13, h * 0.52, w * 0.355, h * 0.22),
        Radius.circular(w * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.515, h * 0.52, w * 0.355, h * 0.22),
        Radius.circular(w * 0.08),
      ),
      p,
    );
    // Подлокотники
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.36, w * 0.12, h * 0.38),
        Radius.circular(w * 0.06),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.88, h * 0.36, w * 0.12, h * 0.38),
        Radius.circular(w * 0.06),
      ),
      pSoft,
    );
    // Ножки
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.78, w * 0.09, h * 0.15),
        Radius.circular(w * 0.045),
      ),
      pSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.75, h * 0.78, w * 0.09, h * 0.15),
        Radius.circular(w * 0.045),
      ),
      pSoft,
    );
  }

  @override
  bool shouldRepaint(covariant _SofaPainter old) => old.c != c;
}

/// СТОЯЧЕЕ МЕСТО — силуэт человека + «волны» звука вокруг (фан-зона).
class _StandingPainter extends CustomPainter {
  final Color c;
  _StandingPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = _fill(c);
    final pSoft = Paint()
      ..color = c.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Голова
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.13, p);
    // Тело (плечи → талия, скруглённая трапеция)
    final body = Path()
      ..moveTo(w * 0.34, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.30, w * 0.66, h * 0.36)
      ..lineTo(w * 0.62, h * 0.66)
      ..quadraticBezierTo(w * 0.50, h * 0.70, w * 0.38, h * 0.66)
      ..close();
    canvas.drawPath(body, p);
    // Ноги
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.66, w * 0.075, h * 0.28),
        Radius.circular(w * 0.04),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.525, h * 0.66, w * 0.075, h * 0.28),
        Radius.circular(w * 0.04),
      ),
      p,
    );
    // Волны звука слева и справа
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.50, h * 0.40), radius: w * 0.36),
      math.pi * 0.80, math.pi * 0.40, false, pSoft,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.50, h * 0.40), radius: w * 0.36),
      -math.pi * 0.20, math.pi * 0.40, false, pSoft,
    );
  }

  @override
  bool shouldRepaint(covariant _StandingPainter old) => old.c != c;
}

/// ДОСТУПНОЕ МЕСТО — символ кресла-коляски (упрощённый ISA-знак).
class _DisabledPainter extends CustomPainter {
  final Color c;
  _DisabledPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = _fill(c);
    final stroke = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Голова
    canvas.drawCircle(Offset(w * 0.42, h * 0.14), w * 0.105, p);

    // Корпус: спина вниз + сиденье вперёд
    final torso = Path()
      ..moveTo(w * 0.40, h * 0.26)
      ..lineTo(w * 0.40, h * 0.52)
      ..lineTo(w * 0.68, h * 0.52);
    canvas.drawPath(torso, stroke);
    // Рука, вытянутая вперёд
    canvas.drawLine(
        Offset(w * 0.42, h * 0.34), Offset(w * 0.64, h * 0.34), stroke);
    // Нога вниз от сиденья
    canvas.drawLine(
        Offset(w * 0.68, h * 0.52), Offset(w * 0.72, h * 0.70), stroke);

    // Большое колесо (дуга ~270°)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.42, h * 0.62), radius: w * 0.28),
      math.pi * 0.15, math.pi * 1.7, false, stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DisabledPainter old) => old.c != c;
}
