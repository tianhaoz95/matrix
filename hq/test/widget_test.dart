import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hq/main.dart';

void main() {
  testWidgets('Dashboard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MatrixHQApp()));
    
    expect(find.text('Matrix HQ'), findsOneWidget);
    expect(find.text('Sprint Review Today'), findsOneWidget);
  });
}
