import 'dart:math' as math;

import 'package:scroll_to_index/scroll_to_index.dart';

const maxScrollDuration = Duration(milliseconds: 500);
const _minScrollDuration = Duration(milliseconds: 50);
const _estimatedItemHeight = 80.0;

Duration scrollDuration(AutoScrollController controller, int targetIndex) {
  if (!controller.hasClients) return maxScrollDuration;

  final viewportHeight = controller.position.viewportDimension;
  final itemsPerViewport = math.max(1.0, viewportHeight / _estimatedItemHeight);

  final currentOffset = controller.position.pixels;
  final currentIndex = currentOffset / _estimatedItemHeight;
  final indexDistance = (targetIndex - currentIndex).abs();

  if (indexDistance <= itemsPerViewport) return _minScrollDuration;

  final viewportsAway = indexDistance / itemsPerViewport;
  final t = math.min(1.0, viewportsAway / 10.0);
  final ms =
      _minScrollDuration.inMilliseconds +
      ((maxScrollDuration.inMilliseconds - _minScrollDuration.inMilliseconds) * t).round();
  return Duration(milliseconds: ms);
}
