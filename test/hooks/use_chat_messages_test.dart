import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart'
    show ChatMessageQuoteData, ChatMessagesResult, useChatMessages;
import 'package:whitenoise/providers/message_debug_log_provider.dart'
    show MessageStreamEventEntry, MessageStreamEventType, messageDebugLogProvider;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart' show UserStreamItem, UserUpdateTrigger;
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatMessage _message(
  String id,
  DateTime createdAt, {
  String content = 'test',
  String pubkey = testPubkeyA,
  bool isDeleted = false,
  ReactionSummary reactions = const ReactionSummary(byEmoji: [], userReactions: []),
  List<MediaFile> mediaAttachments = const [],
}) => ChatMessage(
  id: id,
  pubkey: pubkey,
  content: content,
  createdAt: createdAt,
  tags: const [],
  isReply: false,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: reactions,
  mediaAttachments: mediaAttachments,
  kind: 9,
);

MediaFile _mediaFile(String id) => MediaFile(
  id: id,
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: '/test/path/$id.jpg',
  originalFileHash: 'hash$id',
  encryptedFileHash: 'encrypted$id',
  mimeType: 'image/jpeg',
  mediaType: 'image',
  blossomUrl: 'https://example.com/$id',
  nostrKey: 'nostr$id',
  createdAt: DateTime(2024),
);

const _emptyMetadata = FlutterMetadata(custom: {});

enum _MetadataMode { normal, fail }

class _MockApi extends MockWnApi {
  StreamController<MessageStreamItem>? controller;
  final userSubscribeCalls = <String>[];
  final failingUserSubscriptions = <String>{};
  // Records the pubkey passed to each crateApiMessagesSubscribeToGroupMessages
  // call, keyed by groupId, so tests can verify the subscription contract.
  final lastSubscribePubkeyByGroup = <String, String?>{};

  void emitInitialSnapshot(List<ChatMessage> messages) {
    controller?.add(MessageStreamItem.initialSnapshot(messages: messages));
  }

