import 'package:flutter/material.dart';

/// Espaciado y radios consistentes (estilo producto tipo Linear / Stripe).
/// Tamaños mínimos legibles en móvil (no usar por debajo en UI de lectura).
abstract final class AppTypography {
  static const double minCaption = 13;
  static const double minLabel = 14;
  static const double minBodySecondary = 14;
  static const double navBarLabel = 11;
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration staggerStep = Duration(milliseconds: 55);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeOutQuart;
}

abstract final class AppShadows {
  static List<BoxShadow> card(BuildContext context, {double opacity = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.black : const Color(0xFF0F172A);
    return [
      BoxShadow(
        color: base.withValues(alpha: 0.06 * opacity),
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: base.withValues(alpha: 0.04 * opacity),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> navFloat(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      BoxShadow(
        color: scheme.primary.withValues(alpha: 0.14),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
