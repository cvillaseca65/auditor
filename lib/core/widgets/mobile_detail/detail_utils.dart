import 'package:flutter/material.dart';

import '../../../util/plain_text.dart';

/// Utilidades compartidas para fichas tipo `detail.html` de SIM.
abstract final class DetailUtils {
  static bool isImageUrl(String url, {String? name}) {
    final probe = '${url.toLowerCase()} ${name?.toLowerCase() ?? ''}';
    return RegExp(
      r'\.(jpe?g|png|gif|webp|bmp|heic|svg)(\?|#|$)',
      caseSensitive: false,
    ).hasMatch(probe);
  }

  static bool isPdfUrl(String url, {String? name}) {
    final probe = '${url.toLowerCase()} ${name?.toLowerCase() ?? ''}';
    return RegExp(r'\.pdf(\?|#|$)', caseSensitive: false).hasMatch(probe);
  }

  /// Descripción del adjunto tal como en SIM (sin nombre de storage AWS).
  static String attachmentDescription(Map<String, dynamic> file) {
    return plainText(file['description']?.toString());
  }

  /// Título visible / visor: solo descripción o genérico (nunca el nombre en S3/EC2).
  static String attachmentDisplayTitle(Map<String, dynamic> file) {
    final desc = attachmentDescription(file);
    if (desc.isNotEmpty) return desc;
    return 'Archivo adjunto';
  }

  static String attachmentLabel(Map<String, dynamic> file) =>
      attachmentDisplayTitle(file);

  static List<Map<String, dynamic>> normalizeAttachments(List<dynamic>? raw) {
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => (e['url']?.toString() ?? '').isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> normalizeFields(List<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final label = plainText(item['label']?.toString());
      final value = plainText(item['value']?.toString());
      final key = plainText(item['key']?.toString());
      final raw = item['raw'];
      final layout = plainText(item['layout']?.toString());
      final hasRaw = raw != null && raw.toString().trim().isNotEmpty;
      if (label.isEmpty) continue;
      if (value.isEmpty && !hasRaw && key.isEmpty) continue;
      final row = <String, dynamic>{'label': label, 'value': value};
      if (key.isNotEmpty) row['key'] = key;
      if (hasRaw) row['raw'] = raw;
      if (layout.isNotEmpty) row['layout'] = layout;
      out.add(row);
    }
    return out;
  }
}

class DetailFieldSection {
  const DetailFieldSection({
    required this.title,
    required this.fields,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Map<String, dynamic>> fields;
}

/// Agrupa campos planos de la API en secciones como en `document_detail.html`.
List<DetailFieldSection> groupDetailFields(List<Map<String, dynamic>> fields) {
  const metaLabels = {
    'Código',
    'Versión',
    'Tipo',
    'Título',
    'Área',
    'Crea',
    'Solicitud',
    'Edición',
    'Eliminación',
    'Vista',
    'Estado',
    'Publicación',
    'Versión anterior',
  };
  const processLabels = {'Objetivo', 'Alcance', 'Recursos'};
  const recordLabels = {
    'Retención',
    'Recuperación',
    'Almacenaje',
    'Disposición',
    'Protección',
  };
  const contentLabels = {
    'Descripción',
    'Definiciones',
    'Contenido',
    'Observación',
  };

  final meta = <Map<String, dynamic>>[];
  final process = <Map<String, dynamic>>[];
  final record = <Map<String, dynamic>>[];
  final content = <Map<String, dynamic>>[];
  final publication = <Map<String, dynamic>>[];
  final other = <Map<String, dynamic>>[];

  for (final f in fields) {
    final label = f['label'] as String;
    final key = f['key'] as String? ?? '';
    if (key.startsWith('doc_pub_')) {
      publication.add(f);
    } else if (key.startsWith('doc_')) {
      meta.add(f);
    } else if (metaLabels.contains(label)) {
      meta.add(f);
    } else if (label.startsWith('Publicador') || label.startsWith('Publicación ')) {
      publication.add(f);
    } else if (processLabels.contains(label)) {
      process.add(f);
    } else if (recordLabels.contains(label)) {
      record.add(f);
    } else if (contentLabels.contains(label)) {
      content.add(f);
    } else {
      other.add(f);
    }
  }

  final sections = <DetailFieldSection>[];
  if (meta.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Ficha del registro',
        icon: Icons.article_outlined,
        fields: meta,
      ),
    );
  }
  if (publication.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Publicación',
        icon: Icons.publish_outlined,
        fields: publication,
      ),
    );
  }
  if (process.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Proceso',
        icon: Icons.account_tree_outlined,
        fields: process,
      ),
    );
  }
  if (record.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Registro',
        icon: Icons.inventory_2_outlined,
        fields: record,
      ),
    );
  }
  if (content.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Contenido',
        icon: Icons.menu_book_outlined,
        fields: content,
      ),
    );
  }
  if (other.isNotEmpty) {
    sections.add(
      DetailFieldSection(
        title: 'Información adicional',
        icon: Icons.info_outline,
        fields: other,
      ),
    );
  }
  return sections;
}
