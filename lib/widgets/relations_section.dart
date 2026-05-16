import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/widgets/app_premium_card.dart';
import '../util/open_sim_url.dart';
import '../util/plain_text.dart';

/// Bloque «Relaciones» con enlaces a SIM (como `detail_relations.html`).
class RelationsSection extends StatelessWidget {
  const RelationsSection({
    super.key,
    required this.relations,
    this.title = 'Relaciones',
    this.embedded = false,
  });

  final List<dynamic> relations;
  final String title;
  /// Si va dentro de [AppPremiumCard] del detalle móvil.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...relations.map((raw) {
          final row = raw as Map<String, dynamic>;
          final type = plainText(row['type']?.toString());
          final label = plainText(row['label']?.toString());
          final url = row['url']?.toString() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.hub_outlined, size: 18, color: scheme.primary),
              ),
              title: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              subtitle: type.isNotEmpty && type != label
                  ? Text(type, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: Icon(Icons.chevron_right, color: scheme.primary),
              onTap: url.isNotEmpty ? () => openSimUrl(url) : null,
            ),
          );
        }),
      ],
    );

    if (embedded) return content;
    return AppPremiumCard(child: content);
  }
}
