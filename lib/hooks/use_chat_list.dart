import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_blocked_pubkeys.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/chat_summary.dart';

final _logger = Logger('useChatList');

typedef ChatListResult = ({
  bool isLoading,
  List<ChatSummary> chats,
  Set<String> blockedPubkeys,
  VoidCallback refresh,
});

ChatListResult useChatList(String pubkey, {bool archived = false}) {
  final blockedPubkeysRefreshKey = useState(0);
  final blockedState = useBlockedPubkeys(pubkey, refreshKey: blockedPubkeysRefreshKey.value);
  return _useChatList(
    pubkey,
    archived: archived,
    blockedState: blockedState,
    refreshBlockedPubkeys: () => blockedPubkeysRefreshKey.value++,
  );
}

ChatListResult useChatListWithBlockedPubkeys(
  String pubkey, {
  bool archived = false,
  required BlockedPubkeysState blockedState,
}) {
  final refreshBlockedPubkeysRef = useRef<VoidCallback>(() {});
  refreshBlockedPubkeysRef.value = blockedState.refresh;

  return _useChatList(
    pubkey,
    archived: archived,
    blockedState: blockedState,
    refreshBlockedPubkeys: () => refreshBlockedPubkeysRef.value(),
  );
}

ChatListResult _useChatList(
  String pubkey, {
  required bool archived,
  required BlockedPubkeysState blockedState,
  required VoidCallback refreshBlockedPubkeys,
}) {
  final chatMap = useRef(<String, ChatSummary>{});
  final refreshKey = useState(0);
  final blockedPubkeysRef = useRef<Set<String>>({});
  blockedPubkeysRef.value = blockedState.blockedPubkeys;

  final stream = useMemoized(
    () {
      final subscribe = archived ? subscribeToArchivedChatList : subscribeToChatList;
      return subscribe(accountPubkey: pubkey)
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
                  'trigger=${update.trigger.name}',
                );
                switch (update.trigger) {
                  case ChatListUpdateTrigger.lastMessageDeleted:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.newGroup:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.newLastMessage:
                    final lastMessage = update.item.lastMessage;
                    if (lastMessage != null &&
                        blockedPubkeysRef.value.contains(lastMessage.author)) {
                      return chatMap.value;
                    }
                    if (update.item.pendingConfirmation) {
                      chatMap.value[id] = update.item;
                    } else {
                      chatMap.value.remove(id);
                      chatMap.value[id] = update.item;
                    }
                  case ChatListUpdateTrigger.chatArchiveChanged:
                    chatMap.value.remove(id);
                    final addToArchivedList = archived && update.item.archivedAt != null;
                    final addToUnarchivedList = !archived && update.item.archivedAt == null;
                    if (addToArchivedList || addToUnarchivedList) {
                      chatMap.value[id] = update.item;
                    }
                  case ChatListUpdateTrigger.removedFromGroup:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.chatMuteChanged:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.leftGroup:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.chatCleared:
                    chatMap.value[id] = update.item;
                  case ChatListUpdateTrigger.chatDeleted:
                    chatMap.value.remove(id);
                  case ChatListUpdateTrigger.userBlockChanged:
                    chatMap.value[id] = update.item;
                    refreshBlockedPubkeys();
                }
                return chatMap.value;
              },
            );
          });
    },
    [pubkey, refreshKey.value, archived],
  );

  final snapshot = useStream(stream, initialData: <String, ChatSummary>{});
  final isLoading = snapshot.connectionState == ConnectionState.waiting || blockedState.isLoading;
  final chats = blockedState.isLoading
      ? <ChatSummary>[]
      : chatMap.value.values
            .where((chat) => !_shouldHideChatSummary(chat, blockedState.blockedPubkeys))
            .map((chat) => _sanitizeChatSummary(chat, blockedState.blockedPubkeys))
            .toList()
            .reversed
            .toList();
  return (
    isLoading: isLoading,
    chats: chats,
    blockedPubkeys: blockedState.blockedPubkeys,
    refresh: () {
      refreshKey.value++;
      refreshBlockedPubkeys();
    },
  );
}

bool _shouldHideChatSummary(ChatSummary chat, Set<String> blockedPubkeys) {
  if (!chat.pendingConfirmation) return false;
  final inviterPubkey = chat.welcomerPubkey ?? chat.dmPeerPubkey;
  return inviterPubkey != null && blockedPubkeys.contains(inviterPubkey);
}

ChatSummary _sanitizeChatSummary(ChatSummary chat, Set<String> blockedPubkeys) {
  final lastMessage = chat.lastMessage;
  if (lastMessage == null || !blockedPubkeys.contains(lastMessage.author)) return chat;
  return ChatSummary(
    mlsGroupId: chat.mlsGroupId,
    name: chat.name,
    groupType: chat.groupType,
    createdAt: chat.createdAt,
    groupImagePath: chat.groupImagePath,
    groupImageUrl: chat.groupImageUrl,
    pendingConfirmation: chat.pendingConfirmation,
    welcomerPubkey: chat.welcomerPubkey,
    archivedAt: chat.archivedAt,
    removedAt: chat.removedAt,
    selfRemoved: chat.selfRemoved,
    unreadCount: chat.unreadCount,
    pinOrder: chat.pinOrder,
    dmPeerPubkey: chat.dmPeerPubkey,
    mutedUntil: chat.mutedUntil,
  );
}
