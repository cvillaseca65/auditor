/// Convierte el mapa `detail` del API de pendientes en filas etiqueta/valor.
List<Map<String, dynamic>> detailMapToFields({
  required Map<String, dynamic> detail,
  required String? Function(String key, dynamic value) formatValue,
  required String Function(String key) labelFor,
  List<String> preferredOrder = const [],
}) {
  final seen = <String>{};
  final fields = <Map<String, dynamic>>[];

  void add(String key, dynamic value) {
    if (key == 'display_key_order') return;
    final text = formatValue(key, value);
    if (text == null || text.isEmpty) return;
    fields.add({
      'key': key,
      'label': labelFor(key),
      'value': text,
      'raw': value,
    });
  }

  final explicitOrder = detail['display_key_order'];
  if (explicitOrder is List<dynamic>) {
    for (final rawKey in explicitOrder) {
      if (rawKey is! String) continue;
      if (!detail.containsKey(rawKey)) continue;
      seen.add(rawKey);
      add(rawKey, detail[rawKey]);
    }
  } else {
    for (final key in preferredOrder) {
      if (!detail.containsKey(key)) continue;
      seen.add(key);
      add(key, detail[key]);
    }
  }
  for (final e in detail.entries) {
    if (e.key == 'display_key_order') continue;
    if (seen.contains(e.key)) continue;
    add(e.key, e.value);
  }
  return fields;
}
