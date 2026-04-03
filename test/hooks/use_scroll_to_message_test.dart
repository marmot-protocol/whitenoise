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
                messageCount: 0,
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
                messageCount: 0,
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
                messageCount: 0,
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
                messageCount: 10,
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

    testWidgets('without position loads pages until message is found', (tester) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => loadCalls >= 5 ? 10 : null,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: true,
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      unawaited(result.scrollToMessage('deep-msg'));
      await tester.pump();

      expect(loadCalls, 5);
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
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.runAsync(() => result.scrollToMessage('deep-msg'));

      expect(loadCalls, 0);
    });

    testWidgets('with position calculates exact pages to load', (tester) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => loadCalls >= 3 ? 5 : null,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: true,
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      unawaited(result.scrollToMessage('msg-200', position: 200));
      await tester.pump();

      expect(loadCalls, 3);
    });

    testWidgets('with position does not load if message already in window', (tester) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => 5,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: true,
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      unawaited(result.scrollToMessage('msg-5', position: 10));
      await tester.pump();

      expect(loadCalls, 0);
    });

    testWidgets('with position stops early when message found before all pages loaded', (
      tester,
    ) async {
      late ScrollToMessageResult result;
      var loadCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useScrollToMessage(
                getReversedMessageIndex: (_) => loadCalls >= 1 ? 3 : null,
                loadOlderMessages: () async {
                  loadCalls++;
                },
                hasMoreMessages: true,
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      unawaited(result.scrollToMessage('msg-300', position: 300));
      await tester.pump();

      expect(loadCalls, 1);
    });

    testWidgets('with position does not exceed calculated page count', (tester) async {
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
                hasMoreMessages: true,
                messageCount: 50,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.runAsync(() => result.scrollToMessage('missing-msg', position: 120));

      expect(loadCalls, 2);
    });
  });
}
