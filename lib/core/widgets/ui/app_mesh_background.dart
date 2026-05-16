import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/sim_theme.dart';

/// Fondo mesh con blobs en movimiento lento (fintech / dashboard moderno).
class AppMeshBackground extends StatefulWidget {
  const AppMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppMeshBackground> createState() => _AppMeshBackgroundState();
}

class _AppMeshBackgroundState extends State<AppMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF080A12) : const Color(0xFFEEF2FF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F172A), base, const Color(0xFF020617)]
                      : [
                          const Color(0xFFDBEAFE),
                          const Color(0xFFF8FAFC),
                          const Color(0xFFE2E8F0),
                        ],
                ),
              ),
            ),
            Positioned(
              top: -80 + math.sin(t) * 18,
              right: -40 + math.cos(t * 0.7) * 22,
              child: _MeshBlob(
                size: 220 + math.sin(t * 1.2) * 12,
                color: SimTheme.accentColor.withValues(alpha: isDark ? 0.22 : 0.38),
              ),
            ),
            Positioned(
              top: 120 + math.cos(t * 0.9) * 16,
              left: -60 + math.sin(t * 0.6) * 20,
              child: _MeshBlob(
                size: 180 + math.cos(t) * 10,
                color: SimTheme.primaryColor.withValues(alpha: isDark ? 0.18 : 0.22),
              ),
            ),
            Positioned(
              bottom: 80 + math.sin(t * 0.8) * 24,
              right: -20 + math.cos(t * 1.1) * 14,
              child: _MeshBlob(
                size: 160 + math.sin(t * 0.5) * 14,
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.14 : 0.2),
              ),
            ),
            Positioned(
              bottom: 200 + math.cos(t * 1.3) * 20,
              left: 40 + math.sin(t * 0.4) * 18,
              child: _MeshBlob(
                size: 120,
                color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.1 : 0.14),
              ),
            ),
            if (!isDark)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _MeshBlob extends StatelessWidget {
  const _MeshBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.1)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
