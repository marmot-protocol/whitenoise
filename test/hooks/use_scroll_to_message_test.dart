import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/hooks/use_scroll_to_message.dart';

void main() {
  group('useScrollToMessage', () {
    testWidgets('creates AutoScrollController on init', (tester) async {
      late ScrollToMessageResult result;
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => null,
                loadOlderMessages: () async {},
                hasMoreMessages: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.scrollController, isA<AutoScrollController>());
    });

    testWidgets('disposes controller on unmount', (tester) async {
      late AutoScrollController capturedController;
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final result = useScrollToMessage(
                getReversedMessageIndex: (_) => null,
                loadOlderMessages: () async {},
                hasMoreMessages: false,
              );
              capturedController = result.scrollController;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(
        () => capturedController.position,
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('scrollToMessage does nothing when message not found and no more pages', (
      tester,
    ) async {
      late ScrollToMessageResult result;
      String? lookedUpId;
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (id) {
                  lookedUpId = id;
                  return null;
                },
                loadOlderMessages: () async {},
                hasMoreMessages: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.runAsync(() => result.scrollToMessage('unknown-id'));

      expect(lookedUpId, 'unknown-id');
    });

    testWidgets('scrollToMessage calls getReversedMessageIndex with messageId', (tester) async {
      late ScrollToMessageResult result;
      String? lookedUpId;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (id) {
                  lookedUpId = id;
                  return id == 'msg-1' ? 0 : null;
                },
                loadOlderMessages: () async {},
                hasMoreMessages: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      unawaited(result.scrollToMessage('msg-1'));
      await tester.pump();

      expect(lookedUpId, 'msg-1');
    });

    testWidgets('loads older pages until message is found or no more pages', (tester) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => null,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: loadCalls < 3,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.runAsync(() => result.scrollToMessage('deep-msg'));

      expect(loadCalls, greaterThan(0));
    });

    testWidgets('does not load pages when hasMoreMessages is false', (tester) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => null,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.runAsync(() => result.scrollToMessage('deep-msg'));

      expect(loadCalls, 0);
    });
  });
}
