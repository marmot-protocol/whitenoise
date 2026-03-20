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
  String? latestMessageId,
  String? latestMessagePubkey,
  ChatMessageQuoteData? Function(String? replyId) getChatMessageQuote,
  FlutterMetadata? Function(String pubkey) getAuthorMetadata,
});

ChatMessagesResult useChatMessages(
  String groupId, {
  MessageDebugLogNotifier? debugLog,
}) {
  final messageIds = useRef<List<String>>([]);
  final messagesById = useRef<Map<String, ChatMessage>>({});
  final indexById = useRef<Map<String, int>>({});
  final authorsMetadataByPubkey = useState<Map<String, FlutterMetadata>>({});
  final metadataSubscriptionsByPubkey = useRef<Map<String, StreamSubscription<FlutterMetadata>>>(
    {},
  );

  final stream = useMemoized(
    () {
      _logger.info(
        'stream CREATING groupId=$groupId calling subscribeToGroupMessages',
      );
      Future.microtask(() => debugLog?.logStreamConnected(groupId: groupId));

      return subscribeToGroupMessages(groupId: groupId)
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
    [groupId],
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
  }, [groupId]);

  return (
    messageCount: snapshot.data?.messageCount ?? 0,
    getMessage: getMessage,
    getReversedMessageIndex: getReversedMessageIndex,
    getMessageById: getMessageById,
    isLoading: isLoading,
    latestMessageId: snapshot.data?.latestMessageId,
    latestMessagePubkey: snapshot.data?.latestMessagePubkey,
    getChatMessageQuote: getChatMessageQuote,
    getAuthorMetadata: getAuthorMetadata,
  );
}
