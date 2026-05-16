import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_tokens.dart';

/// Efectos reutilizables con [flutter_animate](https://pub.dev/packages/flutter_animate).
extension AppMotionEffects on Widget {
  /// Entrada escalonada (no usar en listas scroll: puede quedar a medias al reciclar celdas).
  Widget appStaggerIn(
    int index, {
    Duration step = const Duration(milliseconds: 55),
    Duration duration = const Duration(milliseconds: 420),
  }) {
    final delay = step * index;
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppMotion.curve)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: duration,
          curve: AppMotion.curve,
        )
        .slideX(
          begin: 0.015,
          end: 0,
          duration: duration,
          curve: AppMotion.curve,
        );
  }

  /// Cabeceras y bloques hero.
  Widget appHeroIn({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.curve)
        .slideY(begin: 0.06, end: 0, duration: AppMotion.medium, curve: AppMotion.curve)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: AppMotion.medium,
          curve: AppMotion.curve,
        );
  }
}

/// Escala sutil al pulsar (feedback táctil premium).
class AppScalePressable extends StatefulWidget {
  const AppScalePressable({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<AppScalePressable> createState() => _AppScalePressableState();
}

class _AppScalePressableState extends State<AppScalePressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
