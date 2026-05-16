import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Transiciones de pantalla (inspiración dashboards modernos / [flutter_animate](https://pub.dev/packages/flutter_animate)).
abstract final class AppPageTransitions {
  static const Duration forward = Duration(milliseconds: 400);
  static const Duration reverse = Duration(milliseconds: 320);

  static Route<T> elegant<T>(Widget page) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: page.runtimeType.toString()),
      pageBuilder: (_, __, ___) => page,
      transitionDuration: forward,
      reverseTransitionDuration: reverse,
      transitionsBuilder: _build,
    );
  }

  static Widget _build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curved);
    final fade = Tween<double>(begin: 0, end: 1).animate(curved);
    final scale = Tween<double>(begin: 0.985, end: 1).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }
}

/// Builder para [ThemeData.pageTransitionsTheme].
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions._build(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
