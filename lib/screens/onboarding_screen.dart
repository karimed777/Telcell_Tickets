import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/session.dart';
import '../widgets/brand_shapes.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Онбординг — стиль Telcell Wallet: белый фон, оранжевая кнопка,
/// indigo-баннер сверху с лого.
///
/// Две явные ветки (Задача 4): «Войти» → экран входа по телефону;
/// «Продолжить как гость» → гостевой режим и каталог. Экран больше не
/// дублирует выбор оплаты — он только разводит вход и гостя.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _login(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _guest(BuildContext context) async {
    await AppSession.instance.continueAsGuest();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.stringsOf(context);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkBgOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Верхний indigo-баннер (как в Wallet) ──────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF361268), Color(0xFF4A1A8A)],
                ),
              ),
              child: Stack(
                children: [
                  // Размытые пятна (бренд-текстура)
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 20,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // SafeArea + контент
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Языковой переключатель
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [_LanguageToggle()],
                          ),
                          const Spacer(),
                          // Лого
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.20)),
                                ),
                                child: const Center(
                                    child: BrandMark(size: 28)),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.brandName,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    t.brandTagline,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.65),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            t.onboardHeadline,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Белая нижняя часть ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    Text(
                      t.onboardBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // 3 мини-фичи
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Feature(icon: Icons.flash_on_rounded, label: t.featureOneTap),
                        _Feature(icon: Icons.qr_code_rounded, label: t.featureQr),
                        _Feature(icon: Icons.shield_rounded, label: t.featureSafe),
                      ],
                    ),
                    const Spacer(),
                    // Главная CTA — вход в аккаунт (телефон + код)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: Text(t.loginCta),
                        onPressed: () => _login(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Вторичная — продолжить как гость
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _guest(context),
                        child: Text(t.continueGuest),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.legal,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        color: AppColors.inkSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.orangeLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.orange, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkPrimary,
            )),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return GestureDetector(
      onTap: locale.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: Text(
          locale.language.toggleLabel,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
