import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';

/// Tabla resumen superior (código, tipo, área…) como la primera tabla de document_detail.
class DetailMetaTable extends StatelessWidget {
  const DetailMetaTable({super.key, required this.cells});

  /// Pares etiqueta / valor cortos (máx. 6).
  final List<MapEntry<String, String>> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final border = BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.9),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(border),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: scheme.surfaceContainerLow,
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: border,
          verticalInside: border,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _rows(context),
      ),
    );
  }

  List<TableRow> _rows(BuildContext context) {
    final labelStyle = ContentText.fieldLabel(context);
    final valueStyle = ContentText.bodyMedium(context)?.copyWith(
          fontSize: ContentText.bodyMediumSize,
          height: 1.35,
        );

    final rows = <TableRow>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(
        TableRow(
          children: [
            _cell(cells[i].key, cells[i].value, labelStyle, valueStyle),
            if (i + 1 < cells.length)
              _cell(cells[i + 1].key, cells[i + 1].value, labelStyle, valueStyle)
            else
              const SizedBox(),
          ],
        ),
      );
    }
    return rows;
  }

  Widget _cell(
    String label,
    String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          Text(
            value,
            style: valueStyle,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
