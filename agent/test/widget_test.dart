import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent/main.dart';

void main() {
  testWidgets('Operator Dashboard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MatrixAgentApp()));
    
    expect(find.text('Operator Dashboard'), findsOneWidget);
    expect(find.text('Capability Explorer'), findsOneWidget);
    expect(find.textContaining('System initialized...'), findsOneWidget);
  });
}
