import 'package:flutter/material.dart';

import '../../theme/content_text.dart';

/// Bloque de lectura a ancho completo (hallazgo, observación, descripción larga).
class DetailProseBlock extends StatelessWidget {
  const DetailProseBlock({
    super.key,
    required this.text,
    this.minHeight = 0,
  });

  final String text;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final valueStyle = ContentText.fieldValue(context);
    final child = SelectableText(
      text.trim(),
      style: valueStyle,
    );

    if (minHeight <= 0) return child;

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      ),
    );
  }
}
