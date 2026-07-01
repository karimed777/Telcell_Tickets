import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'catalog_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'my_tickets_screen.dart';

/// HomeShell — белый фон, оранжевый активный таб с подчёркиванием.
/// Точно как в Telcell Wallet (скриншот).
class HomeShell extends StatefulWidget {
  /// Вкладка, открытая при старте: 0 — Главная, 3 — Билеты.
  final int initialTab;
  const HomeShell({super.key, this.initialTab = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialTab;

  // Меняется при каждом открытии вкладки «Билеты», чтобы экран
  // перечитал список и показал только что купленные билеты.
  int _ticketsNonce = 0;

  void _onTap(int i) {
    setState(() {
      if (i == 3 && i != _index) _ticketsNonce++;
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final screens = [
      const CatalogScreen(),
      const SearchScreen(),
      const MapScreen(),
      MyTicketsScreen(key: ValueKey('tickets_$_ticketsNonce')),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: _WalletNavBar(
          currentIndex: _index,
          onTap: _onTap,
          items: [
            _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,               label: t.navHome),
            _NavItem(icon: Icons.search_outlined,     activeIcon: Icons.search_rounded,             label: t.navSearch),
            _NavItem(icon: Icons.map_outlined,        activeIcon: Icons.map_rounded,                label: t.navMap),
            _NavItem(icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number_rounded, label: t.navTickets),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Нижняя навигация — белый фон, оранжевый активный + верхняя orange-линия.
/// 1:1 с Telcell Wallet.
class _WalletNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _WalletNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item   = items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Оранжевая линия сверху — только у активного
                      Container(
                        height: 2,
                        width: active ? 32 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 22,
                        color: active
                            ? AppColors.orange
                            : AppColors.inkSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.orange
                              : AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

