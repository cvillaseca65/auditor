// lib/core/utils/date_utils.dart

class DateUtilsApp {
  /// Convierte un ISO string con timezone (ej: 2025-03-27T10:26:14-03:00)
  /// a hora local del dispositivo y lo formatea dd/MM/yy HH:mm
  static String formatMoment(String momentString) {
    final date = DateTime.parse(momentString).toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  /// Fecha y hora local para saludo en inicio (día/mes/año hora:min).
  static String formatNowLocal() {
    final date = DateTime.now();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
