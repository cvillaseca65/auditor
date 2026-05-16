/// Formato de fechas del detalle móvil (alineado a DateTimeField en SIM).
abstract final class DetailDateFormat {
  static const _dateTimeKeys = {
    'start',
    'end',
    'create',
    'execution',
    'verification',
    'edit',
    'date',
  };

  /// Claves cuyo valor debe mostrarse siempre con hora cuando es [DateTime].
  static const _forceTimeKeys = {
    'end',
    'execution',
    'verification',
  };

  static DateTime? tryParse(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static bool rawHasClockTime(String raw) {
    final s = raw.trim();
    if (!s.contains('T') && !s.contains(' ')) return false;
    final dt = DateTime.tryParse(s);
    if (dt == null) return false;
    return dt.hour != 0 || dt.minute != 0 || dt.second != 0 || dt.millisecond != 0;
  }

  static String formatDatePart(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String formatTimePart(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Texto para mostrar al usuario; incluye hora si el dato la trae o la clave lo exige.
  static String formatField(String key, dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    if (s.isEmpty) return '';

    final dt = tryParse(raw);
    if (dt == null) return s;

    if (!_dateTimeKeys.contains(key)) {
      return formatDatePart(dt);
    }

    final forceTime = _forceTimeKeys.contains(key);
    final showTime = forceTime || rawHasClockTime(s);

    if (!showTime) {
      return formatDatePart(dt);
    }
    return '${formatDatePart(dt)} ${formatTimePart(dt)}';
  }

  /// Etiqueta secundaria bajo el valor (p. ej. «Fecha y hora»).
  static String? valueCaption(String key, dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    if (!_dateTimeKeys.contains(key)) return null;
    if (tryParse(raw) == null) return null;

    final forceTime = _forceTimeKeys.contains(key);
    final showTime = forceTime || rawHasClockTime(s);
    if (!showTime) return 'Fecha';
    return 'Fecha y hora';
  }
}
