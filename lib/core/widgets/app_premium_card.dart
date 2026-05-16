import 'package:flutter/material.dart';

import 'ui/app_mesh_background.dart';

import '../theme/app_tokens.dart';
import '../theme/sim_theme.dart';

/// Tarjeta elevada con borde suave y sombra adaptada al tema (Stripe-like).
class AppPremiumCard extends StatelessWidget {
  const AppPremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  /// Franja superior con degradado (acento de sección).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = borderRadius ?? BorderRadius.circular(AppRadii.xl);

    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    final accent = accentColor;
    final topStripe = accent != null
        ? Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  Color.lerp(accent, SimTheme.accentColor, 0.35)!,
                  Color.lerp(accent, scheme.primary, 0.5)!,
                ],
              ),
            ),
          )
        : null;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: r,
        border: Border.all(
          color: accent?.withValues(alpha: 0.28) ??
              scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          ...AppShadows.card(context, opacity: accent != null ? 1.25 : 1),
          if (accent != null)
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topStripe != null) topStripe,
              onTap == null
                  ? inner
                  : InkWell(
                      onTap: onTap,
                      borderRadius: r,
                      child: inner,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo de pantalla con gradiente del tema (solo presentación).
class AppScreenBackdrop extends StatelessWidget {
  const AppScreenBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppMeshBackground(child: child);
  }
}
