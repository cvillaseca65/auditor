import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Indicador de carga / “pensando” con el logo SIM (sustituye el spinner genérico).
class SimLoadingIndicator extends StatelessWidget {
  const SimLoadingIndicator({
    super.key,
    this.size = 72,
    this.message,
  });

  /// Versión compacta para botones o filas inline.
  const SimLoadingIndicator.compact({super.key, this.message})
      : size = 26;

  final double size;
  final String? message;

  static const _logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final msg = message;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    if (size <= 28 && (msg == null || msg.isEmpty)) {
      return SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: _animatedLogo(height: size),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _animatedLogo(height: size),
        if (msg != null && msg.isNotEmpty) ...[
          SizedBox(height: size < 40 ? 8 : 14),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: variant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  static Widget _animatedLogo({required double height}) {
    return Image.asset(
      _logoAsset,
      height: height,
      fit: BoxFit.contain,
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 320.ms)
        .scaleXY(
          begin: 0.9,
          end: 1,
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.72,
          end: 1,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}
