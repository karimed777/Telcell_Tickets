import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

/// Общие виджеты для шагов покупки (выбор билетов + оплата).
/// Вынесены сюда, чтобы экраны TicketSelection и Checkout не дублировали код.

/// Мини-карточка события (indigo-градиент) — шапка экранов покупки.
class EventMiniCard extends StatelessWidget {
  final Event event;
  const EventMiniCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isAm = AppLocale.of(context).language == AppLanguage.am;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF361268), Color(0xFF4A2080)]),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.category.icon, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.getTitle(isAm),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                const SizedBox(height: 3),
                Text(event.dateLabel,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: AppColors.cyanSoft,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Жирный заголовок-секция.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.inkPrimary,
        ));
  }
}

/// Строка выбора количества билетов одного типа (− qty +).
class TicketCounter extends StatelessWidget {
  final TicketType tt;
  final int qty;
  final ValueChanged<int> onChange;
  const TicketCounter(
      {super.key, required this.tt, required this.qty, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final isAm = AppLocale.of(context).language == AppLanguage.am;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: qty > 0 ? AppColors.orange : AppColors.divider,
            width: qty > 0 ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tt.getName(isAm),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                    )),
                if (tt.note != null)
                  Text(tt.note!,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.inkSecondary,
                      )),
                Text('${money(tt.price)} ֏',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    )),
              ],
            ),
          ),
          Row(
            children: [
              _CounterBtn(
                icon: Icons.remove_rounded,
                enabled: qty > 0,
                onTap: () {
                  if (qty > 0) onChange(qty - 1);
                },
              ),
              SizedBox(
                width: 32,
                child: Text('$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              _CounterBtn(
                icon: Icons.add_rounded,
                enabled: true,
                onTap: () => onChange(qty + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _CounterBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.orange : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : AppColors.inkSecondary, size: 16),
      ),
    );
  }
}
