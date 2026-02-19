import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';

typedef ChatListResult = ({
  bool isLoading,
  List<ChatSummary> chats,
  VoidCallback refresh,
});

ChatListResult useChatList(String pubkey) {
  final chatMap = useRef(<String, ChatSummary>{});
  final refreshKey = useState(0);

  final stream = useMemoized(
    () => subscribeToChatList(accountPubkey: pubkey).map((item) {
      return item.when(
        initialSnapshot: (items) {
          chatMap.value = {for (final c in items.reversed) c.mlsGroupId: c};
          return chatMap.value;
        },
        update: (update) {
          final id = update.item.mlsGroupId;
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
