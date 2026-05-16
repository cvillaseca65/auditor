import 'package:flutter/material.dart';

import '../../../util/open_sim_url.dart';
import '../../../widgets/relations_section.dart';
import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../app_premium_card.dart';
import '../ui/app_visual_kit.dart';
import 'detail_attachments_section.dart';
import 'detail_date_format.dart';
import 'detail_full_width_panel.dart';
import 'detail_meta_table.dart';
import 'detail_utils.dart';
import 'nc_timeline_section.dart';

/// Ficha NC alineada a `nc/templates/nc/nc_detail.html`.
class NcDetailBody extends StatelessWidget {
  const NcDetailBody({
    super.key,
    required this.ncId,
    required this.data,
    this.extraSections = const [],
    this.simOpenUrl,
    this.openSimLabel = 'Abrir en SIM',
  });

  final int ncId;
  final Map<String, dynamic> data;
  final List<Widget> extraSections;
  final String? simOpenUrl;
  final String openSimLabel;

  String _s(dynamic v) => (v?.toString() ?? '').trim();

  String _date(dynamic raw) {
    if (raw == null) return '';
    return DetailDateFormat.formatField('date', raw);
  }

  List<MapEntry<String, String>> _metaCells() {
    final cells = <MapEntry<String, String>>[];

    void add(String label, String value) {
      if (value.isNotEmpty) cells.add(MapEntry(label, value));
    }

    if (data['view'] != null && (data['view'] as num) > 0) {
      add('Tipo', _s(data['view_label']));
    }
    add('Grado', _s(data['type']));
    add('Origen', _s(data['origin']));
    add('Área', _s(data['area']));
    add('Localidad', _s(data['location']));
    add('Cliente', _s(data['customer']));
    add('Proveedor', _s(data['supplier']));
    add('Costo', _s(data['cost']));
    if (data['improve'] != null) {
      add('Mejora', data['improve'].toString());
    }

    final involved = data['involved_users'] as List<dynamic>? ?? [];
    if (involved.isNotEmpty) {
      add(
        'Involucrados',
        involved.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).join(', '),
      );
    }

    return cells;
  }

  List<Map<String, dynamic>> _timelineSteps() {
    final raw = data['timeline'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = _metaCells();
    final finding = _s(data['finding']);
    final observation = _s(data['observation']);
    final cause = _s(data['cause']);
    final causeType = _s(data['cause_type']);
    final binnacle = _s(data['binnacle']);
    final status = _s(data['status_label']);
    final detectDate = _date(data['date']);
    final analysisDate = _date(data['cause_date']);
    final timeline = _timelineSteps();
    final attachments = DetailUtils.normalizeAttachments(
      data['attachments'] as List<dynamic>?,
    );
    final relations = data['relations'] as List<dynamic>? ?? [];
    final accent = scheme.error;

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
                  icon: Icons.report_problem_outlined,
                  size: 44,
                  colors: [
                    accent,
                    Color.lerp(accent, scheme.primary, 0.35) ?? accent,
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hallazgo #$ncId',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                      ),
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _StatusBadge(label: status),
                      ],
                      if (detectDate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Detecta: ${_s(data['detector'])} · $detectDate',
                          style: ContentText.uiCaption(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (finding.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DetailFullWidthPanel(
              label: 'Hallazgo',
              text: finding,
              accentColor: accent,
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppPremiumCard(child: DetailMetaTable(cells: meta)),
          ],
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            NcTimelineSection(steps: timeline),
          ],
          if (causeType.isNotEmpty || cause.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Análisis de causa',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (causeType.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tipo de causa',
                      style: ContentText.fieldLabel(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      causeType,
                      style: ContentText.bodyMedium(context)?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  if (_s(data['cause_user']).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Analista: ${_s(data['cause_user'])}',
                      style: ContentText.bodyMedium(context),
                    ),
                  ],
                  if (analysisDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Fecha análisis: $analysisDate',
                      style: ContentText.uiCaption(context),
                    ),
                  ],
                  if (cause.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    SelectableText(
                      cause,
                      style: ContentText.fieldValue(context),
                    ),
                  ],
                  if (data['cause_ok'] == true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Análisis aprobado',
                      style: ContentText.bodyMedium(context)?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (observation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DetailFullWidthPanel(
              label: 'Observación',
              text: observation,
              accentColor: scheme.primary,
            ),
          ],
          if (binnacle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DetailFullWidthPanel(
              label: 'Bitácora',
              text: binnacle,
              accentColor: scheme.tertiary,
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
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: ContentText.bodyMedium(context)?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
