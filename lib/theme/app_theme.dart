import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// AppColors — точная палитра из реального Telcell Wallet (скриншот).
/// ══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // Основные бренд-цвета
  static const Color orange  = Color(0xFFFF5B2E); // главный CTA / active nav
  static const Color indigo  = Color(0xFF361268); // бренд-фиолетовый / баннеры
  static const Color cyan    = Color(0xFF00D9FF); // вторичный акцент
  static const Color cyanSoft = Color(0xFF73DFFF); // пастельный cyan

  // Фон и поверхности
  static const Color background = Color(0xFFFFFFFF); // белый фон — как в Wallet
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceGray= Color(0xFFF5F5F7); // карточки/сервисы

  // Текст
  static const Color inkPrimary   = Color(0xFF1A1A1A);
  static const Color inkSecondary = Color(0xFF8A8A8E);
  static const Color divider      = Color(0xFFE8E8EC);

  // Статусы
  static const Color success = Color(0xFF34C759);
  static const Color error   = Color(0xFFFF3B30);

  // Специальные
  static const Color orangeLight = Color(0xFFFFF0EB); // подсветка orange
  static const Color indigoLight = Color(0xFFF0EBFF); // подсветка indigo
}

class AppRadii {
  AppRadii._();
  static const double chip   = 100;
  static const double card   = 16;
  static const double button = 14;
  static const double sheet  = 20;
  static const double input  = 12;
  static const double icon   = 14;
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Manrope';
  static TextTheme _manrope(TextTheme base) =>
      GoogleFonts.manropeTextTheme(base);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    const colorScheme = ColorScheme.light(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.indigo,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.inkPrimary,
      // ignore: deprecated_member_use
      background: AppColors.background,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(_manrope(base.textTheme)),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.inkPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkPrimary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceGray,
        selectedColor: AppColors.orange,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.inkPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        elevation: 0,
        pressElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGray,
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.inkSecondary,
          fontSize: 15,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),

      // Nav bar стилизован вручную в home_shell
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.inkSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: AppColors.inkPrimary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.inkPrimary,
      ),
      headlineSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      titleLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
      titleSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
      bodyLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.inkPrimary,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      labelSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSecondary,
      ),
    );
  }
}

/// SystemUiOverlayStyle helpers
const lightBgOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
);
const darkBgOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
);
