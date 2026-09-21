import 'package:flutter/material.dart';

import 'core/theme/app_theme_mode.dart';
import 'core/theme/sim_theme.dart';
import 'screens/app_entry.dart';
import 'services/offline/audit_sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ValueNotifier<ThemeMode> _themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ignore: discarded_futures
    AuditSyncService.instance.flushOutbox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeMode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ignore: discarded_futures
      AuditSyncService.instance.flushOutbox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Inicio',
          theme: SimTheme.lightTheme,
          darkTheme: SimTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return AppThemeMode(
              notifier: _themeMode,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppEntry(),
        );
      },
    );
  }
}
