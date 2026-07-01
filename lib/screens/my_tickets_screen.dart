import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../services/tickets_api.dart';
import '../services/session.dart';
import '../services/http_tickets_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ticket_card.dart';
import 'onboarding_screen.dart';

/// Мои билеты — стиль Telcell Wallet / QR-раздел.
/// Белый фон, два таба (Активные / История), карточки-билеты.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<OwnedTicket>> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _future = Api.instance.fetchMyTickets();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    // Блок-форма setState: стрелочная `=> _future = ...` вернула бы Future
    // (результат присваивания) и Flutter падал бы с
    // «setState() callback argument returned a Future».
    setState(() {
      _future = Api.instance.fetchMyTickets();
    });
  }

  /// Диалог передачи билета с моментальным поиском получателя
  /// (PRD §5.5, US-03). По мере ввода показываем имя получателя
  /// или «пользователь не найден»; передать можно только
  /// существующему пользователю.
  Future<void> _transfer(OwnedTicket ticket) async {
    final t = AppLocale.stringsOf(context);
    final contact = await showDialog<String>(
      context: context,
      builder: (ctx) => _TransferDialog(strings: t),
    );

    if (contact == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await Api.instance.transferTicket(ticketId: ticket.id, toContact: contact);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.transferDone)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('${t.transferFailed}: ${_humanError(e)}'),
        ),
      );
    }
  }

  /// Реакция на перенос события (Задача 4): подтвердить участие
  /// на новую дату. Билет переходит в rescheduledConfirmed.
  Future<void> _confirmReschedule(OwnedTicket ticket) async {
    final t = AppLocale.stringsOf(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Api.instance.confirmReschedule(ticket.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.rescheduleConfirmed)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(_humanError(e)),
        ),
      );
    }
  }

  /// Реакция на отмену/перенос события (Задача 4): запросить возврат.
  /// Перед вызовом API спрашиваем подтверждение в диалоге.
  Future<void> _requestRefund(OwnedTicket ticket) async {
    final t = AppLocale.stringsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.refundDialogTitle),
        content: Text(t.refundDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.refundDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await Api.instance.requestRefund(ticket.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.refundRequested)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(_humanError(e)),
        ),
      );
    }
  }

  /// Достаёт человекочитаемое сообщение из ошибки API/мока.
  /// Backend возвращает тело вида {"error": "..."}; вытаскиваем поле error.
  String _humanError(Object e) {
    final raw = e.toString();
    final match = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1)!;
    return raw.replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
  }

  /// Выход из аккаунта / гостевого режима — возврат на онбординг.
  Future<void> _signOut() async {
    await AppSession.instance.signOut();
    final api = Api.instance;
    if (api is HttpTicketsApi) api.setIdentity(token: null);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final session = AppSession.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(t.navTickets),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(
                session.isLoggedIn
                    ? Icons.account_circle_rounded
                    : Icons.account_circle_outlined,
              ),
              onSelected: (v) {
                if (v == 'signout') _signOut();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    session.isLoggedIn
                        ? (session.name?.isNotEmpty == true
                            ? '${session.name}\n${session.phone ?? ''}'
                            : session.phone ?? '')
                        : t.guestBadge,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'signout',
                  child: Text(t.signOut),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.inkSecondary,
            indicatorColor: AppColors.orange,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: t.tabMyQr),
              Tab(text: t.tabScan),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            // Таб 1 — Мои QR-билеты
            FutureBuilder<List<OwnedTicket>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.orange, strokeWidth: 2.5),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) return _EmptyTickets(t: t);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TicketCard(
                      ticket: list[i],
                      onTransfer: () => _transfer(list[i]),
                      onConfirmReschedule: () => _confirmReschedule(list[i]),
                      onRequestRefund: () => _requestRefund(list[i]),
                    ),
                  ),
                );
              },
            ),
            // Таб 2 — Сканер
            _ScannerTab(),
          ],
        ),
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  final AppStrings t;
  const _EmptyTickets({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 38, color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 16),
            Text(t.noTicketsTitle,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(t.noTicketsBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

/// Таб сканера — имитация вьюфайндера.
class _ScannerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final t = AppLocale.stringsOf(context);
    return Stack(
      children: [
        // Тёмный фон (камера)
        Container(color: Colors.black),
        // Вьюфайндер
        Center(
          child: Container(
            width: size.width * 0.70,
            height: size.width * 0.70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Угловые акценты (как в реальном Wallet)
                ..._corners(),
              ],
            ),
          ),
        ),
        // Инструкция
        Positioned(
          top: size.width * 0.15,
          left: 0, right: 0,
          child: Text(
            t.scanHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        // Нижние кнопки
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            color: AppColors.background,
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: Text(t.enterId),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(t.openGallery),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<Widget> _corners() {
    const len = 22.0;
    const thick = 3.0;
    final color = AppColors.orange;

    Positioned corner(bool top, bool left) {
      return Positioned(
        top:    top  ? 0 : null,
        bottom: top  ? null : 0,
        left:   left ? 0 : null,
        right:  left ? null : 0,
        child: SizedBox(
          width: len, height: len,
          child: CustomPaint(
            painter: _CornerPainter(
              top: top, left: left, color: color, thickness: thick),
          ),
        ),
      );
    }

    return [
      corner(true, true),
      corner(true, false),
      corner(false, true),
      corner(false, false),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  final Color color;
  final double thickness;
  const _CornerPainter(
      {required this.top, required this.left, required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Диалог передачи билета с моментальным поиском получателя.
///
/// По мере ввода телефона/email (debounce 400мс) вызывает
/// [TicketsApi.lookupRecipient] и показывает:
///  • имя получателя, если найден — кнопка «Передать» активна;
///  • «пользователь не найден» — кнопка заблокирована.
/// Возвращает нормализованный контакт через Navigator.pop.
class _TransferDialog extends StatefulWidget {
  final AppStrings strings;
  const _TransferDialog({required this.strings});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  /// Состояние поиска: idle / searching / результат.
  bool _searching = false;
  RecipientLookup? _result;

  /// Контакт, для которого сейчас актуален _result
  /// (защита от гонок: показываем результат только для текущего ввода).
  String _resultFor = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final v = value.trim();
    setState(() {
      _result = null;
      _resultFor = '';
      _searching = v.length >= 3;
    });
    if (v.length < 3) {
      setState(() => _searching = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _doLookup(v));
  }

  Future<void> _doLookup(String contact) async {
    try {
      final res = await Api.instance.lookupRecipient(contact);
      if (!mounted || _ctrl.text.trim() != contact) return;
      setState(() {
        _result = res;
        _resultFor = contact;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || _ctrl.text.trim() != contact) return;
      // При сетевой ошибке трактуем как «не найден» (передача заблокирована).
      setState(() {
        _result = RecipientLookup(found: false, contact: contact);
        _resultFor = contact;
        _searching = false;
      });
    }
  }

  bool get _canTransfer =>
      _result != null &&
      _result!.found &&
      _resultFor == _ctrl.text.trim();

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return AlertDialog(
      title: Text(t.transferTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.transferBody,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: AppColors.inkSecondary,
                height: 1.4,
              )),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(hintText: t.transferHint),
          ),
          const SizedBox(height: 10),
          _statusRow(t),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _canTransfer
              ? () => Navigator.pop(context, _ctrl.text.trim())
              : null,
          child: Text(t.transferConfirm),
        ),
      ],
    );
  }

  /// Строка состояния под полем ввода.
  Widget _statusRow(AppStrings t) {
    if (_searching) {
      return Row(
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.transferSearching,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.inkSecondary,
                )),
          ),
        ],
      );
    }
    final r = _result;
    if (r == null || _resultFor != _ctrl.text.trim()) {
      return Text(t.transferEnterContact,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12,
            color: AppColors.inkSecondary,
          ));
    }
    if (r.found) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF1DB954), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.transferFound(r.displayName ?? ''),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12903F),
                )),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(t.transferNotFound,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: AppColors.error,
              )),
        ),
      ],
    );
  }
}
