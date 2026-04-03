import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/utils/scroll_duration.dart';

final _logger = Logger('useScrollToMessage');

const _defaultPageSize = 50;

typedef ScrollToMessageResult = ({
  AutoScrollController scrollController,
  Future<void> Function(String messageId, {int? position}) scrollToMessage,
});

ScrollToMessageResult useScrollToMessage({
  required int? Function(String messageId) getReversedMessageIndex,
  required Future<void> Function() loadOlderMessages,
  required bool hasMoreMessages,
  required int messageCount,
}) {
  final controller = useMemoized(() => AutoScrollController(), []);
  final hasMoreRef = useRef(hasMoreMessages);
  final getIndexRef = useRef(getReversedMessageIndex);
  final loadRef = useRef(loadOlderMessages);
  final messageCountRef = useRef(messageCount);

  hasMoreRef.value = hasMoreMessages;
  getIndexRef.value = getReversedMessageIndex;
  loadRef.value = loadOlderMessages;
  messageCountRef.value = messageCount;

  useEffect(() => controller.dispose, [controller]);

  Future<void> scrollToMessage(String messageId, {int? position}) async {
    var reversedIndex = getIndexRef.value(messageId);

    if (reversedIndex == null && hasMoreRef.value) {
      final pagesToLoad = position != null ? _pagesToLoad(position, messageCountRef.value) : null;

      if (pagesToLoad != null) {
        _logger.info(
          'scrollToMessage: message $messageId at position $position, '
          'loading $pagesToLoad pages (${messageCountRef.value} messages loaded)',
        );
      }

      var attempts = 0;
      final limit = pagesToLoad ?? double.infinity;
      while (reversedIndex == null && hasMoreRef.value && attempts < limit) {
        if (pagesToLoad == null) {
          _logger.info(
            'scrollToMessage: message $messageId not in window, loading page ${attempts + 1}',
          );
        }
        await loadRef.value();
        reversedIndex = getIndexRef.value(messageId);
        attempts++;
      }
    }

    if (reversedIndex == null) {
      _logger.warning('scrollToMessage: message $messageId not found');
      return;
    }

    await controller.scrollToIndex(
      reversedIndex,
      preferPosition: AutoScrollPosition.middle,
      duration: scrollDuration(controller, reversedIndex),
    );
  }

  return (
    scrollController: controller,
    scrollToMessage: scrollToMessage,
  );
}

int _pagesToLoad(int position, int currentMessageCount) {
  if (position < currentMessageCount) return 0;
  final remaining = position - currentMessageCount + 1;
  return (remaining / _defaultPageSize).ceil();
}
