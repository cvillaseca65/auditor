/// Utilidades para ordenar listas por “plazo” como número (días hasta vencimiento).
///
/// Valores negativos = días de atraso. Orden ascendente numérico (primero −10),
/// sin orden léxico de strings en el texto de alerta.
library;

DateTime _localMidnight(DateTime dt) {
  final l = dt.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Días naturales hasta la fecha [iso] (solo fecha); negativo si ya pasó.
int? plazoDaysFromEndIso(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return null;
  final end = _localMidnight(parsed);
  final today = _localMidnight(DateTime.now());
  return end.difference(today).inDays;
}

final _signedInt = RegExp(r'-?\d+');

/// Primer entero con signo “plausible” en texto de alerta (evita años tipo 2025).
int? plazoDaysFromAlertText(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  for (final m in _signedInt.allMatches(t)) {
    final v = int.tryParse(m.group(0)!);
    if (v == null) continue;
    if (v >= 1900 && v <= 2100) continue;
    return v;
  }
  return null;
}

/// Prioriza fecha fin del API; si falta, intenta extraer días del texto de alerta.
int? pendingPlazoDays({required String? endIso, required String alertText}) {
  final fromEnd = plazoDaysFromEndIso(endIso);
  if (fromEnd != null) return fromEnd;
  return plazoDaysFromAlertText(alertText);
}

/// Orden ascendente por días de plazo: primero las más atrasadas (ej. −10 antes
/// que −2 antes que +5). Las sin plazo conocido van al final.
int comparePlazoAscendingNullable(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  final c = a.compareTo(b);
  if (c != 0) return c;
  return 0;
}
