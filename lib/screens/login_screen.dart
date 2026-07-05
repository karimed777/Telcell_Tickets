import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../services/auth_api.dart';
import '../services/http_tickets_api.dart';
import '../services/session.dart';
import '../services/tickets_api.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_shapes.dart';
import 'home_shell.dart';

/// Экран входа/регистрации по телефону + код (имитация SMS, mock-OTP).
///
/// Два шага:
///  1. ввод телефона (+ имя для новых пользователей) →
///     запрос кода (/api/auth/request-otp);
///  2. ввод кода → проверка и выдача токена (/api/auth/verify-otp).
///
/// После успеха сессия сохраняется в [AppSession] и приложение открывает
/// каталог. Для HttpTicketsApi обновляется личность покупателя, чтобы
/// билеты/заказы привязывались к вошедшему пользователю.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { phone, code }

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  _Step _step = _Step.phone;
  bool _loading = false;
  String? _error;
  String? _devCode; // dev-подсказка с кодом (mock/dev backend)

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phoneCtrl.text.trim().length >= 6;
  bool get _codeValid => _codeCtrl.text.trim().length >= 4;

  /// Достаёт человекочитаемое сообщение из ошибки вида {"error": "..."}.
  String _readError(Object e, String fallback) {
    var raw = e is StateError ? e.message : e.toString();
    final brace = raw.indexOf('{');
    if (brace >= 0) raw = raw.substring(brace);
    try {
      final j = jsonDecode(raw);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {}
    return fallback;
  }

  Future<void> _requestCode() async {
    final t = AppLocale.stringsOf(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await Auth.instance.requestOtp(
        phone: _phoneCtrl.text.trim(),
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _step = _Step.code;
        _devCode = code;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _readError(e, t.loginFailed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final t = AppLocale.stringsOf(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Auth.instance.verifyOtp(
        phone: _phoneCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
      );
      await AppSession.instance.signIn(
        token: res.token,
        phone: res.user.phone,
        name: res.user.name,
        isAdmin: res.user.isAdmin,
      );
      // Регистрируем пользователя в mock-справочнике, чтобы ему можно
      // было передать билет по номеру/email (поиск получателя).
      MockTicketsApi.registerKnownUser(res.user.phone, res.user.name);
      // Привязываем последующие запросы к вошедшему пользователю.
      final api = Api.instance;
      if (api is HttpTicketsApi) {
        api.setIdentity(
          phone: res.user.phone,
          name: res.user.name,
          token: res.token,
        );
      }
      if (!mounted) return;
      // Админ входит скрытым номером — признак уже в сессии
      // (AppSession.isAdmin). Админ-панель откроется из HomeShell
      // (скрытый пункт меню), когда будет реализована.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = _readError(e, t.loginFailed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _backToPhone() {
    setState(() {
      _step = _Step.phone;
      _error = null;
      _codeCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.indigo,
        body: Stack(
          children: [
            // Фирменный indigo-фон с бликами (как на онбординге)
            const Positioned.fill(child: OnboardingBackdrop()),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Шапка: назад + бренд ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12)),
                            ),
                            child: const Center(child: BrandMark(size: 32)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            t.loginWelcome,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.loginHeroTag,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.cyanSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Белый лист с формой ─────────────────────────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _step == _Step.phone
                            ? _buildPhoneStep(t)
                            : _buildCodeStep(t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Шаг 1: телефон + имя ─────────────────────────────────────────────
  Widget _buildPhoneStep(AppStrings t) {
    return ListView(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        _StepChips(current: 0, labels: [t.loginStepPhone, t.loginStepCode]),
        const SizedBox(height: 20),
        Text(t.loginTitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
            )),
        const SizedBox(height: 6),
        Text(t.loginPhoneStep,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSecondary,
            )),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: t.loginPhoneHint,
            prefixIcon: const Icon(Icons.phone_outlined,
                size: 18, color: AppColors.inkSecondary),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: t.nameHint,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                size: 18, color: AppColors.inkSecondary),
          ),
        ),
        if (_error != null) _ErrorBox(text: _error!),
        const SizedBox(height: 24),
        _CtaButton(
          label: t.sendCode,
          loading: _loading,
          enabled: _phoneValid,
          onPressed: _requestCode,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 14, color: AppColors.inkSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.loginSecureNote,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Шаг 2: код из SMS ────────────────────────────────────────────────
  Widget _buildCodeStep(AppStrings t) {
    return ListView(
      key: const ValueKey('code'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        _StepChips(current: 1, labels: [t.loginStepPhone, t.loginStepCode]),
        const SizedBox(height: 20),
        Text(t.loginCodeStep,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
            )),
        const SizedBox(height: 6),
        Text(t.codeSentTo(_phoneCtrl.text.trim()),
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSecondary,
            )),
        const SizedBox(height: 20),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          maxLength: 6,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
            color: AppColors.inkPrimary,
          ),
          decoration: InputDecoration(
            hintText: t.codeHint,
            counterText: '',
            hintStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSecondary,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
        if (_devCode != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.indigoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code_rounded,
                    size: 15, color: AppColors.indigo),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t.devCodeHint(_devCode!),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) _ErrorBox(text: _error!),
        const SizedBox(height: 24),
        _CtaButton(
          label: t.confirmCode,
          loading: _loading,
          enabled: _codeValid,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _backToPhone,
          child: Text(t.changePhone,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.indigo,
              )),
        ),
      ],
    );
  }
}

/// Индикатор шагов «1 Телефон — 2 Код».
class _StepChips extends StatelessWidget {
  final int current;
  final List<String> labels;
  const _StepChips({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.orange : AppColors.divider,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.orange
                  : (i < current ? AppColors.orangeLight : AppColors.surfaceGray),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i < current)
                  const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.orange)
                else
                  Text('${i + 1}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: i == current
                            ? Colors.white
                            : AppColors.inkSecondary,
                      )),
                const SizedBox(width: 6),
                Text(labels[i],
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == current
                          ? Colors.white
                          : (i < current
                              ? AppColors.orange
                              : AppColors.inkSecondary),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Оранжевая CTA-кнопка с состоянием загрузки.
class _CtaButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;
  const _CtaButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: (loading || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          disabledBackgroundColor:
              enabled ? AppColors.orange : AppColors.surfaceGray,
          disabledForegroundColor: AppColors.inkSecondary,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label),
      ),
    );
  }
}

/// Красивый блок ошибки.
class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                )),
          ),
        ],
      ),
    );
  }
}
