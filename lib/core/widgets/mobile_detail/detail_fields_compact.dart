import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import 'detail_date_format.dart';
import 'detail_field_layout.dart';

/// Celda de detalle para rejilla móvil (2 columnas en pantallas estrechas).
class DetailLayoutItem {
  const DetailLayoutItem({
    required this.label,
    required this.value,
    this.primary,
    this.secondary,
    this.fullWidth = false,
    this.emphasizeValue = false,
    this.key,
    this.periodStartRaw,
    this.periodEndRaw,
  });

  final String label;
  final String value;
  final String? primary;
  final String? secondary;
  final bool fullWidth;
  final bool emphasizeValue;
  final String? key;
  final String? periodStartRaw;
  final String? periodEndRaw;

  bool get isComposite => (secondary ?? '').trim().isNotEmpty;

  bool get isStartEndPeriod =>
      (periodStartRaw ?? '').trim().isNotEmpty &&
      (periodEndRaw ?? '').trim().isNotEmpty;
}

const _gridSkipKeys = {'display_key_order'};

bool _fieldFullWidth(Map<String, dynamic> f) =>
    DetailFieldLayout.isFullWidthField(f);

/// Prepara filas API en celdas compactas (composites + ancho completo).
List<DetailLayoutItem> buildCompactLayoutItems(List<Map<String, dynamic>> fields) {
  final byKey = <String, Map<String, dynamic>>{};
  for (final f in fields) {
    final k = f['key'] as String?;
    if (k != null && k.isNotEmpty) byKey[k] = f;
  }

  final used = <String>{};
  final usedLabels = <String>{};
  final out = <DetailLayoutItem>[];

  String v(String key) => byKey[key]?['value'] as String? ?? '';

  dynamic raw(String key) => byKey[key]?['raw'] ?? byKey[key]?['value'];

  void useKeys(Iterable<String> keys) {
    for (final k in keys) {
      used.add(k);
    }
  }

  String? formatRawDate(dynamic rawVal) {
    if (rawVal == null) return null;
    final s = rawVal.toString().trim();
    if (s.isEmpty) return null;
    return DetailDateFormat.formatField('date', s);
  }

  DetailLayoutItem? tryPersonDateField(Map<String, dynamic> f, String key) {
    final label = f['label'] as String? ?? '';
    if (label.isEmpty) return null;
    final primary = (f['value'] as String? ?? '').trim();
    final secondary = formatRawDate(f['raw']);
    if (primary.isEmpty && (secondary ?? '').isEmpty) return null;
    useKeys([key]);
    final name = primary.isEmpty ? '—' : primary;
    return DetailLayoutItem(
      key: key,
      label: label,
      value: name,
      primary: name,
      secondary: secondary,
    );
  }

  DetailLayoutItem? tryLabelPersonDate({
    required String personLabel,
    required String dateLabel,
    required String compositeLabel,
    required String compositeKey,
  }) {
    if (usedLabels.contains(personLabel)) return null;
    Map<String, dynamic>? personField;
    Map<String, dynamic>? dateField;
    for (final f in fields) {
      final k = f['key'] as String?;
      if (k != null && used.contains(k)) continue;
      final l = f['label'] as String? ?? '';
      if (l == personLabel) personField = f;
      if (l == dateLabel) dateField = f;
    }
    if (personField == null) return null;
    final primary = (personField['value'] as String? ?? '').trim();
    if (primary.isEmpty) return null;
    final secondary = formatRawDate(dateField?['raw'] ?? dateField?['value']);
    usedLabels.add(personLabel);
    usedLabels.add(dateLabel);
    final pk = personField['key'] as String?;
    if (pk != null && pk.isNotEmpty) used.add(pk);
    final dk = dateField?['key'] as String?;
    if (dk != null && dk.isNotEmpty) used.add(dk);
    return DetailLayoutItem(
      key: compositeKey,
      label: compositeLabel,
      value: primary,
      primary: primary,
      secondary: secondary,
    );
  }

  DetailLayoutItem? tryComposite({
    required String label,
    required String primaryKey,
    String? secondaryKey,
    String Function(String secondaryValue)? formatSecondary,
  }) {
    if (!byKey.containsKey(primaryKey)) return null;
    final primary = v(primaryKey).trim();
    if (primary.isEmpty) return null;
    var secondary = '';
    if (secondaryKey != null && byKey.containsKey(secondaryKey)) {
      secondary = v(secondaryKey).trim();
      if (formatSecondary != null && secondary.isNotEmpty) {
        secondary = formatSecondary(secondary);
      }
    }
    useKeys([primaryKey, if (secondaryKey != null) secondaryKey]);
    return DetailLayoutItem(
      key: primaryKey,
      label: label,
      value: primary,
      primary: primary,
      secondary: secondary.isEmpty ? null : secondary,
    );
  }

  for (final legacy in [
    tryLabelPersonDate(
      personLabel: 'Creador',
      dateLabel: 'Creación',
      compositeLabel: 'Crea',
      compositeKey: 'doc_creator_legacy',
    ),
    tryLabelPersonDate(
      personLabel: 'Editor',
      dateLabel: 'Edición',
      compositeLabel: 'Edición',
      compositeKey: 'doc_editor_legacy',
    ),
    tryLabelPersonDate(
      personLabel: 'Solicitante',
      dateLabel: 'Solicitud',
      compositeLabel: 'Solicitud',
      compositeKey: 'doc_solicitation_legacy',
    ),
  ]) {
    if (legacy != null) out.add(legacy);
  }

  for (final f in fields) {
    final key = f['key'] as String?;
    if (key == null || key.isEmpty) {
      final label = f['label'] as String? ?? '';
      if (usedLabels.contains(label)) continue;
      final value = f['value'] as String? ?? '';
      if (label.isEmpty || value.isEmpty) continue;
      out.add(
        DetailLayoutItem(
          label: label,
          value: value,
          fullWidth: _fieldFullWidth(f),
        ),
      );
      continue;
    }
    if (_gridSkipKeys.contains(key) || used.contains(key)) continue;

    if (key.startsWith('doc_') || f['layout'] == 'person_date') {
      final item = tryPersonDateField(f, key);
      if (item != null) {
        out.add(item);
        continue;
      }
    }

    if (key == 'creator') {
      final item = tryComposite(
        label: 'Crea',
        primaryKey: 'creator',
        secondaryKey: 'create',
        formatSecondary: (s) => formatRawDate(s) ?? s,
      );
      if (item != null) {
        out.add(item);
        continue;
      }
    }
    if (key == 'create') continue;

    if (key == 'executor') {
      final item = tryComposite(
        label: 'Ejecución',
        primaryKey: 'executor',
        secondaryKey: 'execution',
      );
      if (item != null) {
        out.add(item);
        continue;
      }
    }
    if (key == 'execution') continue;

    if (key == 'editor') {
      final item = tryComposite(
        label: 'Edición',
        primaryKey: 'editor',
        secondaryKey: 'edit',
        formatSecondary: (s) => formatRawDate(s) ?? s,
      );
      if (item != null) {
        out.add(item);
        continue;
      }
    }
    if (key == 'edit') continue;

    if (key == 'end') {
      final endVal = v('end').trim();
      final daysRaw = v('deadline_days').trim();
      if (endVal.isNotEmpty) {
        useKeys(['end', 'deadline_days', 'deatline']);
        final days = int.tryParse(daysRaw);
        out.add(
          DetailLayoutItem(
            key: 'end',
            label: 'Plazo',
            value: endVal,
            primary: endVal,
            secondary: days != null ? '$days días' : (daysRaw.isNotEmpty ? daysRaw : null),
          ),
        );
        continue;
      }
    }
    if (key == 'deadline_days' || key == 'deatline') continue;

    if (key == 'start' &&
        byKey.containsKey('end') &&
        !byKey.containsKey('deadline_days')) {
      final startRaw = raw('start');
      final endRaw = raw('end');
      if (startRaw != null &&
          endRaw != null &&
          startRaw.toString().trim().isNotEmpty &&
          endRaw.toString().trim().isNotEmpty) {
        useKeys(['start', 'end', 'deadline_days', 'deatline']);
        out.add(
          DetailLayoutItem(
            key: 'start',
            label: '',
            value: '',
            fullWidth: true,
            periodStartRaw: startRaw.toString(),
            periodEndRaw: endRaw.toString(),
          ),
        );
        continue;
      }
    }

    final label = f['label'] as String? ?? '';
    final value = f['value'] as String? ?? '';
    if (label.isEmpty || value.isEmpty) continue;

    final full = _fieldFullWidth(f);
    final emphasize = key == 'subject' || key == 'title';

    out.add(
      DetailLayoutItem(
        key: key,
        label: label,
        value: value,
        fullWidth: full,
        emphasizeValue: emphasize && !full,
      ),
    );
  }

  return out;
}

