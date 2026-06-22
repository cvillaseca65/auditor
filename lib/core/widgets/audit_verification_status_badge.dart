import 'package:flutter/material.dart';

/// Colores de resultado de verificación legibles en claro y oscuro.
class AuditVerificationStatusStyle {
  const AuditVerificationStatusStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  static AuditVerificationStatusStyle forStatus(
    BuildContext context,
    int status,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 1:
        return isDark
            ? const AuditVerificationStatusStyle(
                // Verde vivo: debe destacar del gris pendiente y del fondo oscuro.
                background: Color(0xFF22C55E),
                foreground: Color(0xFF052E16),
                border: Color(0xFF86EFAC),
              )
            : const AuditVerificationStatusStyle(
                background: Color(0xFFD1E7DD),
                foreground: Color(0xFF0F5132),
                border: Color(0xFF75B798),
              );
      case 2:
        return isDark
            ? const AuditVerificationStatusStyle(
                background: Color(0xFFDC2626),
                foreground: Color(0xFFFFFFFF),
                border: Color(0xFFF87171),
              )
            : const AuditVerificationStatusStyle(
                background: Color(0xFFF8D7DA),
                foreground: Color(0xFF842029),
                border: Color(0xFFE899A1),
              );
      default:
        return isDark
            ? const AuditVerificationStatusStyle(
                background: Color(0xFF475569),
                foreground: Color(0xFFE2E8F0),
                border: Color(0xFF64748B),
              )
            : const AuditVerificationStatusStyle(
                background: Color(0xFFE2E3E5),
                foreground: Color(0xFF41464B),
                border: Color(0xFFC4C8CB),
              );
    }
  }
}

/// Badge Conforme / NC / Pendiente (lista del plan y detalle).
class AuditVerificationStatusBadge extends StatelessWidget {
  const AuditVerificationStatusBadge({
    super.key,
    required this.status,
    this.ncIds = const [],
    this.onNcTap,
  });

  final int status;
  final List<int> ncIds;
  final VoidCallback? onNcTap;

  String get _label {
    if (status == 1) return 'Conforme';
    if (status == 2) {
      return ncIds.isEmpty ? 'NC' : 'NC ${ncIds.join(' ')}';
    }
    return 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final style = AuditVerificationStatusStyle.forStatus(context, status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: style.border,
          width: isDark ? 1.5 : 1,
        ),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: style.foreground,
        ),
      ),
    );

    if (status == 2 && onNcTap != null) {
      return InkWell(
        onTap: onNcTap,
        borderRadius: BorderRadius.circular(4),
        child: badge,
      );
    }
    return badge;
  }
}
