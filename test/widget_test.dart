import 'package:flutter_test/flutter_test.dart';
import 'package:ritme/main.dart';

void main() {
  testWidgets('Ritme smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RitmeApp());
      await tester.pump(const Duration(milliseconds: 500));
    });
    expect(find.text('Ritme'), findsOneWidget);
  });
}
