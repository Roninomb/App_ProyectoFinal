import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen muestra el título correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Pantalla principal'), findsOneWidget);
  });
}
