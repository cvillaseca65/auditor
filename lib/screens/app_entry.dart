import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'login_page.dart';

/// Arranque: splash negro con logo ~1 s, luego login con transición suave.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _splashVisible = true;
  bool _splashMounted = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _splashVisible = false);
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _splashMounted = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const LoginPage()
            .animate()
            .fadeIn(delay: 900.ms, duration: 450.ms, curve: Curves.easeOut),
        if (_splashMounted)
          IgnorePointer(
            ignoring: !_splashVisible,
            child: _SplashOverlay(visible: _splashVisible),
          ),
      ],
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  const _SplashOverlay({required this.visible});

  final bool visible;

  static const _logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Image.asset(
          _logoAsset,
          height: 168,
          fit: BoxFit.contain,
        )
            .animate(target: visible ? 1 : 0)
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .scaleXY(
              begin: 0.82,
              end: 1,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
            .then()
            .fadeOut(duration: 380.ms, curve: Curves.easeIn),
      ),
    )
        .animate(target: visible ? 1 : 0)
        .fade(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeIn);
  }
}
