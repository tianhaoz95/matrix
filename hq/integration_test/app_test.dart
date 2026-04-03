import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hq/main.dart' as app;
import 'package:hq/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msp/msp.dart';
import '../test/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify sign in, add task, and column movement', (tester) async {
      final mockAuth = MockAuthProvider();
      final mockData = MockDataProvider();
      
      final authStateController = StreamController<bool>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWithValue(mockAuth),
            dataProvider.overrideWithValue(mockData),
            authStateProvider.overrideWith((ref) => authStateController.stream),
          ],
          child: const app.MatrixHQApp(),
        ),
      );
      
      authStateController.add(false);
      
      // Wait for Welcome text
      bool foundWelcome = false;
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.textContaining('Welcome').evaluate().isNotEmpty) {
          foundWelcome = true;
          break;
        }
      }
      expect(foundWelcome, isTrue, reason: 'Should find Welcome text');

      // 1. Sign In
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      
      await tester.tap(find.text('Sign In'));
      authStateController.add(true);
      
      await tester.pumpAndSettle();

      // 2. Add Task
      expect(find.text('Matrix HQ'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Initialize Prophecy'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'New Test Task');
      await tester.enterText(find.byType(TextField).at(1), 'Task details here');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('New Test Task'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget); // Priority chip
      expect(find.text('Backlog'), findsOneWidget); // Column header

      // 3. Move Task
      final tasks = await mockData.getTasks('w1');
      final task = tasks.firstWhere((t) => t.title == 'New Test Task');
      
      final updatedTask = MatrixTask(
        id: task.id,
        workspaceId: task.workspaceId,
        title: task.title,
        description: task.description,
        status: 'Architect Review',
        priority: task.priority,
      );
      
      await mockData.updateTask(updatedTask);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('New Test Task'), findsOneWidget);
      expect(find.text('Architect Review'), findsAtLeast(1)); // Column header
      
      authStateController.close();
    });
  });
}
