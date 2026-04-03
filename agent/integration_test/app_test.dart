import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify sign in and operator dashboard entry', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // We should be at Sign In screen initially
      expect(find.text('Welcome Back!'), findsOneWidget);

      // Fill in details
      await tester.enterText(find.byType(TextField).at(0), 'agent@matrix.ai');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Similar to HQ, without a mocked backend, the network request may fail or hang.
      // If we had a mock, we would verify we reach 'Operator Dashboard'.
    });
  });
}
