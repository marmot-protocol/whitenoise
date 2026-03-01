import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/screens/chat_raw_debug_screen.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testGroupId = testGroupId;

class _MockAccountPubkeyNotifier extends AccountPubkeyNotifier {
  @override
  String build() => testPubkeyA;
}

ChatMessage _message(
  String id,
  DateTime createdAt, {
  String pubkey = testPubkeyB,
  bool isDeleted = false,
}) => ChatMessage(
  id: id,
  pubkey: pubkey,
  content: 'Content of $id',
  createdAt: createdAt,
  tags: const [],
  isReply: false,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 9,
);

class _MockApi extends MockWnApi {
  StreamController<MessageStreamItem>? controller;
  List<ChatMessage> initialMessages = [];

  @override
  void reset() {
    super.reset();
    controller?.close();
    controller = null;
    initialMessages = [];
  }

  @override
  Stream<MessageStreamItem> crateApiMessagesSubscribeToGroupMessages({
    required String groupId,
  }) {
    controller?.close();
    controller = StreamController<MessageStreamItem>.broadcast();
    Future.microtask(() {
      controller?.add(MessageStreamItem.initialSnapshot(messages: initialMessages));
    });
    return controller!.stream;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpDebugScreen(WidgetTester tester) async {
    await mountWidget(
      const ChatRawDebugScreen(groupId: _testGroupId),
      tester,
      overrides: [accountPubkeyProvider.overrideWith(_MockAccountPubkeyNotifier.new)],
    );
    await tester.pumpAndSettle();
  }

  group('ChatRawDebugScreen', () {
    testWidgets('displays Raw Debug View title', (tester) async {
      await pumpDebugScreen(tester);

      expect(find.text('Raw Debug View'), findsOneWidget);
    });

    testWidgets('displays group ID', (tester) async {
      await pumpDebugScreen(tester);

      expect(find.byKey(const Key('debug_group_id')), findsOneWidget);
      expect(find.text(_testGroupId), findsOneWidget);
    });

    testWidgets('displays message count', (tester) async {
      await pumpDebugScreen(tester);

      expect(find.byKey(const Key('debug_message_count')), findsOneWidget);
    });

    testWidgets('shows 0 count when no messages', (tester) async {
      await pumpDebugScreen(tester);

      final countWidget = tester.widget<SelectableText>(
        find.byKey(const Key('debug_message_count')),
      );
      expect(countWidget.data, '0');
    });

    testWidgets('displays message cards when messages exist', (tester) async {
      final now = DateTime(2024, 1, 15, 12);
      _api.initialMessages = [
        _message('msg1', now),
        _message('msg2', now.add(const Duration(minutes: 1))),
      ];

      await pumpDebugScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('raw_message_card_msg2')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // msg2 is latest so it appears first in the reversed list (always visible)
      expect(find.byKey(const Key('raw_message_card_msg2')), findsOneWidget);
    });

    testWidgets('message card contains id field', (tester) async {
      final now = DateTime(2024, 1, 15, 12);
      _api.initialMessages = [_message('abc123', now)];

      await pumpDebugScreen(tester);

      expect(find.textContaining('abc123'), findsWidgets);
    });

    testWidgets('message card contains pubkey field', (tester) async {
      final now = DateTime(2024, 1, 15, 12);
      _api.initialMessages = [_message('msg1', now)];

      await pumpDebugScreen(tester);

      expect(find.textContaining(testPubkeyB), findsWidgets);
    });

    testWidgets('message card contains content field', (tester) async {
      final now = DateTime(2024, 1, 15, 12);
      _api.initialMessages = [_message('msg1', now)];

      await pumpDebugScreen(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('raw_message_card_msg1')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('Content of msg1'), findsWidgets);
    });

    testWidgets('displays correct message count with messages', (tester) async {
      final now = DateTime(2024, 1, 15, 12);
      _api.initialMessages = [
        _message('msg1', now),
        _message('msg2', now.add(const Duration(minutes: 1))),
        _message('msg3', now.add(const Duration(minutes: 2))),
      ];

      await pumpDebugScreen(tester);

      final countWidget = tester.widget<SelectableText>(
        find.byKey(const Key('debug_message_count')),
      );
      expect(countWidget.data, '3');
    });

    testWidgets('back button is present', (tester) async {
      await pumpDebugScreen(tester);

      expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
    });

    testWidgets('executes debug query and shows formatted result', (tester) async {
      _api.debugQueryResult = '[{"table":"accounts","rows":2}]';

      await pumpDebugScreen(tester);
      await tester.enterText(
        find.byKey(const Key('debug_query_input')),
        'SELECT * FROM accounts;',
      );
      await tester.tap(find.byKey(const Key('debug_query_run_button')));
      await tester.pumpAndSettle();

      expect(_api.lastDebugQuerySql, 'SELECT * FROM accounts;');
      expect(find.byKey(const Key('debug_query_table')), findsOneWidget);
      expect(find.byKey(const Key('debug_query_result')), findsOneWidget);
      expect(find.textContaining('"table": "accounts"'), findsOneWidget);
    });

    testWidgets('shows debug query errors', (tester) async {
      _api.shouldFailDebugQuery = true;

      await pumpDebugScreen(tester);
      await tester.tap(find.byKey(const Key('debug_query_run_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('debug_query_error')), findsOneWidget);
      expect(find.textContaining('debug query failed'), findsOneWidget);
    });
  });
}
