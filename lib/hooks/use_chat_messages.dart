import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';

final _logger = Logger('useChatMessages');

/// Maximum number of message IDs kept in memory at once. When prepending older
/// messages would push the total past this limit, the tail (oldest end) is
/// evicted and hasMoreMessages is reset to true so the user can reload them by
/// scrolling up. 500 is large enough that normal usage never notices the cap,
/// yet small enough to prevent OOM in long-running sessions.
const _kWindowSize = 500;

typedef ChatMessageQuoteData = ({
  String messageId,
  String authorPubkey,
  FlutterMetadata? authorMetadata,
  String content,
  MediaFile? mediaFile,
  bool isNotFound,
});

typedef ChatMessagesResult = ({
  int messageCount,
  ChatMessage Function(int reversedIndex) getMessage,
  int? Function(String messageId) getReversedMessageIndex,
  ChatMessage? Function(String messageId) getMessageById,
  bool isLoading,
  bool isLoadingOlderMessages,
  bool hasMoreMessages,
  Future<void> Function() loadOlderMessages,
  String? latestMessageId,
  String? latestMessagePubkey,
  ChatMessageQuoteData? Function(String? replyId) getChatMessageQuote,
  FlutterMetadata? Function(String pubkey) getAuthorMetadata,
});

ChatMessagesResult useChatMessages(
  String groupId, {
  required String pubkey,
  MessageDebugLogNotifier? debugLog,
}) {
  final messageIds = useRef<List<String>>([]);
  final messagesById = useRef<Map<String, ChatMessage>>({});
  final indexById = useRef<Map<String, int>>({});
  final authorsMetadataByPubkey = useState<Map<String, FlutterMetadata>>({});
  final metadataSubscriptionsByPubkey = useRef<Map<String, StreamSubscription<FlutterMetadata>>>(
    {},
  );
  final isLoadingOlderMessages = useState(false);
  final hasMoreMessages = useState(true);
  // Incremented whenever older messages are prepended to messageIds. Because
  // messageIds is stored in a useRef it does not trigger rebuilds on its own;
  // this counter forces a rebuild so the list reflects the newly prepended
  // pages. Do not remove.
  final paginationVersion = useState(0);

  // Set to true in the disposal teardown so any in-flight loadOlderMessages
  // call knows not to write to hook state after the widget is gone.
  final isDisposed = useRef(false);
  useEffect(() {
    isDisposed.value = false;
    return () {
      isDisposed.value = true;
    };
  }, []);

  // Monotonically increasing counter bumped whenever groupId or pubkey changes.
  // loadOlderMessages captures the current value at call time and checks it
  // after the await; a mismatch means the account or group changed while the
  // fetch was in-flight and the response must be discarded.
  final requestTokenRef = useRef(0);

  useEffect(() {
    messageIds.value = [];
    messagesById.value = {};
    indexById.value = {};
    isLoadingOlderMessages.value = false;
    hasMoreMessages.value = true;
    // Reset rebuild counter when switching groups or accounts (see declaration).
    paginationVersion.value = 0;
    requestTokenRef.value++;
    return null;
  }, [groupId, pubkey]);

  final stream = useMemoized(
    () {
      _logger.info(
        'stream CREATING groupId=$groupId calling subscribeToGroupMessages',
      );
      Future.microtask(() => debugLog?.logStreamConnected(groupId: groupId));

      return subscribeToGroupMessages(pubkey: pubkey, groupId: groupId)
          .handleError((Object e, StackTrace st) {
            _logger.severe(
              'stream ERROR groupId=$groupId error=$e',
              e,
              st,
            );
            Future.microtask(
              () => debugLog?.logStreamError(groupId: groupId, error: e, stackTrace: st),
            );
            throw e;
          })
          .transform(
            StreamTransformer.fromHandlers(
              handleDone: (EventSink<MessageStreamItem> sink) {
                _logger.info('stream DONE groupId=$groupId subscription closed');
                Future.microtask(
                  () => debugLog?.logStreamDisconnected(groupId: groupId),
                );
                sink.close();
              },
            ),
          )
          .map((item) {
            return item.when(
              initialSnapshot: (initialChatMessages) {
                _logger.info(
                  'stream initialSnapshot groupId=$groupId count=${initialChatMessages.length}',
                );
                Future.microtask(
                  () => debugLog?.logStreamSnapshot(
                    groupId: groupId,
                    messageCount: initialChatMessages.length,
                  ),
                );

                messageIds.value = [];
                messagesById.value = {};
                indexById.value = {};

                for (var i = 0; i < initialChatMessages.length; i++) {
                  final message = initialChatMessages[i];
                  messageIds.value.add(message.id);
                  messagesById.value[message.id] = message;
                  indexById.value[message.id] = i;
                }

                final lastMessage = initialChatMessages.isNotEmpty
                    ? initialChatMessages.last
                    : null;
                return (
                  messageCount: initialChatMessages.length,
                  latestMessageId: lastMessage?.id,
                  latestMessagePubkey: lastMessage?.pubkey,
                );
              },
              update: (update) {
                final message = update.message;
                final triggerName = update.trigger.name;
                _logger.info(
                  'stream update groupId=$groupId trigger=$triggerName '
                  'messageId=${message.id} isDeleted=${message.isDeleted}',
                );
                Future.microtask(
                  () => debugLog?.logStreamUpdate(
                    groupId: groupId,
                    trigger: triggerName,
                    messageId: message.id,
                  ),
                );

                messagesById.value[message.id] = message;

                if (update.trigger == UpdateTrigger.newMessage &&
                    !indexById.value.containsKey(message.id)) {
                  final newIndex = messageIds.value.length;
                  messageIds.value.add(message.id);
                  indexById.value[message.id] = newIndex;
                }

                final lastId = messageIds.value.isNotEmpty ? messageIds.value.last : null;
                final lastPubkey = lastId != null ? messagesById.value[lastId]?.pubkey : null;
                return (
                  messageCount: messageIds.value.length,
                  latestMessageId: lastId,
                  latestMessagePubkey: lastPubkey,
                );
              },
            );
          });
    },
    [groupId, pubkey],
  );

  final initialData = (
    messageCount: 0,
    latestMessageId: null,
    latestMessagePubkey: null,
  );
  final snapshot = useStream(stream, initialData: initialData);
  final isLoading = snapshot.connectionState == ConnectionState.waiting;

  final prevState = useRef<ConnectionState?>(null);
  final prevHasError = useRef(false);
  useEffect(
    () {
      final state = snapshot.connectionState;
      if (prevState.value != state) {
        prevState.value = state;
        _logger.info(
          'stream snapshot groupId=$groupId connectionState=$state '
          'hasData=${snapshot.hasData} hasError=${snapshot.hasError} '
          'messageCount=${snapshot.data?.messageCount}',
        );
      }
      if (snapshot.hasError && !prevHasError.value) {
        prevHasError.value = true;
        _logger.severe(
          'stream snapshot ERROR groupId=$groupId',
          snapshot.error,
          snapshot.stackTrace,
        );
        Future.microtask(
          () => debugLog?.logStreamError(
            groupId: groupId,
            error: snapshot.error!,
            stackTrace: snapshot.stackTrace,
          ),
        );
      } else if (!snapshot.hasError) {
        prevHasError.value = false;
      }
      return null;
    },
    [snapshot.connectionState, snapshot.hasData, snapshot.hasError, snapshot.data?.messageCount],
  );

  ChatMessage getMessage(int reversedIndex) {
    final length = messageIds.value.length;
    final naturalIndex = length - 1 - reversedIndex;
    final messageId = messageIds.value[naturalIndex];
    return messagesById.value[messageId]!;
  }

  int? getReversedMessageIndex(String messageId) {
    final naturalIndex = indexById.value[messageId];
    if (naturalIndex == null) return null;
    return messageIds.value.length - 1 - naturalIndex;
  }

  ChatMessage? getMessageById(String messageId) {
    return messagesById.value[messageId];
  }

  void removeAuthorMetadataSubscription(String pubkey) {
    final subscription = metadataSubscriptionsByPubkey.value[pubkey];
    if (subscription == null) return;

    metadataSubscriptionsByPubkey.value = {
      ...metadataSubscriptionsByPubkey.value,
    }..remove(pubkey);
    unawaited(subscription.cancel());
  }

  void ensureAuthorMetadataSubscription(String pubkey) {
    if (metadataSubscriptionsByPubkey.value.containsKey(pubkey)) return;

    _logger.fine('ensureAuthorMetadataSubscription pubkey=${pubkey.substring(0, 8)}…');
    final subscription = UserService(pubkey).watchMetadata().listen(
      (metadata) {
        _logger.fine(
          'author metadata update pubkey=${pubkey.substring(0, 8)}… '
          'name=${metadata.name} displayName=${metadata.displayName}',
        );
        authorsMetadataByPubkey.value = {
          ...authorsMetadataByPubkey.value,
          pubkey: metadata,
        };
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.severe(
          'author metadata stream failed pubkey=${pubkey.substring(0, 8)}…',
          error,
          stackTrace,
        );
        removeAuthorMetadataSubscription(pubkey);
      },
      onDone: () => removeAuthorMetadataSubscription(pubkey),
      cancelOnError: true,
    );

    metadataSubscriptionsByPubkey.value = {
      ...metadataSubscriptionsByPubkey.value,
      pubkey: subscription,
    };
  }

  FlutterMetadata? getAuthorMetadata(String pubkey) {
    final existingAuthorMetadata = authorsMetadataByPubkey.value[pubkey];
    ensureAuthorMetadataSubscription(pubkey);
    return existingAuthorMetadata;
  }

  ChatMessageQuoteData? getChatMessageQuote(String? replyId) {
    if (replyId == null) return null;
    final message = getMessageById(replyId);
    if (message == null || message.isDeleted) {
      return (
        messageId: replyId,
        authorPubkey: '',
        authorMetadata: null,
        content: '',
        mediaFile: null,
        isNotFound: true,
      );
    }
    return (
      messageId: replyId,
      authorPubkey: message.pubkey,
      authorMetadata: getAuthorMetadata(message.pubkey),
      content: message.content,
      mediaFile: message.mediaAttachments.isNotEmpty ? message.mediaAttachments.first : null,
      isNotFound: false,
    );
  }

  useEffect(() {
    return () {
      for (final subscription in metadataSubscriptionsByPubkey.value.values) {
        subscription.cancel();
      }
      metadataSubscriptionsByPubkey.value = {};
    };
  }, [groupId, pubkey]);

  Future<void> loadOlderMessages() async {
    if (isLoadingOlderMessages.value) {
      _logger.info('loadOlderMessages groupId=$groupId: skipped (already loading)');
      return;
    }
    if (!hasMoreMessages.value) {
      _logger.info('loadOlderMessages groupId=$groupId: skipped (no more messages)');
      return;
    }
    if (messageIds.value.isEmpty) {
      _logger.info('loadOlderMessages groupId=$groupId: skipped (no messages loaded yet)');
      return;
    }

    final oldestId = messageIds.value.first;
    final oldestMessage = messagesById.value[oldestId];
    if (oldestMessage == null) return;

    final requestGroupId = groupId;
    final requestToken = requestTokenRef.value;
    isLoadingOlderMessages.value = true;
    _logger.info(
      'loadOlderMessages groupId=$groupId: fetching page before=${oldestMessage.createdAt} cursorId=$oldestId totalLoaded=${messageIds.value.length}',
    );
    debugLog?.logPageFetch(
      groupId: groupId,
      outcome: 'fetching',
      cursorId: oldestId,
      totalCount: messageIds.value.length,
    );

    try {
      final olderMessages = await fetchAggregatedMessagesForGroup(
        pubkey: pubkey,
        groupId: groupId,
        before: oldestMessage.createdAt,
        beforeMessageId: oldestId,
      );

      // Discard if the widget was disposed OR if groupId/pubkey changed while
      // the fetch was in-flight (requestToken no longer matches the current one).
      if (isDisposed.value || requestToken != requestTokenRef.value) {
        _logger.info(
          'loadOlderMessages groupId=$requestGroupId: discarded (disposed or context changed)',
        );
        debugLog?.logPageFetch(
          groupId: requestGroupId,
          outcome: 'discarded',
          cursorId: oldestId,
        );
        return;
      }

      if (olderMessages.isEmpty) {
        hasMoreMessages.value = false;
        _logger.info('loadOlderMessages groupId=$groupId: no more messages (end of history)');
        debugLog?.logPageFetch(groupId: groupId, outcome: 'end', cursorId: oldestId);
        return;
      }

      final newIds = <String>[];
      for (final msg in olderMessages) {
        // Always refresh the stored payload so that updated deletion/media/
        // content state from an overlapping page overwrites the stale copy.
        messagesById.value[msg.id] = msg;
        // Only track new IDs for prepending; duplicates keep their existing
        // position in the list.
        if (!indexById.value.containsKey(msg.id)) {
          newIds.add(msg.id);
        }
      }

      if (newIds.isNotEmpty) {
        var combined = [...newIds, ...messageIds.value];

        // Sliding-window eviction: keep the list bounded so long sessions do
        // not cause OOM. When the merged list exceeds _kWindowSize we drop the
        // newest entries from the tail. combined = [newIds (older) …
        // messageIds.value (newer)], so trimming the tail discards the
        // most-recent history while keeping the just-loaded older messages.
        // This ensures the pagination cursor always advances: the newly
        // prepended messages remain in the window, so the next page load
        // starts from an older cursor rather than re-fetching the same page.
        if (combined.length > _kWindowSize) {
          final evicted = combined.sublist(_kWindowSize);
          combined = combined.sublist(0, _kWindowSize);
          // Remove evicted payloads from the lookup map to free memory.
          for (final id in evicted) {
            messagesById.value.remove(id);
          }
          _logger.info(
            'loadOlderMessages groupId=$groupId: evicted ${evicted.length} newest messages (window=$_kWindowSize)',
          );
        }

        messageIds.value = combined;
        indexById.value = {
          for (var i = 0; i < combined.length; i++) combined[i]: i,
        };
        // Increment to force a widget rebuild after prepending (see declaration).
        paginationVersion.value++;
        _logger.info(
          'loadOlderMessages groupId=$groupId: prepended ${newIds.length} messages totalLoaded=${combined.length}',
        );
        debugLog?.logPageFetch(
          groupId: groupId,
          outcome: 'prepended',
          cursorId: oldestId,
          newCount: newIds.length,
          totalCount: combined.length,
        );
      } else {
        hasMoreMessages.value = false;
        _logger.info(
          'loadOlderMessages groupId=$groupId: no more messages (${olderMessages.length} fetched were already loaded)',
        );
        debugLog?.logPageFetch(
          groupId: groupId,
          outcome: 'duplicate',
          cursorId: oldestId,
          newCount: 0,
        );
      }
    } catch (e, st) {
      _logger.severe('loadOlderMessages groupId=$groupId: FAILED', e, st);
      if (!isDisposed.value) {
        debugLog?.logPageFetch(
          groupId: groupId,
          outcome: 'error',
          cursorId: oldestId,
          error: e,
          stackTrace: st,
        );
      }
    } finally {
      if (!isDisposed.value && requestToken == requestTokenRef.value) {
        isLoadingOlderMessages.value = false;
      }
    }
  }

  return (
    messageCount: messageIds.value.length,
    getMessage: getMessage,
    getReversedMessageIndex: getReversedMessageIndex,
    getMessageById: getMessageById,
    isLoading: isLoading,
    isLoadingOlderMessages: isLoadingOlderMessages.value,
    hasMoreMessages: hasMoreMessages.value,
    loadOlderMessages: loadOlderMessages,
    latestMessageId: snapshot.data?.latestMessageId,
    latestMessagePubkey: snapshot.data?.latestMessagePubkey,
    getChatMessageQuote: getChatMessageQuote,
    getAuthorMetadata: getAuthorMetadata,
  );
}
