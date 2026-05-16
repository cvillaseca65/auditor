import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/app_page_transitions.dart';
import 'app_tokens.dart';

/// Identidad SIM + Material 3 (claro / oscuro) con tipografía limpia.
class SimTheme {
  SimTheme._();

  static const Color primaryColor = Color.fromRGBO(39, 39, 82, 1);
  static const Color accentColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color scaffoldMuted = Color(0xFFF1F5F9);

  static const Color _primaryDark = Color(0xFF1E1E3F);

  /// Compatibilidad: tema claro por defecto.
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          primary: primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          surface: backgroundColor,
          surfaceContainerHighest: const Color(0xFFE2E8F0),
          surfaceContainer: const Color(0xFFE8EEF4),
          surfaceContainerLow: const Color(0xFFF8FAFC),
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE2E8F0),
        ),
        scaffold: scaffoldMuted,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          primary: const Color(0xFF93C5FD),
          brightness: Brightness.dark,
        ).copyWith(
          onPrimary: const Color(0xFF0B1020),
          primaryContainer: const Color(0xFF1E3A5F),
          onPrimaryContainer: const Color(0xFFE0F2FE),
          surface: const Color(0xFF0B0E14),
          surfaceContainerHighest: const Color(0xFF1A2230),
          surfaceContainer: const Color(0xFF141B26),
          surfaceContainerLow: const Color(0xFF10151E),
          surfaceContainerLowest: const Color(0xFF080A0E),
          onSurface: const Color(0xFFE8ECF3),
          onSurfaceVariant: const Color(0xFFB4BDCA),
          outline: const Color(0xFF3D4A5C),
          outlineVariant: const Color(0xFF2A3444),
        ),
        scaffold: const Color(0xFF080A0E),
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffold,
  }) {
    final baseText = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    final inter = GoogleFonts.interTextTheme(baseText);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(inter).copyWith(
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      // Contenido legible (detalle, listas, lecturas): un poco más grande que UI.
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 17,
        height: 1.45,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.45,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: 15,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: AppTypography.minLabel,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: AppTypography.minCaption,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: AppTypography.minBodySecondary,
        height: 1.35,
      ),
    );

    final navIndicator = BorderRadius.circular(AppRadii.md);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: brightness == Brightness.dark ? 1 : 2,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: brightness == Brightness.dark ? 0.55 : 0.65,
            ),
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(borderRadius: navIndicator),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium?.copyWith(
            fontSize: AppTypography.navBarLabel,
            height: 1.15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          );
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: colorScheme.primary);
          }
          return base?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: colorScheme.primary);
          }
          return IconThemeData(
            size: 24,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
            fontSize: 15,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : colorScheme.surfaceContainerLow,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        elevation: 6,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl + 2),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
    );
  }

  static LinearGradient get headerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, _primaryDark, Color(0xFF252550)],
        stops: [0.0, 0.55, 1.0],
      );

  /// Fondo shell / listas: halo suave según brillo.
  static LinearGradient softScreenGradientOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(scheme.primary, scheme.surface, 0.88)!,
          scheme.surface,
          Color.lerp(const Color(0xFF111827), scheme.surface, 0.55)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFE0E7FF),
        scaffoldMuted,
        Color.lerp(primaryColor, const Color(0xFFF8FAFC), 0.9)!,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }
}
