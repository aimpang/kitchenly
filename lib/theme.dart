import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 9999.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

class LightModeColors {
  static const primary = Color(0xFFC4785A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF808055);
  static const onSecondary = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF08080);
  static const background = Color(0xFFFFFBF5);
  static const surface = Color(0xFFFDF6E3);
  static const onSurface = Color(0xFF6B4423);
  static const primaryText = Color(0xFF4A3728);
  static const secondaryText = Color(0xFF8C7E6F);
  static const hint = Color(0xFFBDB2A7);
  static const error = Color(0xFFD9534F);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF8BA888);
  static const divider = Color(0xFFE8DFD0);
  static const transparent = Colors.transparent;
}

class DarkModeColors {
  static const primary = Color(0xFFD69074);
  static const onPrimary = Color(0xFF2D1B14);
  static const secondary = Color(0xFF9BA17B);
  static const onSecondary = Color(0xFF1C1C14);
  static const accent = Color(0xFFF29898);
  static const background = Color(0xFF1C1917);
  static const surface = Color(0xFF2D2A27);
  static const onSurface = Color(0xFFFDF6E3);
  static const primaryText = Color(0xFFFDF6E3);
  static const secondaryText = Color(0xFFBDB2A7);
  static const hint = Color(0xFF6B635B);
  static const error = Color(0xFFE57373);
  static const onError = Color(0xFF2D1B14);
  static const success = Color(0xFFA3B899);
  static const divider = Color(0xFF3D3834);
  static const transparent = Colors.transparent;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: LightModeColors.primary,
    onPrimary: LightModeColors.onPrimary,
    secondary: LightModeColors.secondary,
    onSecondary: LightModeColors.onSecondary,
    error: LightModeColors.error,
    onError: LightModeColors.onError,
    surface: LightModeColors.surface,
    onSurface: LightModeColors.onSurface,
    outline: LightModeColors.divider,
  ),
  scaffoldBackgroundColor: LightModeColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.primaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(LightModeColors.primaryText, LightModeColors.secondaryText),
  dividerColor: LightModeColors.divider,
  iconTheme: const IconThemeData(color: LightModeColors.primaryText),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: LightModeColors.surface,
    indicatorColor: LightModeColors.primary.withValues(alpha: 0.16),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: isSelected ? LightModeColors.primaryText : LightModeColors.secondaryText,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return IconThemeData(color: isSelected ? LightModeColors.primary : LightModeColors.primaryText);
    }),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: DarkModeColors.primary,
    onPrimary: DarkModeColors.onPrimary,
    secondary: DarkModeColors.secondary,
    onSecondary: DarkModeColors.onSecondary,
    error: DarkModeColors.error,
    onError: DarkModeColors.onError,
    surface: DarkModeColors.surface,
    onSurface: DarkModeColors.onSurface,
    outline: DarkModeColors.divider,
  ),
  scaffoldBackgroundColor: DarkModeColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: DarkModeColors.primaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(DarkModeColors.primaryText, DarkModeColors.secondaryText),
  dividerColor: DarkModeColors.divider,
  iconTheme: const IconThemeData(color: DarkModeColors.primaryText),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: DarkModeColors.surface,
    indicatorColor: DarkModeColors.primary.withValues(alpha: 0.22),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: isSelected ? DarkModeColors.primaryText : DarkModeColors.secondaryText,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return IconThemeData(color: isSelected ? DarkModeColors.primary : DarkModeColors.primaryText);
    }),
  ),
);

TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
  return TextTheme(
    headlineLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, color: primaryColor),
    headlineMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25, color: primaryColor),
    titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: primaryColor),
    titleMedium: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: primaryColor),
    titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: primaryColor),
    bodyLarge: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: secondaryColor),
    bodyMedium: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5, color: secondaryColor),
    bodySmall: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: secondaryColor),
    labelLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2, color: secondaryColor),
    labelMedium: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2, color: secondaryColor),
    labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, color: secondaryColor),
  );
}

extension CustomThemeColors on ThemeData {
  Color get success => brightness == Brightness.light ? LightModeColors.success : DarkModeColors.success;
  Color get accent => brightness == Brightness.light ? LightModeColors.accent : DarkModeColors.accent;
  Color get hint => brightness == Brightness.light ? LightModeColors.hint : DarkModeColors.hint;
  Color get transparent => Colors.transparent;
  Color get primaryText => brightness == Brightness.light ? LightModeColors.primaryText : DarkModeColors.primaryText;
  Color get secondaryText => brightness == Brightness.light ? LightModeColors.secondaryText : DarkModeColors.secondaryText;
}
