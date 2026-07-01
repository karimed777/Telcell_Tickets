import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../services/tickets_api.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/language_pill.dart';

/// Каталог — точный стиль Telcell Wallet:
/// • Белый фон
/// • Шапка: имя + стрелка-аккаунт | иконка уведомлений + поиск
/// • Баннеры горизонтального скролла (indigo / orange)
/// • Горизонтальный скролл категорий событий
/// • Секции «Услуги» / «Ближайшие события»
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  EventCategory _selected = EventCategory.all;
  late Future<List<Event>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = Api.instance.fetchEvents(category: _selected.key);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ── Шапка (белая, как в Wallet) ───────────────────────────
            SliverToBoxAdapter(child: _WalletHeader(t: t)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Фирменные цветные плитки-категории (стиль Telcell) ────
            SliverToBoxAdapter(child: _CategoryTiles(
              selected: _selected,
              onSelect: (c) => setState(() { _selected = c; _reload(); }),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Секция «Ближайшие события» ────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: t.upcoming,
                onSeeAll: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Список событий ────────────────────────────────────────
            FutureBuilder<List<Event>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.orange, strokeWidth: 2.5),
                      ),
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EventCard(event: list[i]),
                      ),
                      childCount: list.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Шапка Wallet-стиля ───────────────────────────────────────────────────

class _WalletHeader extends StatelessWidget {
  final AppStrings t;
  const _WalletHeader({required this.t});

  /// Имя вошедшего пользователя; для гостя или пустого имени — «Гость».
  String _displayName(AppStrings t) {
    final name = AppSession.instance.name?.trim();
    return (name == null || name.isEmpty) ? t.guest : name;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            // Аватар + имя + стрелка
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _displayName(t),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_right_rounded,
                            size: 18, color: AppColors.inkSecondary),
                      ],
                    ),
                    Text(
                      t.city,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Смена языка РУС ⇄ ՀԱՅ
            const LanguagePill(),
            const SizedBox(width: 8),
            // Иконки справа
            _HeaderIcon(Icons.notifications_outlined),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppColors.inkPrimary),
    );
  }
}

// ─── Фирменные цветные плитки-категории (стиль Telcell Wallet) ────────────

class _CategoryTiles extends StatelessWidget {
  final EventCategory selected;
  final ValueChanged<EventCategory> onSelect;
  const _CategoryTiles({required this.selected, required this.onSelect});

  /// Градиент на каждую категорию — те самые насыщенные карточки из Wallet.
  static const _gradients = <List<Color>>[
    [Color(0xFF361268), Color(0xFF6B3FA0)], // all — indigo
    [Color(0xFF1F6FB2), Color(0xFF3B9AE1)], // concert — blue
    [Color(0xFF0E7C7B), Color(0xFF16A8A6)], // theatre — teal
    [Color(0xFFB0203C), Color(0xFFE0476A)], // festival — red
    [Color(0xFF2E2A6B), Color(0xFF4B46A8)], // conference — navy
    [Color(0xFF8A5A00), Color(0xFFC79114)], // exhibition — gold
  ];

  @override
  Widget build(BuildContext context) {
    // Показываем все категории
    final cats = EventCategory.values;
    final t = AppLocale.stringsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(title: t.categoriesTitle, onSeeAll: null),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: cats.length,
            itemBuilder: (ctx, i) {
              final cat = cats[i];
              final active = cat == selected;
              final gradient = _gradients[i % _gradients.length];
              return GestureDetector(
                onTap: () => onSelect(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: active
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last
                            .withOpacity(active ? 0.45 : 0.25),
                        blurRadius: active ? 16 : 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, size: 19, color: Colors.white),
                      ),
                      Text(
                        t.category(cat.key),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Секция-заголовок ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                AppLocale.stringsOf(context).seeAll,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Пустой стейт ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.inkSecondary),
          const SizedBox(height: 12),
          Text(t.notFound,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                color: AppColors.inkSecondary,
              )),
        ],
      ),
    );
  }
}
