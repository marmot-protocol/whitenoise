import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;

final _logger = Logger('useMarkAsRead');

typedef MarkAsReadResult = ({
  int? firstUnreadIndex,
  bool hasLoadedLastRead,
  bool lastReadMessageFound,
  void Function(String messageId) markMessageAsRead,
});

MarkAsReadResult useMarkAsRead({
  required String accountPubkey,
  required String groupId,
  required int messageCount,
  required int? Function(String messageId) getReversedIndex,
}) {
  final lastReadMessageId = useState<String?>(null);
  final hasLoadedLastRead = useState(false);
  final isDisposed = useRef(false);
  useEffect(() {
    isDisposed.value = false;
    return () => isDisposed.value = true;
  }, const []);

  Future<void> fetchLastReadMessageId() async {
    try {
      final accountGroup = await account_groups_api.getAccountGroup(
        accountPubkey: accountPubkey,
        mlsGroupId: groupId,
      );
      if (isDisposed.value) return;
      lastReadMessageId.value = accountGroup.lastReadMessageId;
    } catch (error) {
      if (isDisposed.value) return;
      _logger.severe('Failed to fetch last read message for group $groupId', error.toString());
    }
    hasLoadedLastRead.value = true;
  }

  useEffect(() {
    fetchLastReadMessageId();
    return null;
  }, [accountPubkey, groupId]);

  final refetchTimer = useRef<Timer?>(null);
  useEffect(() {
    if (hasLoadedLastRead.value) {
      refetchTimer.value?.cancel();
      refetchTimer.value = Timer(const Duration(seconds: 1), fetchLastReadMessageId);
    }
    return null;
  }, [messageCount]);
  useEffect(
    () => () {
      refetchTimer.value?.cancel();
    },
    const [],
  );

  bool isMessageRead(String messageId) {
    if (messageId == lastReadMessageId.value) return true;
    final messageIndex = getReversedIndex(messageId);
    if (messageIndex == null) return true;

    final lastReadIndex = lastReadMessageId.value != null
        ? getReversedIndex(lastReadMessageId.value!)
        : null;

    return lastReadIndex != null && messageIndex >= lastReadIndex;
  }

  void markMessageAsRead(String messageId) {
    if (isMessageRead(messageId)) return;

    account_groups_api
        .markMessageRead(accountPubkey: accountPubkey, messageId: messageId)
        .then((_) {
          if (!isDisposed.value) lastReadMessageId.value = messageId;
        })
        .onError((_, _) {});
  }

  int? computeFirstUnreadIndex() {
    if (!hasLoadedLastRead.value || messageCount == 0) return null;

    final lastReadId = lastReadMessageId.value;
    if (lastReadId == null) return messageCount - 1;

    final lastReadReversedIndex = getReversedIndex(lastReadId);
    if (lastReadReversedIndex == null) return messageCount - 1;

    return lastReadReversedIndex > 0 ? lastReadReversedIndex - 1 : null;
  }

  final lastReadId = lastReadMessageId.value;
  // Require hasLoadedLastRead so consumers don't short-circuit before the
  // async fetch completes: if the load is still in-flight, treat the marker
  // as not-yet-found regardless of the current lastReadId value.
  final lastReadFound =
      hasLoadedLastRead.value && (lastReadId == null || getReversedIndex(lastReadId) != null);

  return (
    firstUnreadIndex: computeFirstUnreadIndex(),
    hasLoadedLastRead: hasLoadedLastRead.value,
    lastReadMessageFound: lastReadFound,
    markMessageAsRead: markMessageAsRead,
  );
}