/// Rejilla 2 columnas + bloques anchos; fusiona creador/fecha, ejecutor/fecha, etc.
class DetailFieldsCompactLayout extends StatelessWidget {
  const DetailFieldsCompactLayout({
    super.key,
    required this.fields,
  });

  final List<Map<String, dynamic>> fields;

  @override
  Widget build(BuildContext context) {
    final items = buildCompactLayoutItems(fields);
    if (items.isEmpty) return const SizedBox.shrink();

    final hero = items.where((i) => i.key == 'subject' && i.fullWidth).toList();
    final periods = items.where((i) => i.isStartEndPeriod).toList();
    final full = items
        .where((i) => i.fullWidth && i.key != 'subject' && !i.isStartEndPeriod)
        .toList();
    final grid = items
        .where((i) => !i.fullWidth && i.key != 'subject' && !i.isStartEndPeriod)
        .toList();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in hero) ...[
          _FullWidthBlock(item: h, hero: true),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final p in periods) ...[
          DetailStartEndPeriodRow(
            startRaw: p.periodStartRaw!,
            endRaw: p.periodEndRaw!,
            scheme: scheme,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (grid.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.xs;
              final cellW = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in grid)
                    SizedBox(
                      width: cellW,
                      child: _GridCell(item: item, scheme: scheme),
                    ),
                ],
              );
            },
          ),
        for (var i = 0; i < full.length; i++) ...[
          SizedBox(height: i == 0 && grid.isNotEmpty ? AppSpacing.md : AppSpacing.sm),
          _FullWidthBlock(item: full[i]),
        ],
      ],
    );
  }
}

