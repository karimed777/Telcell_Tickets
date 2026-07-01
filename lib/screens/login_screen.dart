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

/// Экран входа по телефону + код (имитация SMS, mock-OTP).
///
/// Два шага:
///  1. ввод телефона → запрос кода (/api/auth/request-otp);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(t.loginTitle),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: BrandMark(size: 30)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _step == _Step.phone ? t.loginPhoneStep : t.loginCodeStep,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 24),

              if (_step == _Step.phone) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t.loginPhoneHint,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: t.nameHint,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t.codeHint,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                ),
                if (_devCode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    t.devCodeHint(_devCode!),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_step == _Step.phone
                          ? (_phoneValid ? _requestCode : null)
                          : (_codeValid ? _verifyCode : null)),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(_step == _Step.phone ? t.sendCode : t.confirmCode),
                ),
              ),
              if (_step == _Step.code) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _step = _Step.phone;
                            _error = null;
                            _codeCtrl.clear();
                          }),
                  child: Text(t.changePhone),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
