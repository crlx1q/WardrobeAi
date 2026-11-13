import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed brand colors that do not change between light/dark.
class AppColors {
  static const accent = Color(0xFFA77B4E); // warm gold — AI accent
  static const accentSoft = Color(0xFFF0BD8B);
  static const onyx = Color(0xFF1C1B1B);
  static const ivory = Color(0xFFFDF8F8);
  static const error = Color(0xFFBA1A1A);
}

class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

/// Custom tokens not covered by [ColorScheme].
@immutable
class AppX extends ThemeExtension<AppX> {
  final Color accentSoft;
  final Color glassFill;
  final Color glassBorder;
  final Color chipBg;
  final List<BoxShadow> cardShadow;

  const AppX({
    required this.accentSoft,
    required this.glassFill,
    required this.glassBorder,
    required this.chipBg,
    required this.cardShadow,
  });

  @override
  AppX copyWith({
    Color? accentSoft,
    Color? glassFill,
    Color? glassBorder,
    Color? chipBg,
    List<BoxShadow>? cardShadow,
  }) =>
      AppX(
        accentSoft: accentSoft ?? this.accentSoft,
        glassFill: glassFill ?? this.glassFill,
        glassBorder: glassBorder ?? this.glassBorder,
        chipBg: chipBg ?? this.chipBg,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  AppX lerp(ThemeExtension<AppX>? other, double t) => this;
}

extension ThemeAccess on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  AppX get x => Theme.of(this).extension<AppX>()!;
}

class AppTheme {
  static ThemeData light() => _build(_lightScheme, _lightX, Brightness.light);
  static ThemeData dark() => _build(_darkScheme, _darkX, Brightness.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    surface: Color(0xFFFDF8F8),
    onSurface: Color(0xFF1C1B1B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F3F2),
    surfaceContainer: Color(0xFFF1EDEC),
    surfaceContainerHigh: Color(0xFFEBE7E6),
    surfaceContainerHighest: Color(0xFFE5E2E1),
    onSurfaceVariant: Color(0xFF444748),
    outline: Color(0xFF747878),
    outlineVariant: Color(0xFFC4C7C7),
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF5D5F5F),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: AppColors.accent,
    onTertiary: Color(0xFFFFFFFF),
    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    surface: Color(0xFF141313),
    onSurface: Color(0xFFF4F0EF),
    surfaceContainerLowest: Color(0xFF1B1A1A),
    surfaceContainerLow: Color(0xFF1E1D1D),
    surfaceContainer: Color(0xFF242322),
    surfaceContainerHigh: Color(0xFF2E2C2B),
    surfaceContainerHighest: Color(0xFF383635),
    onSurfaceVariant: Color(0xFFC7C6C5),
    outline: Color(0xFF8F9392),
    outlineVariant: Color(0xFF3A3938),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF1C1B1B),
    secondary: Color(0xFFC6C6C6),
    onSecondary: Color(0xFF1C1B1B),
    tertiary: Color(0xFFD8B183),
    onTertiary: Color(0xFF1C1B1B),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  );

  static final _lightX = AppX(
    accentSoft: AppColors.accentSoft,
    glassFill: Colors.white.withValues(alpha: 0.7),
    glassBorder: Colors.white.withValues(alpha: 0.6),
    chipBg: const Color(0xFFEBE7E6),
    cardShadow: [
      BoxShadow(
        color: AppColors.onyx.withValues(alpha: 0.10),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final _darkX = AppX(
    accentSoft: AppColors.accentSoft,
    glassFill: Colors.white.withValues(alpha: 0.06),
    glassBorder: Colors.white.withValues(alpha: 0.12),
    chipBg: const Color(0xFF2E2C2B),
    cardShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static ThemeData _build(ColorScheme cs, AppX x, Brightness b) {
    final display = GoogleFonts.playfairDisplay;
    final body = GoogleFonts.inter;
    final onS = cs.onSurface;
    final onV = cs.onSurfaceVariant;

    final textTheme = TextTheme(
      displayLarge: display(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.5, color: onS),
      displayMedium: display(fontSize: 34, fontWeight: FontWeight.w700, height: 1.12, letterSpacing: -0.4, color: onS),
      headlineMedium: display(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: onS),
      headlineSmall: display(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3, color: onS),
      titleLarge: display(fontSize: 20, fontWeight: FontWeight.w600, color: onS),
      bodyLarge: body(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: onS),
      bodyMedium: body(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5, color: onV),
      bodySmall: body(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45, color: onV),
      labelLarge: body(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: onS),
      labelSmall: body(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: onV),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      extensions: [x],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: onS,
        iconTheme: IconThemeData(color: onS),
      ),
      iconTheme: IconThemeData(color: onS),
      dividerColor: cs.surfaceContainerHigh,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.surfaceContainerHigh,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: body(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onS,
          side: BorderSide(color: cs.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: body(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: onS),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: body(fontSize: 15, color: cs.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: onS, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: cs.surfaceContainerLowest),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: cs.surface),
    );
  }
}
