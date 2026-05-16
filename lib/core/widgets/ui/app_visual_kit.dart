import 'package:flutter/material.dart';

import '../../motion/app_motion_kit.dart';
import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../../theme/sim_theme.dart';

/// Badge circular con degradado y anillo.
class AppGradientIconBadge extends StatelessWidget {
  const AppGradientIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.colors,
  });

  final IconData icon;
  final double size;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ??
        [
          SimTheme.accentColor,
          SimTheme.primaryColor,
        ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}

/// Cabecera de bienvenida (hero).
class AppWelcomeBanner extends StatelessWidget {
  const AppWelcomeBanner({
    super.key,
    required this.greeting,
    required this.subtitle,
  });

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl + 6),
        child: Stack(
          children: [
            Container(
              height: 132,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E1B4B),
                    Color(0xFF312E81),
                    Color(0xFF2563EB),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 22,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppGradientIconBadge(
                    icon: Icons.waving_hand_rounded,
                    size: 52,
                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            subtitle,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera de pantalla de listado (volver + título en franja).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? SimTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: ContentText.uiCaption(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección con franja de acento.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.icon = Icons.folder_open_rounded,
    this.topPadding = 20,
    this.accentColor,
  });

  final String title;
  final int count;
  final IconData icon;
  final double topPadding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppGradientIconBadge(
                icon: icon,
                size: 38,
                colors: [accent, Color.lerp(accent, SimTheme.accentColor, 0.5)!],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, SimTheme.accentColor, 0.4)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.9),
                  accent.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de catálogo (documentos, hallazgos, normas).
class AppEntityListTile extends StatelessWidget {
  const AppEntityListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leadingIcon = Icons.article_outlined,
    this.isDelayed = false,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData leadingIcon;
  final bool isDelayed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? SimTheme.accentColor;

    final tile = AppScalePressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg + 2),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg + 2),
                border: Border.all(
                  color: isDelayed
                      ? scheme.error.withValues(alpha: 0.4)
                      : accent.withValues(alpha: 0.18),
                ),
                boxShadow: AppShadows.card(context, opacity: 0.85),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppGradientIconBadge(
                      icon: leadingIcon,
                      size: 44,
                      colors: isDelayed
                          ? [scheme.error, const Color(0xFFFB923C)]
                          : [accent, SimTheme.primaryColor],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: isDelayed
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accent.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return tile;
  }
}

/// Fila de lista premium (categoría, días/hito en pastilla, acción).
class AppActionListTile extends StatelessWidget {
  const AppActionListTile({
    super.key,
    required this.title,
    required this.leadingLabel,
    required this.onTap,
    this.subtitle,
    this.category,
    this.isDelayed = false,
    this.inApp = true,
    this.accentColor,
  });

  final String title;
  final String leadingLabel;
  final String? subtitle;
  final String? category;
  final bool isDelayed;
  final bool inApp;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ??
        (isDelayed ? const Color(0xFFDC2626) : SimTheme.accentColor);

    return AppScalePressable(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shadowColor: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg + 2),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg + 2),
              border: Border.all(
                color: isDelayed
                    ? scheme.error.withValues(alpha: 0.45)
                    : accent.withValues(alpha: 0.22),
                width: isDelayed ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppRadii.lg + 2),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.transparent, 0.7)!,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.14),
                          accent.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDelayed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Icon(
                              Icons.priority_high_rounded,
                              size: 18,
                              color: scheme.error,
                            ),
                          ),
                        Text(
                          leadingLabel,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: leadingLabel.length <= 3 ? 22 : 15,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category != null && category!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ContentText.uiLabel(context)?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.2),
                                      accent.withValues(alpha: 0.08),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  inApp
                                      ? Icons.touch_app_rounded
                                      : Icons.open_in_new_rounded,
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ContentText.uiCaption(context)?.copyWith(
                                    fontSize: AppTypography.minBodySecondary,
                                    color: isDelayed
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
