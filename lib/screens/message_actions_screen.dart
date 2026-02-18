import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_emoji_picker.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class MessageActionsScreen extends HookWidget {
  const MessageActionsScreen({
    super.key,
    required this.message,
    required this.pubkey,
    required this.onAddReaction,
    required this.onRemoveReaction,
    this.onDelete,
    this.onReply,
  });

  final ChatMessage message;
  final String pubkey;
  final Future<void> Function(String emoji) onAddReaction;
  final Future<void> Function(String reactionId) onRemoveReaction;
  final Future<void> Function()? onDelete;
  final void Function(ChatMessage message)? onReply;

  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    required String pubkey,
    required Future<void> Function(String emoji) onAddReaction,
    required Future<void> Function(String reactionId) onRemoveReaction,
    Future<void> Function()? onDelete,
    void Function(ChatMessage message)? onReply,
  }) {
    final colors = context.colors;

    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: colors.backgroundPrimary.withValues(alpha: 0.8),
        pageBuilder: (menuContext, _, _) {
          return MessageActionsScreen(
            message: message,
            pubkey: pubkey,
            onAddReaction: onAddReaction,
            onRemoveReaction: onRemoveReaction,
            onDelete: onDelete,
            onReply: onReply,
          );
        },
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showEmojiPicker = useState(false);
    final noticeMessage = useState<String?>(null);

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    final isOwnMessage = message.pubkey == pubkey;
    final userReactionIds = Map.fromEntries(
      message.reactions.userReactions
          .where((r) => r.user == pubkey)
          .map((r) => MapEntry(r.emoji, r.reactionId)),
    );
    final selectedEmojis = userReactionIds.keys.toSet();

    Future<void> handleDelete() async {
      try {
        await onDelete?.call();
        if (context.mounted) Navigator.of(context).pop();
      } catch (_) {
        if (context.mounted) {
          showNotice(context.l10n.failedToDeleteMessage);
        }
      }
    }

    Future<void> handleReaction(String emoji) async {
      final reactionId = userReactionIds[emoji];
      try {
        if (reactionId != null) {
          await onRemoveReaction(reactionId);
        } else {
          await onAddReaction(emoji);
        }
        if (context.mounted) Navigator.of(context).pop();
      } catch (_) {
        if (context.mounted) {
          showNotice(
            reactionId != null
                ? context.l10n.failedToRemoveReaction
                : context.l10n.failedToSendReaction,
          );
        }
      }
    }

    return SafeArea(
      child: Column(
        children: [
          if (noticeMessage.value != null)
            WnSystemNotice(
              key: ValueKey(noticeMessage.value),
              title: noticeMessage.value!,
              type: WnSystemNoticeType.error,
              onDismiss: dismissNotice,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                mainAxisAlignment: showEmojiPicker.value
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.center,
                children: [
                  MessageActionsModal(
                    message: message,
                    isOwnMessage: isOwnMessage,
                    onClose: () => Navigator.of(context).pop(),
                    currentUserPubkey: pubkey,
                    onDelete: (isOwnMessage && onDelete != null) ? handleDelete : null,
                    onReaction: handleReaction,
                    onEmojiPicker: () => showEmojiPicker.value = !showEmojiPicker.value,
                    selectedEmojis: selectedEmojis,
                    onReply: onReply != null
                        ? () {
                            onReply!(message);
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (showEmojiPicker.value)
            WnEmojiPicker(
              onClose: () => showEmojiPicker.value = false,
              onEmojiSelected: handleReaction,
            ),
        ],
      ),
    );
  }
}

class MessageActionsModal extends StatelessWidget {
  const MessageActionsModal({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.onClose,
    required this.onReaction,
    required this.onEmojiPicker,
    required this.currentUserPubkey,
    this.onDelete,
    this.selectedEmojis = const {},
    this.onReply,
  });

  final ChatMessage message;
  final bool isOwnMessage;
  final VoidCallback onClose;
  final void Function(String emoji) onReaction;
  final VoidCallback onEmojiPicker;
  final String currentUserPubkey;
  final VoidCallback? onDelete;
  final Set<String> selectedEmojis;
  final VoidCallback? onReply;

  static const List<String> reactions = [
    '❤',
    '👍',
    '👎',
    '😂',
    '🚀',
    '😢',
    '🔥',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return WnSlate(
      header: WnSlateNavigationHeader(
        title: context.l10n.messageActions,
        onNavigate: onClose,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),
            WnMessageBubble(
              message: message,
              isOwnMessage: isOwnMessage,
              currentUserPubkey: currentUserPubkey,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...reactions.map(
                  (emoji) => _ReactionButton(
                    key: Key('reaction_$emoji'),
                    colors: colors,
                    emoji: emoji,
                    isSelected: selectedEmojis.contains(emoji),
                    onTap: () => onReaction(emoji),
                  ),
                ),
                GestureDetector(
                  key: const Key('emoji_picker_button'),
                  onTap: onEmojiPicker,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: WnIcon(
                      WnIcons.addEmoji,
                      color: colors.backgroundContentPrimary,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (onReply != null)
              WnButton(
                key: const Key('reply_button'),
                text: context.l10n.reply,
                type: WnButtonType.outline,
                size: WnButtonSize.medium,
                trailingIcon: WnIcons.reply,
                onPressed: onReply,
              ),
            Gap(8.h),
            WnButton(
              key: const Key('copy_button'),
              text: context.l10n.copyMessage,
              type: WnButtonType.outline,
              size: WnButtonSize.medium,
              trailingIcon: WnIcons.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.of(context).pop();
              },
            ),
            if (onDelete != null) ...[
              Gap(8.h),
              WnButton(
                key: const Key('delete_button'),
                text: context.l10n.delete,
                type: WnButtonType.destructive,
                size: WnButtonSize.medium,
                trailingIcon: WnIcons.trashCan,
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    super.key,
    required this.colors,
    required this.emoji,
    required this.onTap,
    this.isSelected = false,
  });

  final SemanticColors colors;
  final String emoji;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: isSelected
            ? BoxDecoration(
                color: colors.fillTertiaryActive,
                borderRadius: BorderRadius.circular(8.r),
              )
            : null,
        child: Text(
          emoji,
          style: context.typographyScaled.medium20,
        ),
      ),
    );
  }
}
