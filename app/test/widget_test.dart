import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:capsule/main.dart';

void main() {
  testWidgets('App boots to a loading gate', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CapsuleApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
