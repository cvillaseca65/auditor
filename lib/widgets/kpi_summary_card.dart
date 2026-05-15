import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/sim_theme.dart';

/// Tarjeta KPI: acento lateral, métricas y pie contextual (tema claro/oscuro).
class KpiSummaryCard extends StatelessWidget {
  final String title;
  final String labelLeft;
  final int countLeft;
  final int delayedLeft;
  final String? labelRight;
  final int? countRight;
  final int? delayedRight;
  final String footer;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const KpiSummaryCard({
    super.key,
    required this.title,
    required this.labelLeft,
    required this.countLeft,
    this.delayedLeft = 0,
    this.labelRight,
    this.countRight,
    this.delayedRight,
    required this.footer,
    required this.icon,
    this.accentColor = SimTheme.accentColor,
    this.onTap,
  });

  Widget _metricBlock(
    BuildContext context, {
    required String label,
    required int count,
    required int delayed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.45,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.8,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            children: [
              TextSpan(text: '$count'),
              if (delayed > 0)
                TextSpan(
                  text: '  / ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (delayed > 0)
                TextSpan(
                  text: '$delayed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.error,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPending = countLeft > 0 || (countRight ?? 0) > 0;
    final hasDelayed = delayedLeft > 0 || (delayedRight ?? 0) > 0;
    final borderTint = accentColor.withValues(alpha: hasPending ? 0.35 : 0.12);

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            margin: const EdgeInsets.only(top: 6, bottom: 6, left: 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor,
                  Color.lerp(accentColor, scheme.primary, 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: accentColor.withValues(alpha: 0.15),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                  height: 1.25,
                                ),
                          ),
                          if (onTap != null)
                            Text(
                              'Toca para abrir',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.primary.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      onTap != null
                          ? Icons.keyboard_arrow_right_rounded
                          : Icons.analytics_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _metricBlock(
                        context,
                        label: labelLeft,
                        count: countLeft,
                        delayed: delayedLeft,
                      ),
                    ),
                    if (labelRight != null) ...[
                      Container(
                        width: 1,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: _metricBlock(
                          context,
                          label: labelRight!,
                          count: countRight ?? 0,
                          delayed: delayedRight ?? 0,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: hasDelayed
                        ? scheme.errorContainer.withValues(alpha: 0.55)
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hasDelayed
                          ? scheme.error.withValues(alpha: 0.35)
                          : scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          hasDelayed
                              ? Icons.error_outline_rounded
                              : Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: hasDelayed ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            footer,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight:
                                  hasDelayed ? FontWeight.w700 : FontWeight.w500,
                          color: hasDelayed ? scheme.error : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        builder: (context, t, child) {
          return Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: Opacity(opacity: t, child: child),
          );
        },
        child: Material(
          color: scheme.surface,
          elevation: hasPending ? 2 : 0,
          shadowColor: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.xl + 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xl + 2),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xl + 2),
                border: Border.all(color: borderTint, width: 1),
                gradient: LinearGradient(
                  colors: [
                    scheme.surface,
                    accentColor.withValues(alpha: 0.045),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
