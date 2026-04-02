import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/utils/scroll_duration.dart';

import '../test_helpers.dart';

void main() {
  group('scrollDuration', () {
    testWidgets('returns max duration when controller has no clients', (tester) async {
      final controller = AutoScrollController();
      addTearDown(controller.dispose);

      expect(scrollDuration(controller, 100), maxScrollDuration);
    });

    testWidgets('returns min duration for nearby targets', (tester) async {
      setUpTestView(tester);
      final controller = AutoScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
            ),
          ),
        ),
      );

      final result = scrollDuration(controller, 0);
      expect(result.inMilliseconds, 50);
    });

    testWidgets('scales duration with distance', (tester) async {
      setUpTestView(tester);
      final controller = AutoScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 1000,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
            ),
          ),
        ),
      );

      final nearDuration = scrollDuration(controller, 2);
      final farDuration = scrollDuration(controller, 500);
      expect(farDuration.inMilliseconds, greaterThan(nearDuration.inMilliseconds));
    });

    testWidgets('never exceeds max duration', (tester) async {
      setUpTestView(tester);
      final controller = AutoScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 10000,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
            ),
          ),
        ),
      );

      final result = scrollDuration(controller, 9999);
      expect(result.inMilliseconds, lessThanOrEqualTo(maxScrollDuration.inMilliseconds));
    });
  });
}