/// Inicio y término en dos columnas (minutas, periodos).
class DetailStartEndPeriodRow extends StatelessWidget {
  const DetailStartEndPeriodRow({
    required this.startRaw,
    required this.endRaw,
    required this.scheme,
  });

  final String startRaw;
  final String endRaw;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.primaryContainer.withValues(alpha: 0.28),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PeriodColumn(
                  title: 'Fecha de inicio',
                  raw: startRaw,
                  fieldKey: 'start',
                  scheme: scheme,
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: scheme.outlineVariant.withValues(alpha: 0.85),
              ),
              Expanded(
                child: _PeriodColumn(
                  title: 'Término',
                  raw: endRaw,
                  fieldKey: 'end',
                  scheme: scheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodColumn extends StatelessWidget {
  const _PeriodColumn({
    required this.title,
    required this.raw,
    required this.fieldKey,
    required this.scheme,
  });

  final String title;
  final String raw;
  final String fieldKey;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final value = DetailDateFormat.formatField(fieldKey, raw);
    final caption = DetailDateFormat.valueCaption(fieldKey, raw);
    final labelStyle = ContentText.fieldLabel(context)?.copyWith(
          color: scheme.primary,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: labelStyle),
        const SizedBox(height: 6),
        Text(
          value,
          style: ContentText.bodyMedium(context)?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(
            caption,
            style: ContentText.uiCaption(context)?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.item, required this.scheme});

  final DetailLayoutItem item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final labelStyle = ContentText.fieldLabel(context)?.copyWith(
          color: scheme.primary,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.primaryContainer.withValues(alpha: 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: item.isComposite
            ? _CompositeBody(item: item, labelStyle: labelStyle)
            : _ShortBody(item: item, labelStyle: labelStyle),
      ),
    );
  }
}

class _CompositeBody extends StatelessWidget {
  const _CompositeBody({required this.item, required this.labelStyle});

  final DetailLayoutItem item;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    final name = item.primary ?? item.value;
    final nameStyle = ContentText.bodyMedium(context)?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: '${item.label}: '),
              TextSpan(text: name, style: nameStyle),
            ],
          ),
        ),
        if (item.secondary != null) ...[
          const SizedBox(height: 3),
          Text(
            item.secondary!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ContentText.uiCaption(context)?.copyWith(
                  color: variant,
                ),
          ),
        ],
      ],
    );
  }
}

class _ShortBody extends StatelessWidget {
  const _ShortBody({required this.item, required this.labelStyle});

  final DetailLayoutItem item;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.label, style: labelStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(
          item.value,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: ContentText.bodyMedium(context)?.copyWith(
            fontWeight: item.emphasizeValue ? FontWeight.w700 : FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _FullWidthBlock extends StatelessWidget {
  const _FullWidthBlock({required this.item, this.hero = false});

  final DetailLayoutItem item;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = ContentText.fieldLabel(context);
    final valueStyle = hero
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.3,
            )
        : ContentText.fieldValue(context);

    if (item.isComposite) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _CompositeBody(
            item: item,
            labelStyle: ContentText.fieldLabel(context),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.label, style: labelStyle),
        const SizedBox(height: 6),
        SelectableText(item.value, style: valueStyle),
      ],
    );
  }
}
