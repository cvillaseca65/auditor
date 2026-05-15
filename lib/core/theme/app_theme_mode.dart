import 'package:flutter/material.dart';

/// Expone [ValueNotifier] de [ThemeMode] a descendientes (p. ej. barra SIM).
class AppThemeMode extends InheritedWidget {
  const AppThemeMode({
    super.key,
    required this.notifier,
    required super.child,
  });

  final ValueNotifier<ThemeMode> notifier;

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeMode>();
    assert(scope != null, 'AppThemeMode no encontrado sobre este contexto');
    return scope!.notifier;
  }

  /// Sin registro en el árbol de dependencias (p. ej. tests aislados).
  static ValueNotifier<ThemeMode>? maybeOf(BuildContext context) {
    final el = context.getElementForInheritedWidgetOfExactType<AppThemeMode>();
    final w = el?.widget;
    return w is AppThemeMode ? w.notifier : null;
  }

  @override
  bool updateShouldNotify(covariant AppThemeMode oldWidget) =>
      oldWidget.notifier != notifier;
}
