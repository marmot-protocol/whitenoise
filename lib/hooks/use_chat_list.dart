import 'package:flutter/foundation.dart';
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

class _ChatListCacheEntry {
  Map<String, ChatSummary> chatMap = <String, ChatSummary>{};
  bool hasInitialSnapshot = false;
}

typedef _ChatListCacheKey = ({String pubkey, bool archived});

final Map<_ChatListCacheKey, _ChatListCacheEntry> _chatListCaches = {};

@visibleForTesting
void resetChatListCacheForTests() => _chatListCaches.clear();

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
  final cache = _chatListCaches.putIfAbsent(
    (pubkey: pubkey, archived: archived),
    _ChatListCacheEntry.new,
  );
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
                cache.chatMap = {for (final c in items.reversed) c.mlsGroupId: c};
                cache.hasInitialSnapshot = true;
                return cache.chatMap;
              },
              update: (update) {
                final id = update.item.mlsGroupId;
                _logger.info(
                  'chatList stream update pubkey=${pubkey.substring(0, 8)}… '
                  'trigger=${update.trigger.name}',
                );
                switch (update.trigger) {
                  case ChatListUpdateTrigger.lastMessageDeleted:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.newGroup:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.newLastMessage:
                    final lastMessage = update.item.lastMessage;
                    final blockedPubkeys = blockedPubkeysRef.value;
                    if (lastMessage != null && blockedPubkeys.contains(lastMessage.author)) {
                      cache.chatMap[id] = _sanitizeChatSummary(update.item, blockedPubkeys);
                      return cache.chatMap;
                    }
                    if (update.item.pendingConfirmation) {
                      cache.chatMap[id] = update.item;
                    } else {
                      cache.chatMap.remove(id);
                      cache.chatMap[id] = update.item;
                    }
                  case ChatListUpdateTrigger.chatArchiveChanged:
                    cache.chatMap.remove(id);
                    final addToArchivedList = archived && update.item.archivedAt != null;
                    final addToUnarchivedList = !archived && update.item.archivedAt == null;
                    if (addToArchivedList || addToUnarchivedList) {
                      cache.chatMap[id] = update.item;
                    }
                  case ChatListUpdateTrigger.removedFromGroup:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.chatMuteChanged:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.leftGroup:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.chatCleared:
                    cache.chatMap[id] = update.item;
                  case ChatListUpdateTrigger.chatDeleted:
                    cache.chatMap.remove(id);
                  case ChatListUpdateTrigger.userBlockChanged:
                    cache.chatMap[id] = update.item;
                    refreshBlockedPubkeys();
                }
                return cache.chatMap;
              },
            );
          });
    },
    [pubkey, refreshKey.value, archived],
  );

  useStream(stream, initialData: cache.chatMap);
  final isLoading = !cache.hasInitialSnapshot || blockedState.isLoading;
  final chats = blockedState.isLoading
      ? <ChatSummary>[]
      : cache.chatMap.values
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
