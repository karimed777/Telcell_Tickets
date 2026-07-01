import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../services/tickets_api.dart';
import '../theme/app_theme.dart';
import 'event_details_screen.dart';

/// Экран карты событий — «найти на карте», как в Яндекс Афише.
/// Мягкая светлая подложка CARTO Positron (в тон сайту), без политических
/// флагов — это обычная картографическая основа. Метки брендовые (orange).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  late Future<List<Event>> _future;
  Event? _selected;

  // Центр Еревана
  static const _yerevan = LatLng(40.1792, 44.4991);

  @override
  void initState() {
    super.initState();
    _future = Api.instance.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Event>>(
        future: _future,
        builder: (context, snap) {
          final events = snap.data ?? [];
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _yerevan,
                  initialZoom: 12.5,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  // Мягкая светлая подложка — CARTO Positron
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.telcell.tickets',
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  MarkerLayer(
                    markers: [
                      for (final e in events)
                        Marker(
                          point: LatLng(e.lat, e.lng),
                          width: 44,
                          height: 54,
                          alignment: Alignment.topCenter,
                          child: _EventPin(
                            event: e,
                            active: _selected?.id == e.id,
                            onTap: () {
                              setState(() => _selected = e);
                              _mapController.move(LatLng(e.lat, e.lng), 14);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Заголовок
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_rounded,
                            color: AppColors.orange, size: 20),
                        const SizedBox(width: 10),
                        Text('События на карте',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('${events.length}',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.orange, strokeWidth: 2.5),
                ),

              // Карточка выбранного события снизу
              if (_selected != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _MapEventCard(
                    event: _selected!,
                    onClose: () => setState(() => _selected = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EventPin extends StatelessWidget {
  final Event event;
  final bool active;
  final VoidCallback onTap;
  const _EventPin(
      {required this.event, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: active ? 44 : 38,
            height: active ? 44 : 38,
            decoration: BoxDecoration(
              color: active ? AppColors.orange : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              event.category.icon,
              size: 18,
              color: active ? Colors.white : AppColors.orange,
            ),
          ),
          // Острый кончик пина
          Transform.translate(
            offset: const Offset(0, -3),
            child: ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                  width: 10, height: 7, color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size s) => ui.Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width / 2, s.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}

class _MapEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;
  const _MapEventCard({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isAm = AppLocale.of(context).language == AppLanguage.am;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [event.cover, event.cover.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(event.category.icon,
                  color: Colors.white.withOpacity(0.9), size: 30),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event.getTitle(isAm),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('${event.dateLabel} · ${event.getVenue(isAm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.inkSecondary,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(event.priceLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          )),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EventDetailsScreen(event: event),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          foregroundColor: AppColors.orange,
                        ),
                        child: Text(AppLocale.stringsOf(context).buyShort,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.inkSecondary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
