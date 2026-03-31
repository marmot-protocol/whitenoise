import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_mark_as_read.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

final _api = MockWnApi();

class _TestWidget extends HookWidget {
  const _TestWidget({
    required this.messageIds,
    this.onResult,
  });

  final List<String> messageIds;
  final void Function(MarkAsReadResult)? onResult;

  @override
  Widget build(BuildContext context) {
    final result = useMarkAsRead(
      accountPubkey: testPubkeyA,
      groupId: testGroupId,
      messageCount: messageIds.length,
      getReversedIndex: (id) {
        final index = messageIds.indexOf(id);
        return index >= 0 ? index : null;
      },
    );

    onResult?.call(result);

    return const SizedBox.shrink();
  }
}

Future<void> _pumpMarkAsRead(
  WidgetTester tester, {
  List<String> messageIds = const [],
  void Function(MarkAsReadResult)? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _TestWidget(messageIds: messageIds, onResult: onResult),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() => _api.reset());

  group('useMarkAsRead', () {
    group('firstUnreadIndex', () {
      testWidgets('is null when no messages', (tester) async {
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(tester, onResult: (r) => lastResult = r);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, isNull);
      });

      testWidgets('is null when all messages are read', (tester) async {
        _api.lastReadMessageId = 'm3';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, isNull);
      });

      testWidgets('returns index of first unread when some are read', (tester) async {
        _api.lastReadMessageId = 'm1';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, 1);
      });

      testWidgets('returns last index when nothing has been read', (tester) async {
        _api.lastReadMessageId = null;
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, 2);
      });

      testWidgets('treats all messages as unread when last read is not in loaded set', (
        tester,
      ) async {
        _api.lastReadMessageId = 'm99';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, 2);
      });
    });

    group('hasLoadedLastRead', () {
      testWidgets('is true after fetch resolves', (tester) async {
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.hasLoadedLastRead, true);
      });

      testWidgets('is true even when fetch fails', (tester) async {
        _api.shouldFailGetAccountGroup = true;
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.hasLoadedLastRead, true);
      });
    });

    group('markMessageAsRead', () {
      testWidgets('marks unread message via API', (tester) async {
        _api.lastReadMessageId = 'm1';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        lastResult?.markMessageAsRead('m2');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m2'));
      });

      testWidgets('does not re-mark already-read message', (tester) async {
        _api.lastReadMessageId = 'm2';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        lastResult?.markMessageAsRead('m1');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, isEmpty);
      });

      testWidgets('does not re-mark the exact last-read message', (tester) async {
        _api.lastReadMessageId = 'm2';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        lastResult?.markMessageAsRead('m2');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, isEmpty);
      });
    });

    group('when fetching last read fails', () {
      setUp(() => _api.shouldFailGetAccountGroup = true);

      testWidgets('treats all messages as unread', (tester) async {
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, 2);
      });

      testWidgets('markMessageAsRead still works', (tester) async {
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        _api.shouldFailGetAccountGroup = false;
        lastResult?.markMessageAsRead('m2');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m2'));
      });
    });

    group('fetching last read', () {
      testWidgets('re-fetches when message count changes after debounce', (tester) async {
        _api.lastReadMessageId = 'm1';
        MarkAsReadResult? lastResult;
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(lastResult?.firstUnreadIndex, 1);
        expect(_api.getAccountGroupCallCount, 1);

        _api.lastReadMessageId = 'm3';
        await _pumpMarkAsRead(
          tester,
          messageIds: ['m4', 'm3', 'm2', 'm1'],
          onResult: (r) => lastResult = r,
        );
        // Advance past the 1-second debounce to fire the Timer callback.
        await tester.pump(const Duration(seconds: 2));
        // Let the async FFI fetch complete.
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.getAccountGroupCallCount, 2);
        expect(lastResult?.firstUnreadIndex, 0);
      });
    });
  });
}
