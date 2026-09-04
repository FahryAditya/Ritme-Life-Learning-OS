import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritme/main.dart';

void main() {
  testWidgets('Ritme smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RitmeApp());
    await tester.pumpAndSettle();
    expect(find.text('Ritme'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
