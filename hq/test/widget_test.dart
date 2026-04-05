import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hq/main.dart';
import 'package:hq/providers.dart';
import 'mocks.dart';

void main() {
  testWidgets('Dashboard renders correctly', (WidgetTester tester) async {
    // Set a HUGE surface size to avoid overflows in Kanban
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1.0;
    
    final mockAuth = MockAuthProvider();
    final mockData = MockDataProvider();
    
    // Sign in to show dashboard
    await mockAuth.signIn(email: 'test@example.com', password: 'password');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWithValue(mockAuth),
          dataProvider.overrideWithValue(mockData),
          authStateProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MatrixHQApp(),
      ),
    );
    
    // Pump multiple times to ensure animations and layout settle
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    
    expect(find.text('Matrix HQ'), findsOneWidget);
    
    // Reset surface size after test
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
