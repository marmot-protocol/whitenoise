import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/drafts.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

final _logger = Logger('useChatInput');

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
      _logger.info('loadDraft groupId=$groupId');
      loadDraft(pubkey: pubkey, groupId: groupId)
          .then((draft) {
            if (!active) return;
            if (draft == null) {
              _logger.info('loadDraft no draft found groupId=$groupId');
              return;
            }
            _logger.info(
              'loadDraft loaded groupId=$groupId contentLen=${draft.content.length} '
              'hasReplyTo=${draft.replyToId != null}',
            );
            controller.text = draft.content;
            if (draft.replyToId != null) {
              final message = findMessage(draft.replyToId!);
              if (message != null) {
                replyingTo.value = message;
              } else {
                _logger.warning(
                  'loadDraft replyToId=${draft.replyToId} not found in messages, ignoring',
                );
              }
            }
          })
          .catchError((Object e, StackTrace st) {
            _logger.severe('loadDraft FAILED groupId=$groupId', e, st);
            return null;
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
            _logger.fine('deleteDraft groupId=$groupId');
            unawaited(
              deleteDraft(pubkey: pubkey, groupId: groupId).then((_) {}).catchError(
                (Object e, StackTrace st) {
                  _logger.severe('deleteDraft FAILED groupId=$groupId', e, st);
                },
              ),
            );
          } else {
            _logger.fine('saveDraft groupId=$groupId contentLen=${content.length}');
            unawaited(
              saveDraft(
                pubkey: pubkey,
                groupId: groupId,
                content: content,
                replyToId: replyToId,
                mediaAttachments: [],
              ).then((_) {}).catchError((Object e, StackTrace st) {
                _logger.severe('saveDraft FAILED groupId=$groupId', e, st);
              }),
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
    focusNode.requestFocus();
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  void clear() {
    controller.clear();
    replyingTo.value = null;
    debounceTimer.value?.cancel();
    debounceTimer.value = null;
    _logger.fine('deleteDraft on clear groupId=$groupId');
    unawaited(
      deleteDraft(pubkey: pubkey, groupId: groupId).then((_) {}).catchError(
        (Object e, StackTrace st) {
          _logger.severe('deleteDraft on clear FAILED groupId=$groupId', e, st);
        },
      ),
    );
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
