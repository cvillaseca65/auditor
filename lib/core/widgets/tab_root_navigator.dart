import 'package:flutter/material.dart';

/// Raíz de una pestaña en [HomeShell]. Las pantallas de detalle se apilan aquí
/// y el [NavigationBar] del shell permanece visible.
class TabRootNavigator extends StatelessWidget {
  const TabRootNavigator({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => child,
          settings: settings,
        );
      },
    );
  }
}
