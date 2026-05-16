import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Texto de valor de producto (un solo lugar en el hero de login).
const String kLoginProductTagline =
    'Pendientes, hallazgos, documentos y normativa en un solo flujo.';

/// Fondo del PNG `logo_hero.png` (simfour_invertido en SIM web).
const Color kLoginHeroLogoBackground = Color(0xFF7C6FFA);

/// Hero de login: fondo morado de marca (mismo tono que `logo_hero.png`).
class LoginHeroBackdrop extends StatelessWidget {
  const LoginHeroBackdrop({
    super.key,
    this.compact = false,
    this.cornerRadius = 0,
  });

  final bool compact;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        const _LoginConceptualBackdrop(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: compact ? AppSpacing.md : AppSpacing.xl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? 340 : 420,
                    ),
                    child: _LoginBrandColumn(
                      compact: compact,
                      showTagline: !compact || constraints.maxHeight >= 168,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: content,
    );
  }
}

/// Logo + Compliance Software + tagline (centrado).
class _LoginBrandColumn extends StatelessWidget {
  const _LoginBrandColumn({
    required this.compact,
    this.showTagline = true,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final taglineStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.82),
          height: 1.4,
          fontWeight: FontWeight.w500,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LoginLogoSpotlight(compact: compact),
        SizedBox(height: compact ? 14 : 24),
        Text(
          'Compliance Software',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.15,
                fontSize: compact ? 20 : 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
        ),
        if (showTagline) ...[
          SizedBox(height: compact ? 8 : 16),
          Text(
            kLoginProductTagline,
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: taglineStyle?.copyWith(
                  fontSize: compact ? 12 : null,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }
}

/// Logo SIM4 centrado sobre el hero oscuro (sin halo ni recuadro).
class _LoginLogoSpotlight extends StatelessWidget {
  const _LoginLogoSpotlight({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoHeight = compact ? 112.0 : 180.0;

    return Image.asset(
      'assets/images/logo_hero.png',
      height: logoHeight,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/logo.png',
        height: logoHeight,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LoginConceptualBackdrop extends StatelessWidget {
  const _LoginConceptualBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kLoginHeroLogoBackground,
      child: CustomPaint(
        painter: _LoginAuditBackdropPainter(),
      ),
    );
  }
}

class _LoginAuditBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGrid(canvas, size);

    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawChecklist(canvas, Offset(w * 0.78, h * 0.62), 0.85, iconPaint);
    _drawShield(canvas, Offset(w * 0.14, h * 0.22), 0.7, iconPaint);
    _drawDocumentStack(canvas, Offset(w * 0.58, h * 0.18), 0.6, iconPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    const step = 32.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawChecklist(Canvas canvas, Offset origin, double scale, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    const box = 22.0;
    for (var i = 0; i < 4; i++) {
      final y = i * 34.0;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, box, box),
        const Radius.circular(5),
      );
      canvas.drawRRect(r, paint);
      canvas.drawLine(
        Offset(box + 10, y + box / 2),
        Offset(box + 88, y + box / 2),
        paint,
      );
    }
    canvas.restore();
  }

  void _drawShield(Canvas canvas, Offset origin, double scale, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final path = Path()
      ..moveTo(40, 8)
      ..lineTo(72, 18)
      ..lineTo(72, 48)
      ..quadraticBezierTo(72, 78, 40, 92)
      ..quadraticBezierTo(8, 78, 8, 48)
      ..lineTo(8, 18)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawDocumentStack(Canvas canvas, Offset origin, double scale, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(i * 10.0, i * 8.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 56, 72),
          const Radius.circular(6),
        ),
        paint,
      );
      for (var line = 0; line < 4; line++) {
        canvas.drawLine(
          Offset(12, 18 + line * 14.0),
          Offset(44, 18 + line * 14.0),
          paint,
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoginAuditBackdropPainter oldDelegate) => false;
}
