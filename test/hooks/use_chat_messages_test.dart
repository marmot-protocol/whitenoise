import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart'
    show ChatMessageQuoteData, ChatMessagesResult, useChatMessages;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
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

enum _MetadataMode { normal, emptyThenSuccess }

class _MockApi extends MockWnApi {
  StreamController<MessageStreamItem>? controller;

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

  @override
  Stream<MessageStreamItem> crateApiMessagesSubscribeToGroupMessages({
    required String groupId,
  }) {
    controller?.close();
    controller = StreamController<MessageStreamItem>.broadcast();
    return controller!.stream;
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
      case _MetadataMode.emptyThenSuccess:
        return blockingDataSync
            ? Future.value(
                userMetadataResponse ?? const FlutterMetadata(displayName: 'Author', custom: {}),
              )
            : Future.value(_emptyMetadata);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _api = _MockApi();

Future<ChatMessagesResult Function()> _pump(WidgetTester tester, String groupId) async {
  return await mountHook(tester, () => useChatMessages(groupId));
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.controller?.close();
    _api.controller = null;
    _api.userMetadataResponse = null;
    _api.metadataMode = _MetadataMode.normal;
    _api.metadataCalls.clear();
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
        _api.userMetadataResponse = const FlutterMetadata(
          displayName: 'Original Author',
          name: 'author',
          custom: {},
        );
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Original content'),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pumpAndSettle();

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
        _api.userMetadataResponse = const FlutterMetadata(
          displayName: 'Async Author',
          custom: {},
        );
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();

        final previewBefore = getResult().getChatMessageQuote('m1');
        expect(previewBefore!.authorMetadata, isNull);

        await tester.pumpAndSettle();

        final previewAfter = getResult().getChatMessageQuote('m1');
        expect(previewAfter!.authorMetadata, isNotNull);
        expect(previewAfter.authorMetadata?.displayName, 'Async Author');
      });

      testWidgets('fetches metadata from relays when local cache is empty', (tester) async {
        const authorPubkey = testPubkeyB;
        _api.metadataMode = _MetadataMode.emptyThenSuccess;
        _api.userMetadataResponse = const FlutterMetadata(
          displayName: 'Relay Author',
          name: 'relay_author',
          custom: {},
        );
        final getResult = await _pump(tester, 'group1');

        _api.emitInitialSnapshot([
          _message('m1', DateTime(2024), pubkey: authorPubkey, content: 'Hello'),
        ]);
        await tester.pump();
        getResult().getChatMessageQuote('m1');
        await tester.pumpAndSettle();

        final preview = getResult().getChatMessageQuote('m1');
        expect(preview!.authorMetadata, isNotNull);
        expect(preview.authorMetadata?.displayName, 'Relay Author');
        expect(_api.metadataCalls.any((c) => c.blocking), isTrue);
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
