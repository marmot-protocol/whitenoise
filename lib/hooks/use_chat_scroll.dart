import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/hooks/use_mark_as_read.dart';

const _bottomThreshold = 50.0;
const _topThreshold = 200.0;

typedef ChatScrollResult = ({
  bool isInitialPositionReady,
  bool isScrollDownButtonVisible,
  void Function() scrollToBottom,
});

ChatScrollResult useChatScroll({
  required AutoScrollController scrollController,
  required FocusNode focusNode,
  required String? latestMessageId,
  required String? latestMessagePubkey,
  required String accountPubkey,
  required String groupId,
  required int messageCount,
  required String? Function(int reversedIndex) getMessageId,
  required int? Function(String messageId) getReversedIndex,
  required bool hasMoreMessages,
  required Future<void> Function() loadOlderMessages,
}) {
  final (
    :firstUnreadIndex,
    :hasLoadedLastRead,
    :lastReadMessageFound,
    :markMessageAsRead,
  ) = useMarkAsRead(
    accountPubkey: accountPubkey,
    groupId: groupId,
    messageCount: messageCount,
    getReversedIndex: getReversedIndex,
  );

  final isAtBottom = useState(true);
  final hasUnseenMessages = useState(false);
  final isInitialPositionReady = useState(false);
  final prevLatestMessageId = useRef<String?>(null);
  final shouldStayAtBottom = useRef(false);
  final hasScrolledToUnread = useRef(false);
  final debounceTimer = useRef<Timer?>(null);
  final hasUserScrolled = useRef(false);

  final messageCountRef = useRef(messageCount);
  final getMessageIdRef = useRef(getMessageId);
  messageCountRef.value = messageCount;
  getMessageIdRef.value = getMessageId;

  final isMounted = useRef(true);
  useEffect(() {
    isMounted.value = true;
    return () {
      isMounted.value = false;
    };
  }, []);

  void autoScrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void jumpToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  useEffect(() {
    if (latestMessageId == null) return null;

    final isOwnMessage = latestMessagePubkey == accountPubkey;
    final atBottom =
        scrollController.hasClients && scrollController.position.pixels <= _bottomThreshold;

    if (isOwnMessage || atBottom) {
      markMessageAsRead(latestMessageId);
    }
    return null;
  }, [latestMessageId, latestMessagePubkey]);

  useEffect(() {
    void markVisibleMessagesAsRead() {
      if (!scrollController.hasClients) return;
      if (!hasUserScrolled.value) return;
      if (messageCountRef.value == 0) return;

      final position = scrollController.position;

      final int indexToMark;
      if (position.pixels <= _bottomThreshold) {
        indexToMark = 0;
      } else {
        final lowestVisible = _getLowestVisibleIndex(scrollController);
        if (lowestVisible == null) return;
        indexToMark = lowestVisible;
      }

      final messageIdToMark = getMessageIdRef.value(indexToMark);
      if (messageIdToMark == null) return;

      markMessageAsRead(messageIdToMark);
    }

    void onScrollUpdate() {
      if (!scrollController.hasClients) return;
      final position = scrollController.position;
      final atBottom = position.pixels <= _bottomThreshold;

      if (isAtBottom.value != atBottom) {
        isAtBottom.value = atBottom;
      }

      if (atBottom && hasUnseenMessages.value) {
        hasUnseenMessages.value = false;
      }
      hasUserScrolled.value = true;

      final atTop =
          position.maxScrollExtent > _topThreshold &&
          position.pixels >= position.maxScrollExtent - _topThreshold;
      if (atTop && hasMoreMessages) {
        unawaited(loadOlderMessages());
      }

      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(
        const Duration(milliseconds: 300),
        markVisibleMessagesAsRead,
      );
    }

    scrollController.addListener(onScrollUpdate);

    return () {
      scrollController.removeListener(onScrollUpdate);
      debounceTimer.value?.cancel();
    };
    // hasMoreMessages and loadOlderMessages are intentionally omitted from deps.
    // loadOlderMessages guards internally against hasMoreMessages and isLoadingOlderMessages,
    // so a stale closure here cannot cause a runaway fetch loop.
  }, [scrollController, firstUnreadIndex]);

  useEffect(() {
    void onFocusChange() {
      if (focusNode.hasFocus) {
        shouldStayAtBottom.value = true;
        autoScrollToBottom();
      } else {
        shouldStayAtBottom.value = false;
      }
    }

    focusNode.addListener(onFocusChange);
    return () => focusNode.removeListener(onFocusChange);
  }, [focusNode]);

  final observer = useMemoized(
    () => _KeyboardObserver(() {
      if (shouldStayAtBottom.value || isAtBottom.value) {
        jumpToBottom();
      }
    }),
    [],
  );

  useEffect(() {
    WidgetsBinding.instance.addObserver(observer);
    return () => WidgetsBinding.instance.removeObserver(observer);
  }, [observer]);

  final isLatestMessageOwn = latestMessagePubkey == accountPubkey;

  useEffect(() {
    if (!isInitialPositionReady.value) return null;
    if (latestMessageId == null) return null;

    final atBottom =
        !scrollController.hasClients || scrollController.position.pixels <= _bottomThreshold;
    if (atBottom) {
      markMessageAsRead(latestMessageId);
    }
    return null;
  }, [isInitialPositionReady.value]);

  useEffect(
    () {
      if (isInitialPositionReady.value) return null;
      if (latestMessageId == null) return null;
      if (messageCount > 0 && !hasLoadedLastRead) return null;

      if (!lastReadMessageFound && hasMoreMessages) {
        // Keep the list hidden (isInitialPositionReady = false) and fetch the next page.
        // Once messageCount changes, this effect will re-run until we find the last read message.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isMounted.value) return;
          unawaited(loadOlderMessages());
        });
        return null;
      }

      if (firstUnreadIndex != null && !hasScrolledToUnread.value) {
        hasScrolledToUnread.value = true;
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          if (!isMounted.value) return;
          if (!scrollController.hasClients) return;
          // Use duration: 1ms to jump instantly rather than animating. We don't want a long
          // animation if the unread message is many pages back.
          await scrollController.scrollToIndex(
            firstUnreadIndex,
            preferPosition: AutoScrollPosition.middle,
            duration: const Duration(milliseconds: 1),
          );
          if (!isMounted.value) return;
          isInitialPositionReady.value = true;
        });
      } else {
        isInitialPositionReady.value = true;
      }

      prevLatestMessageId.value = latestMessageId;
      return null;
    },
    [
      latestMessageId,
      firstUnreadIndex,
      hasLoadedLastRead,
      lastReadMessageFound,
      hasMoreMessages,
      isInitialPositionReady.value,
      messageCount,
    ],
  );

  useEffect(() {
    if (!isInitialPositionReady.value) return null;
    if (latestMessageId == null) return null;
    if (latestMessageId == prevLatestMessageId.value) return null;

    if (isAtBottom.value || isLatestMessageOwn) {
      autoScrollToBottom();
    } else {
      hasUnseenMessages.value = true;
    }

    prevLatestMessageId.value = latestMessageId;
    return null;
  }, [latestMessageId, isLatestMessageOwn, isInitialPositionReady.value]);

  final showScrollDown =
      isInitialPositionReady.value &&
      (hasUnseenMessages.value || (!isAtBottom.value && firstUnreadIndex != null));

  return (
    isInitialPositionReady: isInitialPositionReady.value,
    isScrollDownButtonVisible: showScrollDown,
    scrollToBottom: scrollToBottom,
  );
}

