import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hq/main.dart' as app;
import 'package:hq/providers.dart';
import 'package:hq/services/matrix_brain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../test/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('verify prophecy loop (Oracle & Architect)', (tester) async {
    final mockAuth = MockAuthProvider();
    final mockData = MockDataProvider();
    final authStateController = StreamController<bool>.broadcast();

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWithValue(mockAuth),
        dataProvider.overrideWithValue(mockData),
        authStateProvider.overrideWith((ref) => authStateController.stream),
      ],
    );
    
    final brain = container.read(matrixBrainProvider);
    brain.start();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const app.MatrixHQApp(),
      ),
    );
    
    authStateController.add(false);
    await tester.pump(const Duration(seconds: 2));

    // 1. Sign In
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    authStateController.add(true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 2. Add Prophecy (Draft)
    expect(find.text('Matrix HQ'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Build a Matrix');
    await tester.enterText(find.byType(TextField).at(1), 'Create a multi-agent organization.');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    
    // 3. Manual Brain Trigger Loop
    bool loopFinished = false;
    for (int i = 0; i < 40; i++) {
      final tasks = await mockData.getTasks('w1');
      
      // Manually trigger brain if it's stuck
      await brain.processTasks(tasks);
      
      await tester.pump(const Duration(milliseconds: 500));
      
      if (tasks.any((t) => t.title == 'Build a Matrix' && t.status.toLowerCase() == 'complete')) {
        loopFinished = true;
        break;
      }
    }
    expect(loopFinished, isTrue, reason: 'The prophecy loop should finish with Complete status');
    
    authStateController.close();
    container.dispose();
  });

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
    await tester.pump(const Duration(seconds: 2));

    // 1. Sign In
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    authStateController.add(true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 2. Add Task
    expect(find.text('Matrix HQ'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'New Test Task');
    await tester.enterText(find.byType(TextField).at(1), 'Task details here');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    
    bool found = false;
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('New Test Task').evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    expect(found, isTrue);

    // 3. Move Task
    final tasks = await mockData.getTasks('w1');
    final task = tasks.firstWhere((t) => t.title == 'New Test Task');
    
    final updatedTask = task.copyWith(status: 'Architect Review');
    await mockData.updateTask(updatedTask);
    
    bool moved = false;
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.textContaining('Architect Review').evaluate().isNotEmpty) {
        moved = true; 
        break;
      }
    }
    expect(moved, isTrue);
    
    authStateController.close();
  });
}
