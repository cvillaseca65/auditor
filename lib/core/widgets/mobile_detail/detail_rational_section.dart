import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'detail_field_layout.dart';
import 'detail_fields_compact.dart';
import 'detail_full_width_panel.dart';
import 'detail_meta_table.dart';

/// Sección de detalle alineada a `detail.html`: meta en tabla, textos en bloque ancho.
class DetailRationalSectionLayout extends StatelessWidget {
  const DetailRationalSectionLayout({
    super.key,
    required this.fields,
  });

  final List<Map<String, dynamic>> fields;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    final personDate = fields.where(DetailFieldLayout.isPersonDateField).toList();
    final rest = fields
        .where((f) => !DetailFieldLayout.isPersonDateField(f))
        .toList();
    final split = DetailFieldLayout.split(rest);
    if (split.isEmpty && personDate.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (split.meta.isNotEmpty)
          DetailMetaTable(
            cells: split.meta
                .map((f) => MapEntry(f['label'] as String, f['value'] as String))
                .toList(),
          ),
        if (split.meta.isNotEmpty && personDate.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (personDate.isNotEmpty)
          DetailFieldsCompactLayout(fields: personDate),
        if (personDate.isNotEmpty &&
            (split.prose.isNotEmpty || split.compact.isNotEmpty))
          const SizedBox(height: AppSpacing.md),
        if (split.meta.isNotEmpty &&
            personDate.isEmpty &&
            (split.prose.isNotEmpty || split.compact.isNotEmpty))
          const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < split.prose.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          DetailFullWidthPanel(
            label: split.prose[i]['label'] as String,
            text: split.prose[i]['value'] as String,
          ),
        ],
        if (split.compact.isNotEmpty) ...[
          if (split.meta.isNotEmpty || split.prose.isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          DetailFieldsCompactLayout(fields: split.compact),
        ],
      ],
    );
  }
}
