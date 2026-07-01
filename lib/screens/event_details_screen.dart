import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/event_cover.dart';
import '../widgets/language_pill.dart';
import '../widgets/purchase_widgets.dart';
import 'checkout_screen.dart';

/// Экран события — стиль Telcell Wallet.
/// Здесь же, под описанием, покупатель выбирает тип билета и количество,
/// а затем переходит к оплате (CheckoutScreen).
class EventDetailsScreen extends StatefulWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final Map<String, int> _qty = {};

  Event get event => widget.event;

  @override
  void initState() {
    super.initState();
    for (final tt in event.ticketTypes) {
      _qty[tt.name] = 0;
    }
  }

  int get _total {
    int sum = 0;
    for (final tt in event.ticketTypes) {
      sum += tt.price * (_qty[tt.name] ?? 0);
    }
    return sum;
  }

  int get _count => _qty.values.fold(0, (a, b) => a + b);

  void _goToPayment() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckoutScreen(event: event, quantities: Map.from(_qty)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final isAm = AppLocale.of(context).language == AppLanguage.am;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.background,
              systemOverlayStyle: darkBgOverlay,
              leading: _CircleBackBtn(),
              actions: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(child: LanguagePill()),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CircleIconBtn(Icons.share_outlined),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventCover(event: event, iconSize: 50),
                    // Низ-фейд
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background,
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Категория
                    Positioned(
                      bottom: 16, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.category(event.category.key),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(event.getTitle(isAm),
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  // Мета-чипы
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _MetaChip(Icons.schedule_outlined, event.dateLabel),
                      _MetaChip(Icons.place_outlined,
                          '${event.getVenue(isAm)}, ${event.city}'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Описание
                  Text(t.aboutEvent,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(event.getDescription(isAm),
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 22),
                  // Выбор билетов (тип/место + количество)
                  Text(t.selectTickets,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final tt in event.ticketTypes) ...[
                    TicketCounter(
                      tt: tt,
                      qty: _qty[tt.name] ?? 0,
                      onChange: (v) => setState(() => _qty[tt.name] = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BuyBar(
          total: _total,
          count: _count,
          fromLabel: event.priceLabel,
          onPay: _total > 0 ? _goToPayment : null,
        ),
      ),
    );
  }
}

class _CircleBackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  const _CircleIconBtn(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.inkSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkPrimary,
              )),
        ],
      ),
    );
  }
}

/// Нижняя панель: сумма выбранного + переход к оплате.
class _BuyBar extends StatelessWidget {
  final int total;
  final int count;
  final String fromLabel;
  final VoidCallback? onPay;
  const _BuyBar({
    required this.total,
    required this.count,
    required this.fromLabel,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final enabled = onPay != null;
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(enabled ? '$count · ${t.total.toLowerCase()}' : t.priceFrom,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: AppColors.inkSecondary,
                  )),
              Text(enabled ? '${money(total)} ֏' : fromLabel,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      enabled ? AppColors.orange : AppColors.surfaceGray,
                ),
                child: Text(
                  enabled ? t.proceedToPay : t.selectTickets,
                  style: TextStyle(
                    color: enabled ? Colors.white : AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
