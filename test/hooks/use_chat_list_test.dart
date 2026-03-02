import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_list.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../test_helpers.dart';

ChatSummary _chatSummary(
  String id,
  DateTime createdAt, {
  bool pendingConfirmation = false,
}) => ChatSummary(
  mlsGroupId: 'mls_$id',
  name: 'Chat $id',
  groupType: GroupType.group,
  createdAt: createdAt,
  pendingConfirmation: pendingConfirmation,
  unreadCount: BigInt.zero,
);

class _MockApi implements RustLibApi {
  StreamController<ChatListStreamItem>? controller;

  void emitInitialSnapshot(List<ChatSummary> items) {
    controller?.add(ChatListStreamItem.initialSnapshot(items: items));
  }

  void emitUpdate(ChatListUpdateTrigger trigger, ChatSummary item) {
    controller?.add(
      ChatListStreamItem.update(
        update: ChatListUpdate(trigger: trigger, item: item),
      ),
    );
  }

  @override
  Stream<ChatListStreamItem> crateApiChatListSubscribeToChatList({
    required String accountPubkey,
  }) {
    controller?.close();
    controller = StreamController<ChatListStreamItem>.broadcast();
    return controller!.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _api = _MockApi();

Future<ChatListResult Function()> _pump(WidgetTester tester, String pubkey) {
  return mountHook(tester, () => useChatList(pubkey));
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  tearDown(() {
    _api.controller?.close();
    _api.controller = null;
  });

  group('useChatList', () {
    group('initial state', () {
      testWidgets('starts with empty chats', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        expect(getResult().chats, isEmpty);
      });

      testWidgets('isLoading is true before data arrives', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        expect(getResult().isLoading, isTrue);
      });

      testWidgets('isLoading is false after initial snapshot', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([_chatSummary('c1', DateTime(2024))]);
        await tester.pump();

        expect(getResult().isLoading, isFalse);
      });
    });

    group('initial snapshot', () {
      testWidgets('returns chats in original API order', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024)),
          _chatSummary('c2', DateTime(2024, 1, 2)),
        ]);
        await tester.pump();

        final ids = getResult().chats.map((c) => c.mlsGroupId).toList();
        expect(ids, ['mls_c1', 'mls_c2']);
      });
    });

    group('newGroup trigger', () {
      testWidgets('adds new chat to the front', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([_chatSummary('c1', DateTime(2024))]);
        await tester.pumpAndSettle();

        _api.emitUpdate(
          ChatListUpdateTrigger.newGroup,
          _chatSummary('c2', DateTime(2024, 1, 2)),
        );
        await tester.pumpAndSettle();

        final ids = getResult().chats.map((c) => c.mlsGroupId).toList();
        expect(ids.first, 'mls_c2');
      });
    });

    group('newLastMessage trigger', () {
      testWidgets('moves updated chat to the front', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024)),
          _chatSummary('c2', DateTime(2024, 1, 2)),
        ]);
        await tester.pumpAndSettle();

        _api.emitUpdate(
          ChatListUpdateTrigger.newLastMessage,
          _chatSummary('c2', DateTime(2024, 1, 3)),
        );
        await tester.pumpAndSettle();

        final ids = getResult().chats.map((c) => c.mlsGroupId).toList();
        expect(ids.first, 'mls_c2');
      });

      testWidgets('does not reorder pending confirmation chat', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024)),
          _chatSummary('c2', DateTime(2024, 1, 2), pendingConfirmation: true),
        ]);
        await tester.pumpAndSettle();

        final initialIds = getResult().chats.map((c) => c.mlsGroupId).toList();
        expect(initialIds, ['mls_c1', 'mls_c2']);

        _api.emitUpdate(
          ChatListUpdateTrigger.newLastMessage,
          _chatSummary('c2', DateTime(2024, 1, 3), pendingConfirmation: true),
        );
        await tester.pumpAndSettle();

        final ids = getResult().chats.map((c) => c.mlsGroupId).toList();
        expect(ids, ['mls_c1', 'mls_c2']);
      });

      testWidgets('updates data for pending confirmation chat', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024), pendingConfirmation: true),
        ]);
        await tester.pumpAndSettle();

        final updatedChat = ChatSummary(
          mlsGroupId: 'mls_c1',
          name: 'Updated Pending Chat',
          groupType: GroupType.group,
          createdAt: DateTime(2024),
          pendingConfirmation: true,
          unreadCount: BigInt.zero,
        );
        _api.emitUpdate(ChatListUpdateTrigger.newLastMessage, updatedChat);
        await tester.pumpAndSettle();

        expect(getResult().chats.first.name, 'Updated Pending Chat');
      });
    });

    group('refresh', () {
      testWidgets('re-subscribes to stream and gets fresh data', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([_chatSummary('c1', DateTime(2024))]);
        await tester.pumpAndSettle();

        expect(getResult().chats.length, 1);

        getResult().refresh();
        await tester.pump();

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024)),
          _chatSummary('c2', DateTime(2024, 1, 2)),
        ]);
        await tester.pumpAndSettle();

        expect(getResult().chats.length, 2);
      });
    });

    group('error handling', () {
      testWidgets('logs error and rethrows when stream emits error', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.controller?.addError(Exception('connection lost'));
        await tester.pump();

        expect(getResult().chats, isEmpty);
      });
    });

    group('lastMessageDeleted trigger', () {
      testWidgets('updates chat data without changing order', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([
          _chatSummary('c1', DateTime(2024)),
          _chatSummary('c2', DateTime(2024, 1, 2)),
        ]);
        await tester.pumpAndSettle();

        final updatedChat = ChatSummary(
          mlsGroupId: 'mls_c1',
          name: 'Updated Name',
          groupType: GroupType.group,
          createdAt: DateTime(2024),
          pendingConfirmation: false,
          unreadCount: BigInt.zero,
        );
        _api.emitUpdate(ChatListUpdateTrigger.lastMessageDeleted, updatedChat);
        await tester.pumpAndSettle();

        final chats = getResult().chats;
        expect(chats.first.mlsGroupId, 'mls_c1');
      });

      testWidgets('reflects updated chat data', (tester) async {
        final getResult = await _pump(tester, testPubkeyA);

        _api.emitInitialSnapshot([_chatSummary('c1', DateTime(2024))]);
        await tester.pumpAndSettle();

        final updatedChat = ChatSummary(
          mlsGroupId: 'mls_c1',
          name: 'Updated Name',
          groupType: GroupType.group,
          createdAt: DateTime(2024),
          pendingConfirmation: false,
          unreadCount: BigInt.zero,
        );
        _api.emitUpdate(ChatListUpdateTrigger.lastMessageDeleted, updatedChat);
        await tester.pumpAndSettle();

        expect(getResult().chats.first.name, 'Updated Name');
      });
    });
  });
}
