import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../services/tickets_api.dart';
import '../services/notifications.dart';
import '../theme/app_theme.dart';
import '../widgets/purchase_widgets.dart';
import '../widgets/ticket_card.dart';
import 'home_shell.dart';

/// Шаг 2 покупки — оплата. Билеты уже выбраны на TicketSelectionScreen
/// и приходят сюда в [quantities] (имя типа → количество).
class CheckoutScreen extends StatefulWidget {
  final Event event;
  final Map<String, int> quantities;
  const CheckoutScreen({
    super.key,
    required this.event,
    required this.quantities,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.wallet;
  final _promoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Выбранные позиции (тип билета + количество > 0).
  List<TicketType> get _selectedTypes => widget.event.ticketTypes
      .where((tt) => (widget.quantities[tt.name] ?? 0) > 0)
      .toList();

  int _qtyOf(TicketType tt) => widget.quantities[tt.name] ?? 0;

  /// Сумма билетов (без сервисного сбора).
  int get _subtotal {
    int sum = 0;
    for (final tt in widget.event.ticketTypes) {
      sum += tt.price * _qtyOf(tt);
    }
    return sum;
  }

  int get _fee => Fees.bookingFee(_subtotal);
  int get _grandTotal => _subtotal + _fee;

  /// Для Telcell Wallet контакт уже известен из авторизации; для карты
  /// (Guest Checkout) покупатель вводит email и телефон сам.
  bool get _needsContact => _method == PaymentMethod.card;

  bool get _emailValid {
    final v = _emailCtrl.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  }

  bool get _phoneValid => _phoneCtrl.text.trim().length >= 6;

  bool get _contactValid => !_needsContact || (_emailValid && _phoneValid);

  bool get _canPay => _subtotal > 0 && _contactValid;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final tickets = await Api.instance.checkout(
        eventId: widget.event.id,
        quantities: Map.from(widget.quantities),
        method: _method,
        promoCode: _promoCtrl.text.trim().isEmpty
            ? null
            : _promoCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      // Локальное уведомление об успешной покупке.
      final t = AppLocale.stringsOf(context);
      AppNotifications.instance.purchaseSuccess(
        eventTitle: widget.event.title,
        ticketCount: tickets.length,
        title: t.pushBuyTitle,
        bodyBuilder: t.pushBuyBody,
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            _SuccessScreen(tickets: tickets, event: widget.event),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(t.checkout),
          leading: const BackButton(),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Карточка события
            EventMiniCard(event: widget.event),
            const SizedBox(height: 20),

            // Сводка заказа (что выбрали на прошлом шаге)
            SectionLabel(t.yourOrder),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  for (final tt in _selectedTypes)
                    _OrderLine(
                      name: '${tt.name} × ${_qtyOf(tt)}',
                      amount: tt.price * _qtyOf(tt),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Промокод
            SectionLabel(t.promoCode),
            const SizedBox(height: 8),
            TextField(
              controller: _promoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: t.promoHint,
                suffixIcon: const Icon(Icons.local_offer_rounded,
                    color: AppColors.orange, size: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Способ оплаты
            SectionLabel(t.paymentMethod),
            const SizedBox(height: 8),
            _PayOption(
              icon: Icons.account_balance_wallet_rounded,
              title: t.payWallet,
              subtitle: t.payWalletSub,
              selected: _method == PaymentMethod.wallet,
              onTap: () => setState(() => _method = PaymentMethod.wallet),
              color: AppColors.indigo,
            ),
            const SizedBox(height: 8),
            _PayOption(
              icon: Icons.credit_card_rounded,
              title: t.payCard,
              subtitle: t.payCardSub,
              selected: _method == PaymentMethod.card,
              onTap: () => setState(() => _method = PaymentMethod.card),
              color: AppColors.orange,
            ),
            const SizedBox(height: 20),

            // Контакт покупателя (Guest Checkout для карты, Wallet — из аккаунта)
            SectionLabel(t.contactTitle),
            const SizedBox(height: 8),
            if (_needsContact) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.emailHint,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                  errorText: _emailCtrl.text.isNotEmpty && !_emailValid
                      ? t.errEmail
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.phoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 6),
              Text(t.contactNote,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: AppColors.inkSecondary,
                  )),
            ] else
              _InfoRow(
                icon: Icons.verified_user_outlined,
                color: AppColors.indigo,
                text: t.contactWallet,
              ),
            const SizedBox(height: 20),

            // Политика возврата (PRD §8, Сценарий В) — видна до оплаты
            _RefundPolicy(event: widget.event),
            const SizedBox(height: 24),

            // Итого с разбивкой (PRD §9.3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _TotalLine(label: t.subtotal, amount: _subtotal),
                  const SizedBox(height: 8),
                  _TotalLine(label: t.bookingFee, amount: _fee),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.total,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            color: AppColors.inkSecondary,
                          )),
                      Text(
                        '${money(_grandTotal)} ֏',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _canPay && !_loading ? _pay : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canPay ? AppColors.orange : AppColors.surfaceGray,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(t.confirmPay,
                        style: TextStyle(
                          color: _canPay
                              ? Colors.white
                              : AppColors.inkSecondary,
                        )),
              ),
            ),
            const SizedBox(height: 12),
            Text(t.legal,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  color: AppColors.inkSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

/// Строка сводки заказа: «VIP × 2 ............ 90 000 ֏».
class _OrderLine extends StatelessWidget {
  final String name;
  final int amount;
  const _OrderLine({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                )),
          ),
          Text('${money(amount)} ֏',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.inkPrimary,
              )),
        ],
      ),
    );
  }
}

