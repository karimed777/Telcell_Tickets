import 'package:flutter/material.dart';
import '../models/event.dart';
import 'brand_shapes.dart';

/// Обложка-заглушка: градиент + декоративные круги + иконка категории.
class EventCover extends StatelessWidget {
  final Event event;
  final double iconSize;
  const EventCover({super.key, required this.event, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Подложка: фирменный градиент. Виден, пока грузится фото
        // и если фото недоступно.
        EventCoverGradient(color: event.cover),

        // Декоративные круги — добавляют глубину, как на афишах
        Positioned(
          right: -18,
          top: -18,
          child: _circle(54, Colors.white.withOpacity(0.10)),
        ),
        Positioned(
          left: -10,
          bottom: -22,
          child: _circle(64, Colors.white.withOpacity(0.06)),
        ),

        // Иконка категории — поверх градиента, под фото.
        if (iconSize > 0)
          Center(
            child: Icon(
              event.category.icon,
              size: iconSize,
              color: Colors.white.withOpacity(0.92),
            ),
          ),

        // Реальное фото события. Накрывает градиент/иконку, когда загрузилось.
        // Пока грузится или при ошибке — остаётся прозрачным (виден градиент).
        if (event.imageUrl != null)
          Positioned.fill(
            child: Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (ctx, child, progress) =>
                  progress == null ? child : const SizedBox.expand(),
              errorBuilder: (ctx, error, stack) => const SizedBox.expand(),
            ),
          ),
      ],
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
