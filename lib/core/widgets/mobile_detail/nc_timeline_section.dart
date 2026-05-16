import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../theme/content_text.dart';
import '../app_premium_card.dart';
import 'detail_date_format.dart';

/// Línea de tiempo NC (`nc_detail.html` tabla de etapas).
class NcTimelineSection extends StatelessWidget {
  const NcTimelineSection({
    super.key,
    required this.steps,
  });

  final List<Map<String, dynamic>> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final labelStyle = ContentText.fieldLabel(context);
    final dateStyle = ContentText.bodyMedium(context)?.copyWith(
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final captionStyle = ContentText.uiCaption(context);

    return AppPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Línea de tiempo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
            _TimelineStep(
              step: steps[i],
              labelStyle: labelStyle,
              dateStyle: dateStyle,
              captionStyle: captionStyle,
              scheme: scheme,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.labelStyle,
    required this.dateStyle,
    required this.captionStyle,
    required this.scheme,
  });

  final Map<String, dynamic> step;
  final TextStyle? labelStyle;
  final TextStyle? dateStyle;
  final TextStyle? captionStyle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final label = (step['label'] as String? ?? '').trim();
    final dateRaw = step['date'];
    final days = step['days'];
    final person = (step['person'] as String? ?? '').trim();
    final personRole = (step['person_role'] as String? ?? '').trim();

    String dateText = '—';
    if (dateRaw != null && dateRaw.toString().trim().isNotEmpty) {
      final formatted = DetailDateFormat.formatField('date', dateRaw);
      dateText = formatted.isNotEmpty ? formatted : dateRaw.toString();
    }

    String? daysText;
    if (days is int) {
      daysText = '$days día${days == 1 ? '' : 's'}';
    } else if (days is num) {
      final d = days.toInt();
      daysText = '$d día${d == 1 ? '' : 's'}';
    }

    String? personLine;
    if (person.isNotEmpty) {
      personLine = personRole.isNotEmpty ? '$personRole: $person' : person;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Text(dateText, style: dateStyle),
        if (daysText != null) ...[
          const SizedBox(height: 2),
          Text(daysText, style: captionStyle),
        ],
        if (personLine != null) ...[
          const SizedBox(height: 4),
          Text(
            personLine,
            style: ContentText.bodyMedium(context)?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
