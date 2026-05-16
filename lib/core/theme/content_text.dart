import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tipografía para **contenido** (textos de API, detalle, lecturas).
abstract final class ContentText {
  static const double bodyLargeSize = 17;
  static const double bodyMediumSize = 15;

  static TextStyle? bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  static TextStyle? bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  static TextStyle? fieldValue(BuildContext context) =>
      bodyLarge(context)?.copyWith(height: 1.45);

  static TextStyle? fieldLabel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: AppTypography.minLabel,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: scheme.primary,
        );
  }

  /// Etiquetas en celdas, meta tabla, chips (legible, no microscópica).
  static TextStyle? uiLabel(BuildContext context) => fieldLabel(context);

  /// Fechas secundarias, pies de celda, metadatos en listas.
  static TextStyle? uiCaption(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: AppTypography.minBodySecondary,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        );
  }
}
