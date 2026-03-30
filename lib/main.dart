import 'package:flutter/material.dart';
import 'screens/login_page.dart'; // LoginPage sigue separado
import 'core/theme/sim_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inicio',
      theme: SimTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
