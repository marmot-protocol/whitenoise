import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';

final _logger = Logger('useChatList');

typedef ChatListResult = ({
  bool isLoading,
  List<ChatSummary> chats,
  VoidCallback refresh,
});

ChatListResult useChatList(String pubkey) {
  final chatMap = useRef(<String, ChatSummary>{});
  final refreshKey = useState(0);

  final stream = useMemoized(
    () => subscribeToChatList(accountPubkey: pubkey)
        .handleError((Object e, StackTrace st) {
          _logger.severe('chatList stream ERROR pubkey=${pubkey.substring(0, 8)}…', e, st);
          throw e;
        })
        .map((item) {
          return item.when(
            initialSnapshot: (items) {
              _logger.info(
                'chatList stream initialSnapshot pubkey=${pubkey.substring(0, 8)}… count=${items.length}',
              );
              chatMap.value = {for (final c in items.reversed) c.mlsGroupId: c};
              return chatMap.value;
            },
            update: (update) {
              final id = update.item.mlsGroupId;
              _logger.info(
                'chatList stream update pubkey=${pubkey.substring(0, 8)}… '
                'trigger=${update.trigger.name} groupId=$id',
              );
              switch (update.trigger) {
                case ChatListUpdateTrigger.lastMessageDeleted:
                  chatMap.value[id] = update.item;
                case ChatListUpdateTrigger.newGroup:
                  chatMap.value[id] = update.item;
                case ChatListUpdateTrigger.newLastMessage:
                  if (update.item.pendingConfirmation) {
                    chatMap.value[id] = update.item;
                  } else {
                    chatMap.value.remove(id);
                    chatMap.value[id] = update.item;
                  }
                case ChatListUpdateTrigger.chatArchiveChanged:
                  if (update.item.archivedAt != null) {
                    chatMap.value.remove(id);
                  } else {
                    chatMap.value.remove(id);
                    chatMap.value[id] = update.item;
                  }
              }
              return chatMap.value;
            },
          );
        }),
    [pubkey, refreshKey.value],
  );

  final snapshot = useStream(stream, initialData: <String, ChatSummary>{});
  final isLoading = snapshot.connectionState == ConnectionState.waiting;
  return (
    isLoading: isLoading,
    chats: chatMap.value.values.toList().reversed.toList(),
    refresh: () => refreshKey.value++,
  );
}
