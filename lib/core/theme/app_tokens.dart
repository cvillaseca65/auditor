import 'package:flutter/material.dart';

/// Espaciado y radios consistentes (estilo producto tipo Linear / Stripe).
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
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
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
