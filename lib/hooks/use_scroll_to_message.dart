import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/utils/scroll_duration.dart';

final _logger = Logger('useScrollToMessage');

const _maxLoadAttempts = 20;

typedef ScrollToMessageResult = ({
  AutoScrollController scrollController,
  Future<void> Function(String messageId) scrollToMessage,
});

ScrollToMessageResult useScrollToMessage({
  required int? Function(String messageId) getReversedMessageIndex,
  required Future<void> Function() loadOlderMessages,
  required bool hasMoreMessages,
}) {
  final controller = useMemoized(() => AutoScrollController(), []);
  final hasMoreRef = useRef(hasMoreMessages);
  final getIndexRef = useRef(getReversedMessageIndex);
  final loadRef = useRef(loadOlderMessages);

  hasMoreRef.value = hasMoreMessages;
  getIndexRef.value = getReversedMessageIndex;
  loadRef.value = loadOlderMessages;

  useEffect(() => controller.dispose, [controller]);

  Future<void> scrollToMessage(String messageId) async {
    var reversedIndex = getIndexRef.value(messageId);

    var attempts = 0;
    while (reversedIndex == null && hasMoreRef.value && attempts < _maxLoadAttempts) {
      _logger.info(
        'scrollToMessage: message $messageId not in window, loading page ${attempts + 1}',
      );
      await loadRef.value();
      reversedIndex = getIndexRef.value(messageId);
      attempts++;
    }

    if (reversedIndex == null) {
      _logger.warning('scrollToMessage: message $messageId not found after $attempts attempts');
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
