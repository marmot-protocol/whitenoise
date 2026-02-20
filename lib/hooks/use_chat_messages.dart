import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';

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

ChatMessagesResult useChatMessages(String groupId) {
  final messageIds = useRef<List<String>>([]);
  final messagesById = useRef<Map<String, ChatMessage>>({});
  final indexById = useRef<Map<String, int>>({});
  final authorsMetadataByPubkey = useState<Map<String, FlutterMetadata>>({});
  final loadingPubkeys = useRef<Set<String>>({});

  final stream = useMemoized(
    () => subscribeToGroupMessages(groupId: groupId).map((item) {
      return item.when(
        initialSnapshot: (initialChatMessages) {
          messageIds.value = [];
          messagesById.value = {};
          indexById.value = {};

          for (var i = 0; i < initialChatMessages.length; i++) {
            final message = initialChatMessages[i];
            messageIds.value.add(message.id);
            messagesById.value[message.id] = message;
            indexById.value[message.id] = i;
          }

          final lastMessage = initialChatMessages.isNotEmpty ? initialChatMessages.last : null;
          return (
            messageCount: initialChatMessages.length,
            latestMessageId: lastMessage?.id,
            latestMessagePubkey: lastMessage?.pubkey,
          );
        },
        update: (update) {
          final message = update.message;

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
    }),
    [groupId],
  );

  final initialData = (
    messageCount: 0,
    latestMessageId: null,
    latestMessagePubkey: null,
  );
  final snapshot = useStream(stream, initialData: initialData);
  final isLoading = snapshot.connectionState == ConnectionState.waiting;

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

  Future<void> fetchAuthorMetadata(String pubkey) async {
    if (authorsMetadataByPubkey.value.containsKey(pubkey)) return;
    if (loadingPubkeys.value.contains(pubkey)) return;

    loadingPubkeys.value.add(pubkey);
    try {
      final metadata = await UserService(pubkey).fetchMetadata();
      authorsMetadataByPubkey.value = {
        ...authorsMetadataByPubkey.value,
        pubkey: metadata,
      };
    } finally {
      loadingPubkeys.value.remove(pubkey);
    }
  }

  FlutterMetadata? getAuthorMetadata(String pubkey) {
    final existingAuthorMetadata = authorsMetadataByPubkey.value[pubkey];
    if (existingAuthorMetadata != null) return existingAuthorMetadata;

    fetchAuthorMetadata(pubkey);
    return null;
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
