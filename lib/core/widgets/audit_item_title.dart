import 'package:flutter/material.dart';

import '../../util/open_sim_url.dart';
import '../../util/strip_html.dart';

/// Nombre del punto sin prefijo de tipo (usa [point_label] del API si existe).
String auditItemPointLabel(Map<String, dynamic> item) {
  final fromApi = item['point_label']?.toString().trim() ?? '';
  if (fromApi.isNotEmpty) return fromApi;
  final label = item['label']?.toString().trim() ?? '';
  if (label.isNotEmpty) return label;
  return stripHtml(item['audit_title']?.toString()).trim();
}

Widget _pointText(
  BuildContext context,
  Map<String, dynamic> item, {
  TextStyle? linkStyle,
}) {
  final scopeKind = item['scope_kind']?.toString() ?? '';
  final detailUrl = item['detail_url']?.toString().trim() ?? '';
  final pointLabel = auditItemPointLabel(item);
  final bodyStyle = const TextStyle(fontSize: 14);

  if (scopeKind == 'observation') {
    final obs = stripHtml(item['observation_html']?.toString());
    if (obs.isNotEmpty) {
      return Text(
        obs,
        style: bodyStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      );
    }
  }

  if (detailUrl.isNotEmpty && pointLabel.isNotEmpty) {
    return InkWell(
      onTap: () => openSimUrl(detailUrl),
      child: Text(
        pointLabel,
        style: linkStyle ?? bodyStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  return Text(
    pointLabel,
    style: bodyStyle,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
  );
}

/// Solo el nombre del punto (el tipo va en la columna Tema si aplica).
Widget buildAuditItemTitle(BuildContext context, Map<String, dynamic> item) {
  final scheme = Theme.of(context).colorScheme;
  return _pointText(
    context,
    item,
    linkStyle: TextStyle(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary.withValues(alpha: 0.5),
    ),
  );
}

/// Cabecera de verificación: solo el registro auditado con enlace.
Widget buildAuditItemTopicHeader(
  BuildContext context,
  Map<String, dynamic> item,
) {
  final detailUrl = item['detail_url']?.toString().trim() ?? '';
  final pointLabel = auditItemPointLabel(item);
  final scheme = Theme.of(context).colorScheme;
  final linkStyle = TextStyle(
    color: scheme.primary,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    decoration: TextDecoration.underline,
    decorationColor: scheme.primary.withValues(alpha: 0.5),
  );

  if (detailUrl.isNotEmpty && pointLabel.isNotEmpty) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        InkWell(
          onTap: () => openSimUrl(detailUrl),
          child: Text(pointLabel, style: linkStyle),
        ),
        IconButton(
          tooltip: 'Revisar en SIM (web)',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.open_in_new, size: 18, color: scheme.primary),
          onPressed: () => openSimUrl(detailUrl),
        ),
      ],
    );
  }

  return _pointText(context, item);
}
