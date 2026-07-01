import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../services/tickets_api.dart';
import '../theme/app_theme.dart';

/// Карточка купленного билета — стиль Telcell Wallet QR-экран.
/// Белая карточка, QR по центру, детали события внизу.
class TicketCard extends StatelessWidget {
  final OwnedTicket ticket;

  /// Если задан и билет ещё действителен — показывает кнопку «Передать»
  /// (PRD §5.5, US-03).
  final VoidCallback? onTransfer;

  /// Реакция на перенос события (Задача 4): подтвердить участие.
  final VoidCallback? onConfirmReschedule;

  /// Реакция на отмену/перенос (Задача 4): запросить возврат.
  final VoidCallback? onRequestRefund;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTransfer,
    this.onConfirmReschedule,
    this.onRequestRefund,
  });

  @override
  Widget build(BuildContext context) {
    final event = ticket.event;
    final t = AppLocale.stringsOf(context);
    final isAm = AppLocale.of(context).language == AppLanguage.am;
    final badge = _StatusBadge.of(ticket.status, t);
    final qrValid = ticket.status.qrValid;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card + 2),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Шапка с названием события
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceGray,
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(event.category.icon,
                      color: AppColors.orange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.getTitle(isAm),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          )),
                      Text(ticket.ticketTypeName,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: AppColors.inkSecondary,
                          )),
                    ],
                  ),
                ),
                // Статус-бейдж (зависит от жизненного цикла билета)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badge.fg,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Перфорация
          _Perforation(),

          // Баннер отмены/переноса события (Задача 4).
          _EventChangeBanner(
            ticket: ticket,
            t: t,
            isAm: isAm,
            onConfirmReschedule: onConfirmReschedule,
            onRequestRefund: onRequestRefund,
          ),

          // QR + детали
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // QR-код действителен только у оплаченного билета;
                // после передачи/возврата/использования он аннулируется.
                if (qrValid)
                  _QrArea(token: ticket.qrToken)
                else
                  _VoidedQr(label: t.qrVoided),
                const SizedBox(height: 12),
                // Дата и место
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 13, color: AppColors.inkSecondary),
                    const SizedBox(width: 4),
                    Text(event.dateLabel,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 13, color: AppColors.inkSecondary),
                    const SizedBox(width: 4),
                    Text(event.getVenue(isAm),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.qrCaption,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${ticket.id}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),

                // Кому передан билет (если статус transferred).
                if (ticket.status == TicketStatus.transferred &&
                    ticket.transferredTo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    t.transferredTo(ticket.transferredTo!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],

                // Кнопка передачи — только для действительного билета.
                if (qrValid && onTransfer != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onTransfer,
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: Text(t.transfer),
                    ),
                  ),
                ],

                // Кнопка возврата — для оплаченного билета с Refund Guarantee
                // (PRD §8, Сценарий В). Для отмены/переноса возврат —
                // в баннере события выше.
                if (ticket.status == TicketStatus.paid &&
                    event.refundGuarantee &&
                    onRequestRefund != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRequestRefund,
                      icon: const Icon(Icons.assignment_return_outlined, size: 16),
                      label: Text(t.requestRefund),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(color: AppColors.orange),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Бейдж статуса билета: текст + цвета под конкретный [TicketStatus].
class _StatusBadge {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge(this.label, this.bg, this.fg);

  static _StatusBadge of(TicketStatus status, AppStrings t) {
    switch (status) {
      case TicketStatus.paid:
        return _StatusBadge(
            t.statusActive, const Color(0xFFE8FBF1), const Color(0xFF1DB954));
      case TicketStatus.used:
        return _StatusBadge(
            t.statusUsed, AppColors.surfaceGray, AppColors.inkSecondary);
      case TicketStatus.transferred:
        return _StatusBadge(
            t.statusTransferred, const Color(0xFFEDE9FB), AppColors.indigo);
      case TicketStatus.refunded:
        return _StatusBadge(
            t.statusRefunded, const Color(0xFFFFF2E5), AppColors.orange);
      case TicketStatus.cancelled:
        return _StatusBadge(
            t.statusCancelled, const Color(0xFFFDE8E8), const Color(0xFFD64545));
      case TicketStatus.eventCancelled:
        return _StatusBadge(
            t.statusEventCancelled, const Color(0xFFFDE8E8), const Color(0xFFD64545));
      case TicketStatus.rescheduledPending:
        return _StatusBadge(
            t.statusRescheduled, const Color(0xFFFFF6E0), const Color(0xFFB8860B));
      case TicketStatus.rescheduledConfirmed:
        return _StatusBadge(
            t.statusActive, const Color(0xFFE8FBF1), const Color(0xFF1DB954));
    }
  }
}

/// Баннер сценариев отмены/переноса события (Задача 4).
///
/// Отмена: информация об авто-возврате и сроке.
/// Перенос (pending): новая дата, окно решения и две кнопки
/// («Подтвердить участие» / «Запросить возврат»).
/// Перенос (confirmed): подтверждение новой даты.
class _EventChangeBanner extends StatelessWidget {
  final OwnedTicket ticket;
  final AppStrings t;
  final bool isAm;
  final VoidCallback? onConfirmReschedule;
  final VoidCallback? onRequestRefund;
  const _EventChangeBanner({
    required this.ticket,
    required this.t,
    required this.isAm,
    this.onConfirmReschedule,
    this.onRequestRefund,
  });

  String _fmtDate(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final status = ticket.status;
    final event = ticket.event;

    // Отмена события — информация об авто-возврате.
    if (status == TicketStatus.eventCancelled) {
      return _wrap(
        bg: const Color(0xFFFDE8E8),
        icon: Icons.event_busy_rounded,
        iconColor: const Color(0xFFD64545),
        title: t.cancelBannerTitle,
        body: t.cancelBannerBody(event.refundDaysOnCancel),
      );
    }

    // Перенос — ожидание решения пользователя (72ч).
    if (status == TicketStatus.rescheduledPending) {
      final newDate = event.newDate;
      return _wrap(
        bg: const Color(0xFFFFF6E0),
        icon: Icons.update_rounded,
        iconColor: const Color(0xFFB8860B),
        title: t.rescheduleBannerTitle,
        body: newDate != null
            ? t.rescheduleBannerBody(_fmtDate(newDate))
            : t.rescheduleBannerBodyNoDate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(t.rescheduleOptOut,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  color: AppColors.inkSecondary,
                  height: 1.35,
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequestRefund,
                    child: Text(t.requestRefund),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirmReschedule,
                    child: Text(t.confirmAttendance),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Перенос подтверждён.
    if (status == TicketStatus.rescheduledConfirmed) {
      final newDate = event.newDate;
      return _wrap(
        bg: const Color(0xFFE8FBF1),
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF1DB954),
        title: t.rescheduleConfirmedTitle,
        body: newDate != null
            ? t.rescheduleConfirmedBody(_fmtDate(newDate))
            : t.rescheduleBannerBodyNoDate,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _wrap({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                          height: 1.35,
                        )),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }
}

/// Плейсхолдер вместо QR для аннулированного билета.
class _VoidedQr extends StatelessWidget {
  final String label;
  const _VoidedQr({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded,
              size: 56, color: AppColors.inkSecondary),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSecondary,
              )),
        ],
      ),
    );
  }
}

/// Перфорация между шапкой и QR — точно как в Wallet.
class _Perforation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DashPainter()),
          ),
          Positioned(left: -12, top: 0,
              child: _HalfCircle(left: true)),
          Positioned(right: -12, top: 0,
              child: _HalfCircle(left: false)),
        ],
      ),
    );
  }
}

class _HalfCircle extends StatelessWidget {
  final bool left;
  const _HalfCircle({required this.left});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: left ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: 0.5,
        child: Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5;
    const step = 10.0;
    final y = size.height / 2;
    for (double x = 16; x < size.width - 16; x += step) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// QR-код билета (реальный, сканируемый).
class _QrArea extends StatelessWidget {
  final String token;
  const _QrArea({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: QrImageView(
        data: token,
        version: QrVersions.auto,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.inkPrimary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.inkPrimary,
        ),
      ),
    );
  }
}
