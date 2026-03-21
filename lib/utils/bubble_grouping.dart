import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/widgets/wn_message_bubble.dart' show BubbleLeadingVariant;

BubbleLeadingVariant leadingVariant({
  required bool isOwnMessage,
  required bool showTail,
  required bool isGroupChat,
}) {
  if (isOwnMessage || showTail) return BubbleLeadingVariant.none;
  return isGroupChat ? BubbleLeadingVariant.avatar : BubbleLeadingVariant.tail;
}

bool shouldShowAvatar({
  required ChatMessage current,
  required ChatMessage? next,
  required bool isOwnMessage,
  required bool isGroupChat,
}) {
  if (isOwnMessage) return false;
  if (!isGroupChat) return false;
  if (next == null) return true;
  if (current.isDeleted != next.isDeleted) return true;
  if (next.pubkey != current.pubkey) return true;
  return next.createdAt.difference(current.createdAt).abs().inMinutes >= 5;
}

bool shouldShowTail({
  required ChatMessage current,
  required ChatMessage? next,
}) {
  if (next == null) return true;
  if (current.isDeleted != next.isDeleted) return true;
  if (next.pubkey != current.pubkey) return true;
  return next.createdAt.difference(current.createdAt).abs().inMinutes >= 5;
}
