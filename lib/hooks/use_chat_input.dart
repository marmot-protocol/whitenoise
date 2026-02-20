import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/drafts.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

typedef ChatInputState = ({
  TextEditingController controller,
  FocusNode focusNode,
  bool hasFocus,
  bool hasContent,
  VoidCallback clear,
  ChatMessage? replyingTo,
  void Function(ChatMessage message) setReplyingTo,
  VoidCallback cancelReply,
});

ChatInputState useChatInput({
  required String pubkey,
  required String groupId,
  required ChatMessage? Function(String messageId) findMessage,
}) {
  final controller = useTextEditingController();
  final focusNode = useFocusNode();
  final hasContent = useListenableSelector(controller, () => controller.text.isNotEmpty);
  final hasFocus = useListenableSelector(focusNode, () => focusNode.hasFocus);
  final replyingTo = useState<ChatMessage?>(null);
  final debounceTimer = useRef<Timer?>(null);

  useEffect(
    () {
      var active = true;
      loadDraft(pubkey: pubkey, groupId: groupId).then((draft) {
        if (!active || draft == null) return;
        controller.text = draft.content;
        if (draft.replyToId != null) {
          final message = findMessage(draft.replyToId!);
          if (message != null) replyingTo.value = message;
        }
      });
      return () => active = false;
    },
    [pubkey, groupId],
  );

  useEffect(
    () {
      void scheduleDraft() {
        debounceTimer.value?.cancel();
        final content = controller.text;
        final replyToId = replyingTo.value?.id;
        debounceTimer.value = Timer(const Duration(milliseconds: 500), () {
          if (content.isEmpty && replyToId == null) {
            deleteDraft(pubkey: pubkey, groupId: groupId);
          } else {
            saveDraft(
              pubkey: pubkey,
              groupId: groupId,
              content: content,
              replyToId: replyToId,
              mediaAttachments: [],
            );
          }
        });
      }

      controller.addListener(scheduleDraft);
      replyingTo.addListener(scheduleDraft);
      return () {
        controller.removeListener(scheduleDraft);
        replyingTo.removeListener(scheduleDraft);
        debounceTimer.value?.cancel();
      };
    },
    [controller, replyingTo, pubkey, groupId],
  );

  void setReplyingTo(ChatMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  void clear() {
    controller.clear();
    replyingTo.value = null;
    debounceTimer.value?.cancel();
    debounceTimer.value = null;
    deleteDraft(pubkey: pubkey, groupId: groupId);
  }

  return (
    controller: controller,
    focusNode: focusNode,
    hasFocus: hasFocus,
    hasContent: hasContent,
    clear: clear,
    replyingTo: replyingTo.value,
    setReplyingTo: setReplyingTo,
    cancelReply: cancelReply,
  );
}
