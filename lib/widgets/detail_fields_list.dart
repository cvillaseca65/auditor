import 'package:flutter/material.dart';

import '../core/widgets/mobile_detail/detail_rational_section.dart';
import '../core/widgets/mobile_detail/detail_section_card.dart';

/// Lista etiqueta / valor devuelta por la API móvil (`fields`).
class DetailFieldsList extends StatelessWidget {
  const DetailFieldsList({
    super.key,
    required this.fields,
    this.dense = false,
    this.sectionTitle = 'Detalle',
  });

  final List<dynamic> fields;
  final bool dense;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = <Map<String, dynamic>>[];
    for (final raw in fields) {
      if (raw is! Map) continue;
      final label = raw['label']?.toString() ?? '';
      final value = raw['value']?.toString() ?? '';
      if (label.isEmpty || value.isEmpty) continue;
      final key = raw['key']?.toString();
      final layout = raw['layout']?.toString();
      final row = <String, dynamic>{
        'label': label,
        'value': value,
      };
      if (key != null && key.isNotEmpty) row['key'] = key;
      if (layout != null && layout.isNotEmpty) row['layout'] = layout;
      if (raw['raw'] != null) row['raw'] = raw['raw'];
      normalized.add(row);
    }
    if (normalized.isEmpty) return const SizedBox.shrink();

    return DetailSectionCard(
      title: sectionTitle,
      icon: Icons.list_alt_outlined,
      child: DetailRationalSectionLayout(fields: normalized),
    );
  }
}
