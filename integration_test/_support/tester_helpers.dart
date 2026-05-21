// Generic Flutter widget-test primitives — no Whitenoise knowledge.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> enterTextInWidget(
  WidgetTester tester,
  Key key,
  String text,
) async {
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextField),
  );
  await pumpUntilFound(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> tapKey(
  WidgetTester tester,
  Key key, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final finder = find.byKey(key);
  await pumpUntilFound(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> pumpUntilNotFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to disappear');
}
