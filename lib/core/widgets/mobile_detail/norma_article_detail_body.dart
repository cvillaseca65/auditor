import 'package:flutter/material.dart';

import '../../../widgets/relations_section.dart';
import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../app_premium_card.dart';
import '../ui/app_visual_kit.dart';
import 'detail_meta_table.dart';
import 'detail_prose_block.dart';
import 'detail_section_card.dart';

/// Artículo / cumplimiento normativo (`requirement_detail.html`).
class NormaArticleDetailBody extends StatelessWidget {
  const NormaArticleDetailBody({
    super.key,
    required this.data,
    this.footer,
  });

  final Map<String, dynamic> data;
  final Widget? footer;

  String _s(dynamic v) => (v?.toString() ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = _s(data['index']);
    final title = _s(data['title']);
    final status = _s(data['comply_status_label']);
    final requirement = _s(data['requirement']);
    final complyText = _s(data['comply_text']);
    final responsible = _s(data['responsible']);
    final relations = data['relations'] as List<dynamic>? ?? [];

    return AppScreenBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          AppPremiumCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppGradientIconBadge(
                  icon: Icons.gavel_outlined,
                  size: 44,
                  colors: [
                    scheme.primary,
                    Color.lerp(scheme.primary, scheme.tertiary, 0.45) ??
                        scheme.primary,
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index.isNotEmpty)
                        Text(
                          'Índice: $index',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                      if (title.isNotEmpty) ...[
                        if (index.isNotEmpty) const SizedBox(height: 4),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                        ),
                      ],
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            status,
                            style: ContentText.bodyMedium(context)?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (responsible.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPremiumCard(
              child: DetailMetaTable(
                cells: [MapEntry('Responsable', responsible)],
              ),
            ),
          ],
          if (requirement.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailSectionCard(
              title: 'Requisito',
              icon: Icons.article_outlined,
              child: DetailProseBlock(text: requirement),
            ),
          ],
          if (complyText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailSectionCard(
              title: 'Cumplimiento',
              icon: Icons.fact_check_outlined,
              child: DetailProseBlock(text: complyText),
            ),
          ],
          if (relations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPremiumCard(
              child: RelationsSection(relations: relations, embedded: true),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
