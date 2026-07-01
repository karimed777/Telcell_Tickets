import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/event.dart';
import '../services/tickets_api.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';

/// Экран поиска и фильтров — как в Яндекс Афише.
/// Строка поиска + чипы категорий + быстрые фильтры даты, живой результат.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _DateFilter { any, today, weekend, month }

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  EventCategory _category = EventCategory.all;
  _DateFilter _date = _DateFilter.any;
  String _query = '';
  late Future<List<Event>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    _future = Api.instance.fetchEvents(category: _category.key, query: _query);
  }

  bool _matchesDate(Event e) {
    final now = DateTime.now();
    switch (_date) {
      case _DateFilter.any:
        return true;
      case _DateFilter.today:
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      case _DateFilter.weekend:
        final wd = e.date.weekday;
        return wd == DateTime.saturday || wd == DateTime.sunday;
      case _DateFilter.month:
        return e.date.year == now.year && e.date.month == now.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Поисковая строка
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() {
                    _query = v;
                    _reload();
                  }),
                  decoration: InputDecoration(
                    hintText: 'События, артисты, площадки…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.inkSecondary),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.inkSecondary),
                            onPressed: () => setState(() {
                              _controller.clear();
                              _query = '';
                              _reload();
                            }),
                          ),
                  ),
                ),
              ),

              // Чипы категорий
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: EventCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final c = EventCategory.values[i];
                    final active = c == _category;
                    return ChoiceChip(
                      selected: active,
                      label: Text(c.label),
                      onSelected: (_) => setState(() {
                        _category = c;
                        _reload();
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Быстрые фильтры даты
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _dateChip('Любая дата', _DateFilter.any),
                    _dateChip('Сегодня', _DateFilter.today),
                    _dateChip('Выходные', _DateFilter.weekend),
                    _dateChip('В этом месяце', _DateFilter.month),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.divider),

              // Результаты
              Expanded(
                child: FutureBuilder<List<Event>>(
                  future: _future,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.orange, strokeWidth: 2.5),
                      );
                    }
                    final list =
                        (snap.data ?? []).where(_matchesDate).toList();
                    if (list.isEmpty) return const _NoResults();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (c, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Найдено: ${list.length}',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          );
                        }
                        return EventCard(event: list[i - 1]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(String label, _DateFilter f) {
    final active = _date == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        label: Text(label),
        onSelected: (_) => setState(() => _date = f),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 38, color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Ничего не нашлось',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            const Text('Измените запрос или сбросьте фильтры',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.inkSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
