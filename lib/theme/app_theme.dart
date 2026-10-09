import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ruby Ribbon Bakeshop palette — inspired by the classic Filipino bakeshop
/// look: bold ribbon red, warm cream/gold, chocolate brown text, on a clean
/// white base.
class AppColors {
  static const Color ribbonRed = Color(0xFFD4102A);
  static const Color ribbonRedDark = Color(0xFFA50D21);
  static const Color gold = Color(0xFFE8B23D);
  static const Color cream = Color(0xFFFFF7EA);
  static const Color creamDark = Color(0xFFFBEBD2);
  static const Color chocolate = Color(0xFF3B2620);
  static const Color chocolateSoft = Color(0xFF6F5A52);
  static const Color success = Color(0xFF2E8B57);
  static const Color warning = Color(0xFFCB8A00);
  static const Color danger = Color(0xFFC1272D);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFEFE1CC);

  static const List<Color> categoryColors = [
    Color(0xFFD4102A),
    Color(0xFFE8B23D),
    Color(0xFF7A4B2B),
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final headlineFont = GoogleFonts.baloo2TextTheme();
    final bodyFont = GoogleFonts.nunitoTextTheme();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ribbonRed,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: bodyFont.copyWith(
        displayLarge: headlineFont.displayLarge?.copyWith(color: AppColors.chocolate),
        displayMedium: headlineFont.displayMedium?.copyWith(color: AppColors.chocolate),
        headlineLarge: headlineFont.headlineLarge?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w700),
        headlineMedium: headlineFont.headlineMedium?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w700),
        headlineSmall: headlineFont.headlineSmall?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w700),
        titleLarge: headlineFont.titleLarge?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w600),
        titleMedium: headlineFont.titleMedium?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w600),
        titleSmall: headlineFont.titleSmall?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w600),
        bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.chocolate),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.chocolateSoft),
        labelLarge: bodyFont.labelLarge?.copyWith(color: AppColors.chocolate, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ribbonRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      // Every state (resting, pressed/hovered/focused, disabled) is pinned
      // explicitly here rather than left to Flutter's defaults — the default
      // Material press/overlay layer can otherwise pull a reddish tint from
      // the app's red primary color and wash out the button while it's held
      // down. Pinning guarantees: red surface -> white text, always; beige
      // surface (disabled) -> red text, always; and the press overlay is a
      // fixed neutral white wash that can never turn the surface or text red.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? AppColors.creamDark : AppColors.ribbonRed,
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? AppColors.ribbonRed : Colors.white,
          ),
          overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.14)),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          elevation: MaterialStateProperty.all(1.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(AppColors.ribbonRed),
          // A faint neutral wash on press — never a red/pink tint that could
          // compete with the red label text.
          overlayColor: MaterialStateProperty.all(AppColors.chocolate.withOpacity(0.06)),
          side: MaterialStateProperty.all(const BorderSide(color: AppColors.ribbonRed, width: 1.4)),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(AppColors.ribbonRedDark),
          overlayColor: MaterialStateProperty.all(AppColors.chocolate.withOpacity(0.06)),
        ),
      ),
      // Neutral ripple/highlight everywhere else (plain InkWell/Material
      // widgets like the quantity steppers) so nothing picks up a reddish
      // tint by default from the red primary color.
      splashColor: AppColors.chocolate.withOpacity(0.08),
      highlightColor: AppColors.chocolate.withOpacity(0.05),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ribbonRed, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      // Fallback only — every ChoiceChip in the app uses AppChoiceChip
      // (see common_widgets.dart), which sets its own background/label
      // colors explicitly per selection state rather than relying on this.
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.ribbonRed,
        backgroundColor: AppColors.creamDark,
        labelStyle: const TextStyle(color: AppColors.ribbonRed, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.ribbonRed,
        unselectedItemColor: AppColors.chocolateSoft,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}