  void emitNewMessage(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.newMessage, message: message),
      ),
    );
  }

  void emitDeletedMessage(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.messageDeleted, message: message),
      ),
    );
  }

  void emitReactionAdded(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.reactionAdded, message: message),
      ),
    );
  }

  void emitReactionRemoved(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.reactionRemoved, message: message),
      ),
    );
  }

  void emitDeliveryStatusChanged(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.deliveryStatusChanged, message: message),
      ),
    );
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    controller?.addError(error, stackTrace ?? StackTrace.current);
  }

  void failNextUserSubscription(String pubkey) {
    failingUserSubscriptions.add(pubkey);
  }

  @override
  Stream<MessageStreamItem> crateApiMessagesSubscribeToGroupMessages({
    String? pubkey,
    required String groupId,
  }) {
    lastSubscribePubkeyByGroup[groupId] = pubkey;
    controller?.close();
    controller = StreamController<MessageStreamItem>.broadcast();
    return controller!.stream;
  }

  @override
  Stream<UserStreamItem> crateApiUsersSubscribeToUser({
    required String pubkey,
  }) {
    userSubscribeCalls.add(pubkey);
    if (failingUserSubscriptions.remove(pubkey)) {
      return Stream.error(Exception('metadata stream failed'));
    }
    return super.crateApiUsersSubscribeToUser(pubkey: pubkey);
  }

  List<ChatMessage> olderMessagesResponse = [];
  bool fetchOlderFails = false;
  Completer<List<ChatMessage>>? fetchOlderCompleter;
  ({String? pubkey, String? groupId, DateTime? before, String? beforeMessageId, int? limit})?
  lastFetchOlderCall;

  @override
  Future<List<ChatMessage>> crateApiMessagesFetchAggregatedMessagesForGroup({
    required String pubkey,
    required String groupId,
    DateTime? before,
    String? beforeMessageId,
    int? limit,
  }) async {
    lastFetchOlderCall = (
      pubkey: pubkey,
      groupId: groupId,
      before: before,
      beforeMessageId: beforeMessageId,
      limit: limit,
    );
    if (fetchOlderFails) throw Exception('fetch failed');
    if (fetchOlderCompleter != null) return fetchOlderCompleter!.future;
    return olderMessagesResponse;
  }

  FlutterMetadata? userMetadataResponse;
  _MetadataMode metadataMode = _MetadataMode.normal;
  final metadataCalls = <({String pubkey, bool blocking})>[];

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) {
    metadataCalls.add((pubkey: pubkey, blocking: blockingDataSync));
    switch (metadataMode) {
      case _MetadataMode.normal:
        return Future.value(
          userMetadataResponse ?? const FlutterMetadata(displayName: 'Author', custom: {}),
        );
      case _MetadataMode.fail:
        return Future.error(
          Exception('metadata fetch failed'),
          StackTrace.current,
        );
    }
  }

  @override
  void reset() {
    super.reset();
    controller?.close();
    controller = null;
    userSubscribeCalls.clear();
    failingUserSubscriptions.clear();
    lastSubscribePubkeyByGroup.clear();
    userMetadataResponse = null;
    metadataMode = _MetadataMode.normal;
    metadataCalls.clear();
    olderMessagesResponse = [];
    fetchOlderFails = false;
    fetchOlderCompleter = null;
    lastFetchOlderCall = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _api = _MockApi();

Future<ChatMessagesResult Function()> _pump(WidgetTester tester, String groupId) async {
  return await mountHook(tester, () => useChatMessages(groupId, pubkey: testPubkeyA));
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.reset();
  });

  group('useChatMessages', () {
    testWidgets('starts with empty list', (tester) async {
      final getResult = await _pump(tester, 'group1');

      expect(getResult().messageCount, 0);
    });

    testWidgets('is loading before initial data', (tester) async {
      final getResult = await _pump(tester, 'group1');

      expect(getResult().isLoading, isTrue);
    });

    testWidgets('is not loading after initial data arrives', (tester) async {
      final getResult = await _pump(tester, 'group1');

      _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
      await tester.pumpAndSettle();

      expect(getResult().isLoading, isFalse);
    });

    testWidgets('returns messages from initial snapshot', (tester) async {
      final getResult = await _pump(tester, 'group1');

      _api.emitInitialSnapshot([
        _message('m1', DateTime(2024)),
        _message('m2', DateTime(2024, 1, 2)),
      ]);
      await tester.pump();

      expect(getResult().messageCount, 2);
    });

    testWidgets('returns messages in reversed order (newest first)', (tester) async {
      final getResult = await _pump(tester, 'group1');

      _api.emitInitialSnapshot([
        _message('m1', DateTime(2024)),
        _message('m2', DateTime(2024, 1, 2)),
      ]);
      await tester.pump();

      final result = getResult();
      expect(result.getMessage(0).id, 'm2');
      expect(result.getMessage(1).id, 'm1');
    });

    testWidgets('prepends new message at start (newest first)', (tester) async {
      final getResult = await _pump(tester, 'group1');

      _api.emitInitialSnapshot([
        _message('m1', DateTime(2024)),
      ]);
      await tester.pumpAndSettle();

      _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2)));
      await tester.pumpAndSettle();

      final result = getResult();
      expect(result.messageCount, 2);
      expect(result.getMessage(0).id, 'm2');
    });

    testWidgets('passes the correct pubkey to the subscription', (tester) async {
      await _pump(tester, 'group1');

      // The pubkey recorded by the mock must match the one supplied to useChatMessages.
      expect(_api.lastSubscribePubkeyByGroup['group1'], testPubkeyA);
    });

    group('getReversedMessageIndex', () {
      testWidgets('returns correct index for messages', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2)),
        ]);
        await tester.pump();

        final result = getResult();
        expect(result.getReversedMessageIndex('m2'), 0);
        expect(result.getReversedMessageIndex('m1'), 1);
      });

      testWidgets('returns null for unknown message id', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024)),
        ]);
        await tester.pump();

        expect(getResult().getReversedMessageIndex('unknown'), isNull);
      });
    });

    group('latestMessageId', () {
      group('before initial load', () {
        testWidgets('is null', (tester) async {
          final getResult = await _pump(tester, 'group1');

          expect(getResult().latestMessageId, isNull);
        });
      });

      group('when initial load has messages', () {
        testWidgets('is last message id', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([
            _message('m1', DateTime(2024)),
            _message('m2', DateTime(2024, 1, 2)),
          ]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessageId, 'm2');
        });
      });

      group('when initial load is empty', () {
        testWidgets('is null', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessageId, isNull);
        });
      });

      group('when new message arrives', () {
        testWidgets('updates to new message id', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessageId, isNull);

          _api.emitNewMessage(_message('m1', DateTime(2024)));
          await tester.pumpAndSettle();

          expect(getResult().latestMessageId, 'm1');

          _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2)));
          await tester.pumpAndSettle();

          expect(getResult().latestMessageId, 'm2');
        });
      });
    });

    group('messageDeleted', () {
      testWidgets('does not change message count', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        _api.emitDeletedMessage(_message('m1', DateTime(2024), isDeleted: true));
        await tester.pumpAndSettle();

        expect(getResult().messageCount, 1);
      });

      testWidgets('updates message isDeleted flag', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        _api.emitDeletedMessage(_message('m1', DateTime(2024), isDeleted: true));
        await tester.pumpAndSettle();

        expect(getResult().getMessage(0).isDeleted, isTrue);
      });
    });

    group('latestMessagePubkey', () {
      group('before initial load', () {
        testWidgets('is null', (tester) async {
          final getResult = await _pump(tester, 'group1');

          expect(getResult().latestMessagePubkey, isNull);
        });
      });

      group('when initial load has messages', () {
        testWidgets('is last message pubkey', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([
            _message('m1', DateTime(2024), pubkey: testPubkeyB),
            _message('m2', DateTime(2024, 1, 2), pubkey: testPubkeyC),
          ]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessagePubkey, testPubkeyC);
        });
      });

      group('when initial load is empty', () {
        testWidgets('is null', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessagePubkey, isNull);
        });
      });

      group('when new message arrives', () {
        testWidgets('updates to new message pubkey', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([]);
          await tester.pumpAndSettle();

          expect(getResult().latestMessagePubkey, isNull);

          _api.emitNewMessage(_message('m1', DateTime(2024), pubkey: testPubkeyB));
          await tester.pumpAndSettle();

          expect(getResult().latestMessagePubkey, testPubkeyB);

          _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2), pubkey: testPubkeyC));
          await tester.pumpAndSettle();

          expect(getResult().latestMessagePubkey, testPubkeyC);
        });
      });
    });

    group('reactionAdded', () {
      testWidgets('does not change message count', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        final reactionsAfter = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          userReactions: const [],
        );
        _api.emitReactionAdded(_message('m1', DateTime(2024), reactions: reactionsAfter));
        await tester.pumpAndSettle();

        expect(getResult().messageCount, 1);
      });

      testWidgets('updates message reactions', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        expect(getResult().getMessage(0).reactions.byEmoji, isEmpty);

        final reactionsAfter = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          userReactions: const [],
        );
        _api.emitReactionAdded(_message('m1', DateTime(2024), reactions: reactionsAfter));
        await tester.pumpAndSettle();

        expect(getResult().getMessage(0).reactions.byEmoji, hasLength(1));
        expect(getResult().getMessage(0).reactions.byEmoji.first.emoji, '👍');
      });
    });

    group('reactionRemoved', () {
      testWidgets('does not change message count', (tester) async {
        final getResult = await _pump(tester, 'group1');

        final initialReactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          userReactions: const [],
        );
        _api.emitInitialSnapshot([_message('m1', DateTime(2024), reactions: initialReactions)]);
        await tester.pumpAndSettle();

        _api.emitReactionRemoved(_message('m1', DateTime(2024)));
        await tester.pumpAndSettle();

        expect(getResult().messageCount, 1);
      });

      testWidgets('updates message reactions', (tester) async {
        final getResult = await _pump(tester, 'group1');

        final initialReactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          userReactions: const [],
        );
        _api.emitInitialSnapshot([_message('m1', DateTime(2024), reactions: initialReactions)]);
        await tester.pumpAndSettle();

        expect(getResult().getMessage(0).reactions.byEmoji, hasLength(1));

        _api.emitReactionRemoved(_message('m1', DateTime(2024)));
        await tester.pumpAndSettle();

        expect(getResult().getMessage(0).reactions.byEmoji, isEmpty);
      });
    });

    group('stream error handling', () {
      testWidgets('handles stream error via handleError', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        expect(getResult().messageCount, 1);

        _api.emitError(Exception('test stream error'));
        await tester.pump();

        expect(getResult().messageCount, 1);
      });

      testWidgets('snapshot reports hasError after stream error', (tester) async {
        await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        _api.emitError(Exception('snapshot error test'));
        await tester.pump();
        await tester.pump();
      });

      testWidgets('logs stream error to debugLog when provided', (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final debugLog = container.read(messageDebugLogProvider.notifier);

        await mountHook(
          tester,
          () => useChatMessages('group1', pubkey: testPubkeyA, debugLog: debugLog),
        );

        _api.emitError(Exception('debug log error'));
        await tester.pump();
        await Future<void>.microtask(() {});
        await tester.pump();

        expect(
          container.read(messageDebugLogProvider).streamLog,
          isNotEmpty,
        );
      });
    });

    group('fetchAuthorMetadata error handling', () {
      testWidgets('handles metadata fetch failure gracefully', (tester) async {
        _api.metadataMode = _MetadataMode.fail;
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: testPubkeyB, content: 'Hello'),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pumpAndSettle();

        final preview = getResult().getChatMessageQuote('m1');
        expect(preview, isNotNull);
        expect(preview!.authorMetadata, isNull);
      });

      testWidgets('retries author metadata subscription after a stream error', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.seedUserInitialSnapshot(
          authorPubkey,
          metadata: const FlutterMetadata(
            displayName: 'Recovered Author',
            custom: {},
          ),
        );
        _api.failNextUserSubscription(authorPubkey);
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();

        expect(getResult().getChatMessageQuote('m1')!.authorMetadata, isNull);
        await tester.pump();

        expect(_api.userSubscribeCalls, [authorPubkey]);

        expect(getResult().getChatMessageQuote('m1')!.authorMetadata, isNull);
        await tester.pump();

        final preview = getResult().getChatMessageQuote('m1');
        expect(_api.userSubscribeCalls, [authorPubkey, authorPubkey]);
        expect(preview?.authorMetadata?.displayName, 'Recovered Author');
      });

      testWidgets('resubscribes after metadata stream closes', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.seedUserInitialSnapshot(authorPubkey);
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();

        getResult().getChatMessageQuote('m1');
        await tester.pump();
        await _api.userStreamControllers[authorPubkey]?.close();
        await tester.pump();

        getResult().getChatMessageQuote('m1');
        await tester.pump();

        expect(_api.userSubscribeCalls, [authorPubkey, authorPubkey]);
      });
    });

    group('duplicate messages', () {
      testWidgets('ignores duplicate newMessage update with same id', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pumpAndSettle();

        _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2)));
        await tester.pumpAndSettle();

        _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2)));
        await tester.pumpAndSettle();

        final result = getResult();
        expect(result.messageCount, 2);
        expect(result.getMessage(0).id, 'm2');
        expect(result.getMessage(1).id, 'm1');
      });

      testWidgets('ignores newMessage update for id already in initial snapshot', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2)),
        ]);
        await tester.pumpAndSettle();

        _api.emitNewMessage(_message('m2', DateTime(2024, 1, 2)));
        await tester.pumpAndSettle();

        final result = getResult();
        expect(result.messageCount, 2);
        expect(result.getMessage(0).id, 'm2');
        expect(result.getMessage(1).id, 'm1');
      });

      testWidgets('still updates message data when duplicate id arrives', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024), content: 'original')]);
        await tester.pumpAndSettle();

        _api.emitNewMessage(_message('m1', DateTime(2024), content: 'updated'));
        await tester.pumpAndSettle();

        final result = getResult();
        expect(result.messageCount, 1);
        expect(result.getMessage(0).content, 'updated');
      });
    });

    group('deliveryStatusChanged', () {
      testWidgets('updates message data in place', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), content: 'hello'),
          _message('m2', DateTime(2024, 1, 2), content: 'world'),
        ]);
        await tester.pumpAndSettle();

        _api.emitDeliveryStatusChanged(_message('m1', DateTime(2024), content: 'hello-updated'));
        await tester.pumpAndSettle();

        final result = getResult();
        expect(result.messageCount, 2);
        expect(result.getMessageById('m1')?.content, 'hello-updated');
      });

      testWidgets('does not change message order', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2)),
        ]);
        await tester.pumpAndSettle();

        _api.emitDeliveryStatusChanged(_message('m1', DateTime(2024)));
        await tester.pumpAndSettle();

        final result = getResult();
        expect(result.getMessage(0).id, 'm2');
        expect(result.getMessage(1).id, 'm1');
      });
    });

    group('getMessageById', () {
      testWidgets('returns null before any snapshot', (tester) async {
        final getResult = await _pump(tester, 'group1');

        expect(getResult().getMessageById('m1'), isNull);
      });

      testWidgets('returns null for unknown id', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pump();

        expect(getResult().getMessageById('unknown'), isNull);
      });

      testWidgets('returns message by id after snapshot', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), content: 'hello'),
          _message('m2', DateTime(2024, 1, 2)),
        ]);
        await tester.pump();

        expect(getResult().getMessageById('m1')?.content, 'hello');
      });

      testWidgets('returns updated message after update event', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024), content: 'original')]);
        await tester.pumpAndSettle();

        _api.emitNewMessage(_message('m1', DateTime(2024), content: 'updated'));
        await tester.pumpAndSettle();

        expect(getResult().getMessageById('m1')?.content, 'updated');
      });
    });

    group('getChatMessageQuote', () {
      testWidgets('returns null when replyId is null', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pump();

        expect(getResult().getChatMessageQuote(null), isNull);
      });

      testWidgets('returns isNotFound when message is missing', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
        await tester.pump();

        final preview = getResult().getChatMessageQuote('unknown');
        expect(preview, isNotNull);
        expect(preview!.isNotFound, isTrue);
        expect(preview.messageId, 'unknown');
        expect(preview.authorPubkey, '');
        expect(preview.content, '');
        expect(preview.mediaFile, isNull);
        expect(preview.authorMetadata, isNull);
      });

      testWidgets('returns isNotFound when message is deleted', (tester) async {
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2), isDeleted: true),
        ]);
        await tester.pump();

        final preview = getResult().getChatMessageQuote('m2');
        expect(preview, isNotNull);
        expect(preview!.isNotFound, isTrue);
        expect(preview.mediaFile, isNull);
        expect(preview.messageId, 'm2');
      });

      testWidgets('returns preview when message is found', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.seedUserInitialSnapshot(
          authorPubkey,
          metadata: const FlutterMetadata(
            displayName: 'Original Author',
            name: 'author',
            custom: {},
          ),
        );
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Original content'),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pump();

        final preview = getResult().getChatMessageQuote('m1');
        expect(preview, isNotNull);
        expect(preview!.isNotFound, isFalse);
        expect(preview.mediaFile, isNull);
        expect(preview.messageId, 'm1');
        expect(preview.authorPubkey, authorPubkey);
        expect(preview.content, 'Original content');
        expect(preview.authorMetadata?.displayName, 'Original Author');
      });

      testWidgets('returns hasMedia true when message has media attachments', (tester) async {
        _api.userMetadataResponse = const FlutterMetadata(custom: {});
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message(
            'm1',
            DateTime(2024),
            content: 'With media',
            mediaAttachments: [_mediaFile('file1')],
          ),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pumpAndSettle();

        final preview = getResult().getChatMessageQuote('m1');
        expect(preview, isNotNull);
        expect(preview!.mediaFile, isNotNull);
        expect(preview.content, 'With media');
      });

      testWidgets('rebuilds with author metadata after async fetch completes', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.seedUserInitialSnapshot(
          authorPubkey,
          metadata: const FlutterMetadata(
            displayName: 'Async Author',
            custom: {},
          ),
        );
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();

        final previewBefore = getResult().getChatMessageQuote('m1');
        expect(previewBefore!.authorMetadata, isNull);

        await tester.pump();

        final previewAfter = getResult().getChatMessageQuote('m1');
        expect(previewAfter!.authorMetadata, isNotNull);
        expect(previewAfter.authorMetadata?.displayName, 'Async Author');
      });

      testWidgets('updates author metadata when the user stream emits later', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.seedUserInitialSnapshot(authorPubkey);
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pump();

        expect(getResult().getChatMessageQuote('m1')!.authorMetadata, _emptyMetadata);

        _api.emitUserUpdate(
          authorPubkey,
          trigger: UserUpdateTrigger.metadataChanged,
          metadata: const FlutterMetadata(
            displayName: 'Relay Author',
            name: 'relay_author',
            custom: {},
          ),
        );
        await tester.pump();

        final preview = getResult().getChatMessageQuote('m1');
        expect(preview!.authorMetadata, isNotNull);
        expect(preview.authorMetadata?.displayName, 'Relay Author');
        expect(_api.metadataCalls.every((c) => !c.blocking), isTrue);
      });
    });

    group('pagination', () {
      group('hasMoreMessages', () {
        testWidgets('starts as true', (tester) async {
          final getResult = await _pump(tester, 'group1');

          expect(getResult().hasMoreMessages, isTrue);
        });

        testWidgets('stays true when loadOlderMessages returns messages', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m2', DateTime(2024, 1, 2))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [_message('m1', DateTime(2024))];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().hasMoreMessages, isTrue);
        });

        testWidgets('becomes false when loadOlderMessages returns empty', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().hasMoreMessages, isFalse);
        });
      });

      group('isLoadingOlderMessages', () {
        testWidgets('starts as false', (tester) async {
          final getResult = await _pump(tester, 'group1');

          expect(getResult().isLoadingOlderMessages, isFalse);
        });
      });

      group('loadOlderMessages', () {
        testWidgets('does nothing before initial snapshot', (tester) async {
          final getResult = await _pump(tester, 'group1');

          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().messageCount, 0);
          expect(_api.lastFetchOlderCall, isNull);
        });

        testWidgets('prepends older messages before existing ones', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m2', DateTime(2024, 1, 2))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [_message('m1', DateTime(2024))];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          final result = getResult();
          expect(result.messageCount, 2);
          expect(result.getMessage(0).id, 'm2');
          expect(result.getMessage(1).id, 'm1');
        });

        testWidgets('passes cursor from oldest loaded message', (tester) async {
          final getResult = await _pump(tester, 'group1');
          final oldestDate = DateTime(2024);

          _api.emitInitialSnapshot([
            _message('m1', oldestDate),
            _message('m2', DateTime(2024, 1, 2)),
          ]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [];
          await getResult().loadOlderMessages();

          expect(_api.lastFetchOlderCall?.before, oldestDate);
          expect(_api.lastFetchOlderCall?.beforeMessageId, 'm1');
        });

        testWidgets('does not load when hasMoreMessages is false', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          _api.lastFetchOlderCall = null;
          await getResult().loadOlderMessages();

          expect(_api.lastFetchOlderCall, isNull);
        });

        testWidgets('ignores already-loaded messages in response', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m2', DateTime(2024, 1, 2))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [
            _message('m1', DateTime(2024)),
            _message('m2', DateTime(2024, 1, 2)),
          ];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().messageCount, 2);
        });

        testWidgets('handles fetch errors gracefully', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          _api.fetchOlderFails = true;
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().messageCount, 1);
          expect(getResult().isLoadingOlderMessages, isFalse);
          expect(getResult().hasMoreMessages, isTrue);
        });

        testWidgets('total count includes both older and stream messages', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([
            _message('m3', DateTime(2024, 1, 3)),
            _message('m4', DateTime(2024, 1, 4)),
          ]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [
            _message('m1', DateTime(2024)),
            _message('m2', DateTime(2024, 1, 2)),
          ];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().messageCount, 4);
          expect(getResult().getMessage(3).id, 'm1');
          expect(getResult().getMessage(2).id, 'm2');
          expect(getResult().getMessage(1).id, 'm3');
          expect(getResult().getMessage(0).id, 'm4');
        });

        testWidgets('new stream messages are still appended at newest end', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m2', DateTime(2024, 1, 2))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [_message('m1', DateTime(2024))];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          _api.emitNewMessage(_message('m3', DateTime(2024, 1, 3)));
          await tester.pumpAndSettle();

          final result = getResult();
          expect(result.messageCount, 3);
          expect(result.getMessage(0).id, 'm3');
          expect(result.getMessage(1).id, 'm2');
          expect(result.getMessage(2).id, 'm1');
        });

        testWidgets('concurrent calls are ignored while already loading', (tester) async {
          final completer = Completer<List<ChatMessage>>();
          _api.fetchOlderCompleter = completer;
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          // Start loading and don't await — leaves isLoadingOlderMessages = true
          unawaited(getResult().loadOlderMessages());
          await tester.pump();

          expect(getResult().isLoadingOlderMessages, isTrue);

          // Second call should be a no-op
          _api.lastFetchOlderCall = null;
          await getResult().loadOlderMessages();
          expect(
            _api.lastFetchOlderCall,
            isNull,
            reason: 'second concurrent call must not trigger a fetch',
          );

          completer.complete([]);
          await tester.pumpAndSettle();
        });

        testWidgets('all-duplicate response sets hasMoreMessages false', (tester) async {
          final getResult = await _pump(tester, 'group1');

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          // Return the same message that's already loaded
          _api.olderMessagesResponse = [_message('m1', DateTime(2024))];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(getResult().hasMoreMessages, isFalse);
          expect(getResult().messageCount, 1);
        });

        group('sliding-window eviction', () {
          // _kWindowSize is 500. Build enough messages to exceed the window.
          // The initial snapshot provides the most-recent 400 messages and the
          // page load provides 200 older ones, for a combined 600 which exceeds
          // the 500-message window.
          const windowSize = 500;
          const initialCount = 400;
          const pageCount = 200;

          List<ChatMessage> makeMessages(int start, int end) => [
            for (var i = start; i <= end; i++)
              _message('m$i', DateTime(2024, 1, i ~/ 28 + 1, i % 28 + 1)),
          ];

          testWidgets('truncates combined list to window size', (tester) async {
            final getResult = await _pump(tester, 'group1');

            // Most-recent messages from the live stream snapshot.
            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            expect(getResult().messageCount, initialCount);

            // An older page that, when prepended, exceeds the window.
            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            expect(getResult().messageCount, windowSize);
          });

          testWidgets('evicted messages are removed from messagesById', (tester) async {
            final getResult = await _pump(tester, 'group1');

            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            // Eviction trims from the newest end (tail), so the newest
            // messages from the initial snapshot are evicted.
            final evictedCount = pageCount + initialCount - windowSize;
            final firstEvictedId = pageCount + initialCount - evictedCount + 1;
            for (var i = firstEvictedId; i <= pageCount + initialCount; i++) {
              expect(
                getResult().getMessageById('m$i'),
                isNull,
                reason: 'm$i should have been evicted',
              );
            }
          });

          testWidgets('keeps hasMoreMessages true after eviction', (tester) async {
            // Eviction must never close the pagination gate. If the window
            // trims the oldest messages, those pages are still fetchable.
            final getResult = await _pump(tester, 'group1');

            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            // A page load that exceeds the window triggers eviction.
            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            // Eviction happened (total would have been 600 > 500).
            expect(getResult().messageCount, windowSize);
            // The gate must remain open so the user can reload evicted pages.
            expect(getResult().hasMoreMessages, isTrue);
          });

          testWidgets('indexById is consistent with messageIds after eviction', (tester) async {
            final getResult = await _pump(tester, 'group1');

            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            final result = getResult();
            expect(result.messageCount, windowSize);
            // getReversedMessageIndex must return non-null for every message
            // that is still in the window. Eviction trims the newest end, so
            // the surviving messages are m1 through m${windowSize}.
            for (var i = 1; i <= windowSize; i++) {
              expect(
                result.getReversedMessageIndex('m$i'),
                isNotNull,
                reason: 'm$i should still be in the window',
              );
            }
          });

          testWidgets('oldest messages are always preserved after eviction', (tester) async {
            final getResult = await _pump(tester, 'group1');

            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            final result = getResult();
            // The oldest message (highest reversed index) must be the first
            // message from the prepended page, proving older messages are kept.
            expect(result.getMessage(result.messageCount - 1).id, 'm1');
          });

          testWidgets('evicts from newest end so newly loaded older messages are kept', (
            tester,
          ) async {
            final getResult = await _pump(tester, 'group1');

            _api.emitInitialSnapshot(makeMessages(pageCount + 1, pageCount + initialCount));
            await tester.pumpAndSettle();

            _api.olderMessagesResponse = makeMessages(1, pageCount);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            final result = getResult();
            final evictedCount = pageCount + initialCount - windowSize;
            // The oldest message in the window must be from the prepended page,
            // NOT from the initial snapshot. This proves that eviction removed
            // the newest (tail) messages rather than the just-loaded oldest.
            expect(result.getMessage(result.messageCount - 1).id, 'm1');
            // The newest message after eviction should be the last initial
            // message minus what was evicted from the tail.
            expect(
              result.getMessage(0).id,
              'm${pageCount + initialCount - evictedCount}',
            );
          });

          testWidgets('repeated pagination at window capacity makes progress', (tester) async {
            // Simulates 594 messages with window=500, page=50.
            // After the window fills, each subsequent page must still advance
            // the cursor (make progress) rather than re-fetching the same page
            // in an infinite loop.
            final getResult = await _pump(tester, 'group1');

            // Start with a full window of the newest messages.
            _api.emitInitialSnapshot(makeMessages(95, 594));
            await tester.pumpAndSettle();
            expect(getResult().messageCount, windowSize);

            // Page load: the next 50 older messages (45-94).
            _api.olderMessagesResponse = makeMessages(45, 94);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            // After eviction the oldest message in the window must be from the
            // just-loaded page — proving progress was made.
            final afterFirstLoad = getResult();
            expect(afterFirstLoad.messageCount, windowSize);
            expect(afterFirstLoad.getMessage(afterFirstLoad.messageCount - 1).id, 'm45');

            // Second page: messages 1-44.
            _api.olderMessagesResponse = makeMessages(1, 44);
            await getResult().loadOlderMessages();
            await tester.pumpAndSettle();

            // The cursor must have advanced so message m1 is now reachable.
            final afterSecondLoad = getResult();
            expect(afterSecondLoad.getMessage(afterSecondLoad.messageCount - 1).id, 'm1');
          });
        });
      });

      group('debugLog pageFetch entries', () {
        late ProviderContainer container;

        setUp(() {
          container = ProviderContainer();
        });

        tearDown(() => container.dispose());

        Future<ChatMessagesResult Function()> pumpWithDebugLog(WidgetTester tester) async {
          final debugLog = container.read(messageDebugLogProvider.notifier);
          ChatMessagesResult? result;
          await mountHook(
            tester,
            () {
              final r = useChatMessages('group1', pubkey: testPubkeyA, debugLog: debugLog);
              result = r;
              return r;
            },
          );
          return () => result!;
        }

        List<MessageStreamEventEntry> pageFetchEntries() => container
            .read(messageDebugLogProvider)
            .streamLog
            .where((e) => e.eventType == MessageStreamEventType.pageFetch)
            .toList();

        testWidgets('logs fetching then prepended when messages are loaded', (tester) async {
          final getResult = await pumpWithDebugLog(tester);

          _api.emitInitialSnapshot([_message('m2', DateTime(2024, 1, 2))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [_message('m1', DateTime(2024))];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          // pageFetchEntries() returns entries newest-first (matching streamLog
          // insertion order). entries.last is the oldest log entry ('fetching',
          // logged when the request started) and entries.first is the newest
          // ('prepended', logged after the response arrived).
          final entries = pageFetchEntries();
          expect(entries, hasLength(2));
          expect(entries.last.trigger, 'fetching');
          expect(entries.first.trigger, 'prepended');
          expect(entries.first.messageCount, 1);
        });

        testWidgets('logs end outcome when no more messages returned', (tester) async {
          final getResult = await pumpWithDebugLog(tester);

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          _api.olderMessagesResponse = [];
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          expect(pageFetchEntries().first.trigger, 'end');
        });

        testWidgets('logs error outcome when fetch fails', (tester) async {
          final getResult = await pumpWithDebugLog(tester);

          _api.emitInitialSnapshot([_message('m1', DateTime(2024))]);
          await tester.pumpAndSettle();

          _api.fetchOlderFails = true;
          await getResult().loadOlderMessages();
          await tester.pumpAndSettle();

          final entries = pageFetchEntries();
          expect(entries.first.trigger, 'error');
          expect(entries.first.error, isNotNull);
        });
      });
    });
  });

  group('ChatMessageQuoteData', () {
    test('has messageId', () {
      const ChatMessageQuoteData chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.messageId, 'msg-123');
    });

    test('has authorPubkey', () {
      const ChatMessageQuoteData chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.authorPubkey, testPubkeyA);
    });

    test('has authorMetadata', () {
      const meta = FlutterMetadata(displayName: 'Author', custom: {});
      const chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: meta,
        content: 'hi',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.authorMetadata, meta);
    });

    test('allows null authorMetadata', () {
      const chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.authorMetadata, isNull);
    });

    test('has content', () {
      const chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'Reply text',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.content, 'Reply text');
    });

    test('has isNotFound boolean', () {
      const chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: true,
        mediaFile: null,
      );
      expect(chatMessageQuote.isNotFound, isTrue);
    });

    test('has mediaFile', () {
      final mediaFile = _mediaFile('test');
      final chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: false,
        mediaFile: mediaFile,
      );
      expect(chatMessageQuote.mediaFile, mediaFile);
    });

    test('allows null mediaFile', () {
      const chatMessageQuote = (
        messageId: 'msg-123',
        authorPubkey: testPubkeyA,
        authorMetadata: null,
        content: 'hi',
        isNotFound: false,
        mediaFile: null,
      );
      expect(chatMessageQuote.mediaFile, isNull);
    });
  });
}
