import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';

/// Bloque de texto largo a ancho completo (`col-sm-12` en detail.html de SIM).
class DetailFullWidthPanel extends StatelessWidget {
  const DetailFullWidthPanel({
    super.key,
    required this.label,
    required this.text,
    this.accentColor,
  });

  final String label;
  final String text;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: ContentText.fieldLabel(context)?.copyWith(
              color: accent,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            text.trim(),
            style: ContentText.fieldValue(context)?.copyWith(
              fontSize: ContentText.bodyLargeSize,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
