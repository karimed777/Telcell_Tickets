import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Переключатель языка РУС ⇄ ՀԱՅ для светлых экранов.
/// Тапаешь — язык меняется во всём приложении (через [AppLocale.toggle]).
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return GestureDetector(
      onTap: locale.toggle,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                size: 16, color: AppColors.inkSecondary),
            const SizedBox(width: 5),
            Text(
              locale.language.toggleLabel,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