class _KeyboardObserver extends WidgetsBindingObserver {
  _KeyboardObserver(this.onMetricsChange);

  final VoidCallback onMetricsChange;

  @override
  void didChangeMetrics() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMetricsChange();
    });
  }
}

int? _getLowestVisibleIndex(AutoScrollController controller) {
  if (!controller.hasClients || controller.tagMap.isEmpty) return null;

  final firstScrollItemContext = controller.tagMap.values.first.context;
  final scrollable = Scrollable.maybeOf(firstScrollItemContext);
  if (scrollable == null) return null;

  final scrollableBox = scrollable.context.findRenderObject() as RenderBox?;
  if (scrollableBox == null || !scrollableBox.attached) return null;

  final viewportGlobal = scrollableBox.localToGlobal(Offset.zero);
  final viewportTop = viewportGlobal.dy;
  final viewportBottom = viewportTop + scrollableBox.size.height;

  int? lowestIndex;

  for (final entry in controller.tagMap.entries) {
    final renderBox = entry.value.context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) continue;

    final itemGlobal = renderBox.localToGlobal(Offset.zero);
    final itemTop = itemGlobal.dy;
    final itemBottom = itemTop + renderBox.size.height;

    final visibleHeight =
        itemBottom.clamp(viewportTop, viewportBottom) - itemTop.clamp(viewportTop, viewportBottom);
    final itemHeight = itemBottom - itemTop;

    if (itemHeight > 0 && visibleHeight >= itemHeight * 0.5) {
      if (lowestIndex == null || entry.key < lowestIndex) {
        lowestIndex = entry.key;
      }
    }
  }

  return lowestIndex;
}
