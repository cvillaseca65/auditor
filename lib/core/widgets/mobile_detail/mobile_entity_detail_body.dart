import 'package:flutter/material.dart';

import '../../../util/open_sim_url.dart';
import '../../../widgets/relations_section.dart';
import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../app_premium_card.dart';
import 'detail_attachments_section.dart';
import 'detail_rational_section.dart';
import 'detail_section_card.dart';
import 'detail_utils.dart';

/// Cuerpo de ficha móvil alineado a `detail.html` (card + meta tabla + bloques ancho completo).
class MobileEntityDetailBody extends StatelessWidget {
  const MobileEntityDetailBody({
    super.key,
    required this.title,
    this.subtitle,
    this.chips = const [],
    this.fields = const [],
    this.attachments = const [],
    this.relations = const [],
    this.simOpenUrl,
    this.openSimLabel = 'Abrir en SIM',
    this.extraSections = const [],
    this.footer,
    this.groupFields = true,
  });

  final String title;
  final String? subtitle;
  final List<String> chips;
  final List<Map<String, dynamic>> fields;
  final List<Map<String, dynamic>> attachments;
  final List<dynamic> relations;
  final String? simOpenUrl;
  final String openSimLabel;
  final List<Widget> extraSections;
  final Widget? footer;
  final bool groupFields;

  List<String> get _visibleChips {
    final sub = (subtitle ?? '').trim();
    if (sub.isEmpty) return chips;
    return chips.where((c) => c.trim() != sub).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleChips = _visibleChips;

    final List<DetailFieldSection> sections;
    if (groupFields && fields.isNotEmpty) {
      sections = groupDetailFields(fields);
    } else if (fields.isNotEmpty) {
      sections = [
        DetailFieldSection(
          title: 'Detalle',
          icon: Icons.list_alt_outlined,
          fields: fields,
        ),
      ];
    } else {
      sections = const [];
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (visibleChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: visibleChips
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              c,
                              style: ContentText.bodyMedium(context)?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailSectionCard(
              title: section.title,
              icon: section.icon,
              child: DetailRationalSectionLayout(fields: section.fields),
            ),
          ],
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DetailAttachmentsSection(files: attachments),
          ],
          ...extraSections,
          if (relations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPremiumCard(
              child: RelationsSection(relations: relations, embedded: true),
            ),
          ],
          if (simOpenUrl != null && simOpenUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openSimUrl(simOpenUrl!),
                icon: const Icon(Icons.open_in_browser),
                label: Text(openSimLabel),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}
