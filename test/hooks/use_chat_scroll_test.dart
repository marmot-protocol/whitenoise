import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/hooks/use_chat_scroll.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _withinBottomThreshold = 40.0;

final _api = MockWnApi();

class _TestWidget extends HookWidget {
  const _TestWidget({
    required this.scrollController,
    required this.focusNode,
    required this.messageIds,
    this.latestMessageId,
    this.latestMessagePubkey,
    this.onResult,
  });

  final AutoScrollController scrollController;
  final FocusNode focusNode;
  final List<String> messageIds;
  final String? latestMessageId;
  final String? latestMessagePubkey;
  final void Function(ChatScrollResult)? onResult;

  @override
  Widget build(BuildContext context) {
    final result = useChatScroll(
      scrollController: scrollController,
      focusNode: focusNode,
      latestMessageId: latestMessageId ?? (messageIds.isNotEmpty ? messageIds.first : null),
      latestMessagePubkey: latestMessagePubkey,
      accountPubkey: testPubkeyA,
      groupId: testGroupId,
      messageCount: messageIds.length,
      getMessageId: (index) => index < messageIds.length ? messageIds[index] : null,
      getReversedIndex: (id) {
        final index = messageIds.indexOf(id);
        return index >= 0 ? index : null;
      },
    );

    onResult?.call(result);

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: result.isInitialPositionReady ? 1.0 : 0.0,
                child: ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  itemCount: messageIds.length,
                  itemBuilder: (_, i) => AutoScrollTag(
                    key: ValueKey(messageIds[i]),
                    controller: scrollController,
                    index: i,
                    child: SizedBox(height: 80, child: Text('Item ${messageIds[i]}')),
                  ),
                ),
              ),
            ),
            TextField(focusNode: focusNode),
          ],
        ),
      ),
    );
  }
}

