import 'package:flutter/material.dart';

import '../util/plain_text.dart';

/// Lista etiqueta / valor devuelta por la API móvil (`fields`).
class DetailFieldsList extends StatelessWidget {
  const DetailFieldsList({
    super.key,
    required this.fields,
    this.dense = false,
  });

  final List<dynamic> fields;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final raw in fields) ...[
          if (raw is Map) ...[
            Padding(
              padding: EdgeInsets.only(bottom: dense ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plainText(raw['label']?.toString()),
                    style: labelStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plainText(raw['value']?.toString()),
                    style: valueStyle,
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
