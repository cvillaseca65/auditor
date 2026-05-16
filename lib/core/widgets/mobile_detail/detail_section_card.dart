import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../app_premium_card.dart';
import '../ui/app_visual_kit.dart';

/// Bloque de sección (título + campos) como las `card` / `row` de detail.html.
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;
    return AppPremiumCard(
      accentColor: accent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accent.withValues(alpha: 0.14),
                  scheme.surface,
                ],
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  AppGradientIconBadge(
                    icon: icon!,
                    size: 40,
                    colors: [
                      accent,
                      Color.lerp(accent, scheme.tertiary, 0.45) ?? accent,
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Campos etiqueta / valor dentro de una sección.
class DetailFieldsBlock extends StatelessWidget {
  const DetailFieldsBlock({
    super.key,
    required this.fields,
    this.dense = false,
  });

  final List<Map<String, dynamic>> fields;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final labelStyle = ContentText.fieldLabel(context);
    final valueStyle = ContentText.fieldValue(context);
    final gap = dense ? 8.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          Text(fields[i]['label'] as String, style: labelStyle),
          const SizedBox(height: 3),
          SelectableText(
            fields[i]['value'] as String,
            style: valueStyle,
          ),
        ],
      ],
    );
  }
}