/// Строка разбивки итога: «Билеты ........ 90 000 ֏».
class _TotalLine extends StatelessWidget {
  final String label;
  final int amount;
  const _TotalLine({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: AppColors.inkSecondary,
            )),
        Text('${money(amount)} ֏',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            )),
      ],
    );
  }
}

/// Информационная строка с иконкой (например «данные из Telcell Wallet»).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

/// Блок политики возврата (PRD §8, Сценарий В). Покупатель видит условия
/// возврата до оплаты.
class _RefundPolicy extends StatelessWidget {
  final Event event;
  const _RefundPolicy({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final ok = event.refundGuarantee;
    final color = ok ? const Color(0xFF1DB954) : AppColors.inkSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE8FBF1) : AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.assignment_turned_in_outlined : Icons.lock_outline,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ok ? t.refundYes : t.refundNo,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ok ? const Color(0xFF12903F) : AppColors.inkPrimary,
                    )),
                const SizedBox(height: 2),
                Text(
                  ok ? t.refundYesBody(event.refundUntilHours) : t.refundNoBody,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.10)
                    : AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? color : AppColors.inkSecondary,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.inkSecondary,
                      )),
                ],
              ),
            ),
            // Radio dot
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? color : AppColors.divider,
                    width: selected ? 6 : 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Экран успеха ─────────────────────────────────────────────────────────

/// Экран успеха — сразу показывает купленные билеты с QR-кодом.
/// Эти же билеты сохранены в «Мои билеты».
class _SuccessScreen extends StatelessWidget {
  final List<OwnedTicket> tickets;
  final Event event;
  const _SuccessScreen({required this.tickets, required this.event});

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 84, height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.orangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.orange, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              Text(t.paySuccess,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${tickets.length} ${t.ticketsBought}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Билеты с QR-кодом — сразу после оплаты.
              for (final ticket in tickets) ...[
                TicketCard(ticket: ticket),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Открыть вкладку «Мои билеты» (свежий HomeShell — билеты
                  // уже сохранены и сразу подгрузятся).
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const HomeShell(initialTab: 3)),
                    (route) => false,
                  ),
                  child: Text(t.goToTickets),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  // Вернуться на главную страницу (каталог).
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const HomeShell(initialTab: 0)),
                    (route) => false,
                  ),
                  child: Text(t.backToCatalog),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
