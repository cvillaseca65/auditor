import 'package:flutter/material.dart';

import '../util/open_sim_url.dart';
import '../util/plain_text.dart';

/// Bloque «Relaciones» con enlaces a SIM (datos de la API móvil).
class RelationsSection extends StatelessWidget {
  const RelationsSection({
    super.key,
    required this.relations,
    this.title = 'Relaciones',
  });

  final List<dynamic> relations;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...relations.map((raw) {
          final row = raw as Map<String, dynamic>;
          final label = plainText(row['label']?.toString());
          final url = row['url']?.toString() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: url.isNotEmpty ? () => openSimUrl(url) : null,
            ),
          );
        }),
      ],
    );
  }
}
