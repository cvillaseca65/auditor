// Basic smoke test: app builds and muestra login.
import 'package:flutter_test/flutter_test.dart';

import 'package:auditor/main.dart';

void main() {
  testWidgets('MyApp muestra pantalla de inicio de sesión', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Iniciar sesión'), findsOneWidget);
  });
}
