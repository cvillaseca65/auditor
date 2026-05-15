import 'package:flutter/material.dart';

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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = borderRadius ?? BorderRadius.circular(AppRadii.xl);

    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: r,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: AppShadows.card(context),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? inner
              : InkWell(
                  onTap: onTap,
                  borderRadius: r,
                  child: inner,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: SimTheme.softScreenGradientOf(context),
      ),
      child: child,
    );
  }
}
