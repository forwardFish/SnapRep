// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snaprep/main.dart';

void main() {
  testWidgets('SnapRep app loads without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SnapRepApp());

    // Verify that the app loads without error
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
