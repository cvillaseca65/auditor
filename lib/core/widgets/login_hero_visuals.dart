import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/sim_theme.dart';

/// Hero de login: imagen de ambiente + velado para texto legible.
/// Si no carga la red, se muestra un fallback con gradiente de marca.
class LoginHeroBackdrop extends StatelessWidget {
  const LoginHeroBackdrop({
    super.key,
    this.compact = false,
    this.cornerRadius = 0,
  });

  /// Móvil: altura fija; escritorio: rellena el panel lateral.
  final bool compact;
  final double cornerRadius;

  /// Imagen corporativa / trabajo en equipo (ancho fijo para caché CDN).
  static const String imageUrl =
      'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1600&q=85';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.15),
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const _LoginPhotoFallback(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: compact ? 0.38 : 0.5),
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: compact ? 0.62 : 0.78),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            compact ? AppSpacing.lg : AppSpacing.xl,
            AppSpacing.lg,
            compact ? AppSpacing.lg + 4 : AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.16),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: compact ? 56 : 68,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(
                          Icons.verified_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: compact ? 44 : 52,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIM Auditor',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.05,
                                fontSize: compact ? 22 : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cumplimiento y trabajo en campo',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Pendientes, hallazgos, documentos y normativa en un solo flujo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: compact
          ? SizedBox(height: 288, width: double.infinity, child: content)
          : content,
    );
  }
}

class _LoginPhotoFallback extends StatelessWidget {
  const _LoginPhotoFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SimTheme.primaryColor,
            Color.lerp(SimTheme.primaryColor, SimTheme.accentColor, 0.35)!,
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.groups_2_rounded,
          size: 88,
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