List<String> _generateIds(int count) => List.generate(count, (i) => 'm${count - i}');

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  late AutoScrollController scrollController;
  late FocusNode focusNode;

  setUp(() {
    _api.reset();
    scrollController = AutoScrollController();
    focusNode = FocusNode();
  });

  tearDown(() {
    scrollController.dispose();
    focusNode.unfocus();
    focusNode.dispose();
  });

  Future<void> pumpScroll(
    WidgetTester tester, {
    List<String>? messageIds,
    String? latestMessageId,
    String? latestMessagePubkey,
    void Function(ChatScrollResult)? onResult,
  }) async {
    final ids = messageIds ?? _generateIds(50);
    await tester.pumpWidget(
      _TestWidget(
        scrollController: scrollController,
        focusNode: focusNode,
        messageIds: ids,
        latestMessageId: latestMessageId,
        latestMessagePubkey: latestMessagePubkey,
        onResult: onResult,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('useChatScroll', () {
    group('initial load scroll', () {
      testWidgets('scrolls to bottom on initial load', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);
      });

      testWidgets('defers initial scroll until last read status is loaded', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm50');

        // New message arrives before async resolves — still treated as initial load
        // because prevLatestMessageId was never set (scroll was deferred)
        await pumpScroll(tester, latestMessageId: 'm51');

        // Resolve async — initial load scroll now fires
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);
      });
    });

    group('isInitialPositionReady', () {
      testWidgets('is false before last read status loads', (tester) async {
        _api.lastReadMessageId = 'm1';
        ChatScrollResult? lastResult;
        await tester.pumpWidget(
          _TestWidget(
            scrollController: scrollController,
            focusNode: focusNode,
            messageIds: _generateIds(50),
            onResult: (r) => lastResult = r,
          ),
        );
        await tester.pump();

        expect(lastResult?.isInitialPositionReady, false);

        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.isInitialPositionReady, true);
      });

      testWidgets('is true immediately when all messages are read', (tester) async {
        _api.lastReadMessageId = 'm50';
        ChatScrollResult? lastResult;
        await pumpScroll(tester, onResult: (r) => lastResult = r);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.isInitialPositionReady, true);
      });

      testWidgets('is true after scrolling to unread position', (tester) async {
        _api.lastReadMessageId = 'm1';
        ChatScrollResult? lastResult;
        await pumpScroll(tester, onResult: (r) => lastResult = r);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.isInitialPositionReady, true);
        expect(scrollController.position.pixels, greaterThan(0));
      });
    });

    group('new message scroll', () {
      testWidgets('scrolls to bottom when at bottom and new message arrives', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        await pumpScroll(tester, latestMessageId: 'm2');

        expect(scrollController.position.pixels, 0);
      });

      testWidgets('does not scroll when not at bottom and new message arrives', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(100);
        await tester.pumpAndSettle();

        final positionBefore = scrollController.position.pixels;

        await pumpScroll(tester, latestMessageId: 'm2');

        expect(scrollController.position.pixels, positionBefore);
      });
    });

    group('own message scroll', () {
      testWidgets('scrolls to bottom when own message arrives while scrolled up', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(100);
        await tester.pumpAndSettle();

        await pumpScroll(tester, latestMessageId: 'm2', latestMessagePubkey: testPubkeyA);

        expect(scrollController.position.pixels, 0);
      });

      testWidgets('scrolls to bottom when own message arrives while at bottom', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        await pumpScroll(tester, latestMessageId: 'm2', latestMessagePubkey: testPubkeyA);

        expect(scrollController.position.pixels, 0);
      });
    });

    group('focus scroll', () {
      testWidgets('scrolls to bottom when input gains focus', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);
      });

      testWidgets('resets shouldStayAtBottom when input loses focus', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();

        focusNode.unfocus();
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, scrollController.position.maxScrollExtent);
      });
    });

    group('keyboard scroll', () {
      testWidgets('jumps to bottom when metrics change and input is focused', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        scrollController.jumpTo(100);

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        addTearDown(() => tester.view.resetViewInsets());
      });

      testWidgets('jumps to bottom when metrics change and at bottom', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        addTearDown(() => tester.view.resetViewInsets());
      });

      testWidgets('does not jump when metrics change and not at bottom and not focused', (
        tester,
      ) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(100);
        await tester.pumpAndSettle();

        final positionBefore = scrollController.position.pixels;

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, positionBefore);

        addTearDown(() => tester.view.resetViewInsets());
      });
    });

    group('isAtBottom tracking', () {
      testWidgets('correctly tracks when scrolled away from bottom', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);

        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();

        await pumpScroll(tester, latestMessageId: 'm2');

        expect(scrollController.position.pixels, scrollController.position.maxScrollExtent);
      });

      testWidgets('considers within threshold as at bottom', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(_withinBottomThreshold);
        await tester.pumpAndSettle();

        await pumpScroll(tester, latestMessageId: 'm2');

        expect(scrollController.position.pixels, 0);
      });
    });

    group('isScrollDownButtonVisible', () {
      testWidgets('is false when at bottom without unread messages', (tester) async {
        _api.lastReadMessageId = 'm50';
        await pumpScroll(tester, latestMessageId: 'm1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);
      });

      testWidgets('is false when at bottom', (tester) async {
        ChatScrollResult? lastResult;
        await pumpScroll(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.pumpAndSettle();

        expect(lastResult?.isScrollDownButtonVisible, false);
      });
    });
  });

  group('mark as read', () {
    group('marking messages as read', () {
      testWidgets('marks incoming message as read when at bottom', (tester) async {
        _api.lastReadMessageId = 'm2';
        await pumpScroll(
          tester,
          messageIds: ['m2', 'm1'],
          latestMessageId: 'm2',
          latestMessagePubkey: testPubkeyB,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        await pumpScroll(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          latestMessageId: 'm3',
          latestMessagePubkey: testPubkeyB,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m3'));
      });

      testWidgets('auto-marks own message as read', (tester) async {
        _api.lastReadMessageId = 'm2';
        await pumpScroll(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          latestMessageId: 'm3',
          latestMessagePubkey: testPubkeyA,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m3'));
      });
    });

    group('marks visible messages on scroll', () {
      testWidgets('marks a visible message as read after scrolling', (tester) async {
        final messageIds = List.generate(20, (i) => 'm${20 - i}');
        _api.lastReadMessageId = 'm1';
        await pumpScroll(tester, messageIds: messageIds);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(200);
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
        await tester.pumpAndSettle();

        expect(
          _api.markedAsReadMessages.any((id) => messageIds.contains(id)),
          isTrue,
        );
      });

      testWidgets('marks newer message than last read', (tester) async {
        final messageIds = List.generate(20, (i) => 'm${20 - i}');
        _api.lastReadMessageId = 'm1';
        await pumpScroll(tester, messageIds: messageIds);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        scrollController.jumpTo(200);
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
        await tester.pumpAndSettle();

        final markedId = _api.markedAsReadMessages.first;
        final markedIndex = messageIds.indexOf(markedId);
        final lastReadIndex = messageIds.indexOf('m1');

        expect(
          markedIndex < lastReadIndex,
          isTrue,
        );
      });
    });

    group('scrollToBottom', () {
      testWidgets('provides scrollToBottom function', (tester) async {
        _api.lastReadMessageId = 'm1';
        ChatScrollResult? lastResult;
        await pumpScroll(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );

        expect(lastResult?.scrollToBottom, isNotNull);
      });

      testWidgets('scrolls to bottom when called', (tester) async {
        _api.lastReadMessageId = 'm1';
        ChatScrollResult? lastResult;
        await pumpScroll(tester, messageIds: ['m3', 'm2', 'm1'], onResult: (r) => lastResult = r);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        lastResult?.scrollToBottom();
        await tester.pumpAndSettle();

        expect(scrollController.position.pixels, 0);
      });
    });
  });
}
