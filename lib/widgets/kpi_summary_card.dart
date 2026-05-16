import 'package:flutter/material.dart';
import '../core/motion/app_motion_kit.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/sim_theme.dart';

/// Tarjeta KPI estilo dashboard (cabecera en degradado + métricas grandes).
class KpiSummaryCard extends StatelessWidget {
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
  List<Color> get _headerGradient => [
        accentColor,
        Color.lerp(accentColor, SimTheme.primaryColor, 0.45)!,
        Color.lerp(accentColor, const Color(0xFF1E1B4B), 0.3)!,
      ];

  Widget _metric(
    BuildContext context, {
    required String label,
    required int count,
    required int delayed,
    required bool onDark,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: AppTypography.minCaption,
                letterSpacing: 0.35,
                fontWeight: FontWeight.w700,
                color: onDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -1.2,
                color: onDark ? Colors.white : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (delayed > 0) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: onDark ? 0.9 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: onDark ? 0.5 : 0.35),
                    ),
                  ),
                  child: Text(
                    '$delayed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: onDark ? Colors.white : scheme.error,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPending = countLeft > 0 || (countRight ?? 0) > 0;
    final hasDelayed = delayedLeft > 0 || (delayedRight ?? 0) > 0;
    final dual = labelRight != null;

    final card = AppScalePressable(
      onTap: onTap,
      enabled: onTap != null,
      child: Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: accentColor.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadii.xl + 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl + 4),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl + 4),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: hasPending ? 0.28 : 0.1),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 14, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _headerGradient,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -24,
                        child: Icon(
                          icon,
                          size: 88,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Icon(icon, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.25,
                                            height: 1.15,
                                          ),
                                    ),
                                    if (onTap != null)
                                      Text(
                                        'Ver detalle →',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontSize: AppTypography.minCaption,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              if (onTap != null)
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (dual)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _metric(
                                    context,
                                    label: labelLeft,
                                    count: countLeft,
                                    delayed: delayedLeft,
                                    onDark: true,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 52,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                Expanded(
                                  child: _metric(
                                    context,
                                    label: labelRight!,
                                    count: countRight ?? 0,
                                    delayed: delayedRight ?? 0,
                                    onDark: true,
                                  ),
                                ),
                              ],
                            )
                          else
                            _metric(
                              context,
                              label: labelLeft,
                              count: countLeft,
                              delayed: delayedLeft,
                              onDark: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  color: scheme.surface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Icon(
                        hasDelayed
                            ? Icons.warning_amber_rounded
                            : Icons.insights_rounded,
                        size: 20,
                        color: hasDelayed ? scheme.error : accentColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          footer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: AppTypography.minBodySecondary,
                                fontWeight:
                                    hasDelayed ? FontWeight.w700 : FontWeight.w500,
                                color: hasDelayed
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: card,
    );
  }
}
