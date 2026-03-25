import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/bubble_grouping.dart' show shouldShowAvatar;
import 'package:whitenoise/widgets/chat_message_bubble.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_emoji_picker.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

const _modalViewportVerticalInset = 96.0;
const _modalPreviewTopPadding = 10.0;
const _modalPreviewBottomPadding = 12.0;
const _modalSenderRowHeight = 20.0;
const _modalSenderGap = 8.0;
const _modalReplyRowHeight = 56.0;
const _modalMediaHeight = 96.0;
const _modalReactionsHeight = 36.0;
const _modalSectionSpacing = 16.0;
const _modalButtonSpacing = 8.0;
const _modalContentHorizontalPadding = 14.0;
const _modalContentVerticalPadding = 14.0;
const _modalPreviewSafetyReserve = 12.0;
const _modalMinPreviewHeight = 1.0;
const _emojiPickerReservedHeight = 320.0;
const _modalToPickerGap = 8.0;

double _modalMessageLineHeight(BuildContext context, Color textColor) {
  final style = context.typographyScaled.medium16Compact.copyWith(color: textColor);
  final tp = TextPainter(
    text: TextSpan(text: ' ', style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  );
  try {
    tp.layout();
    return tp.preferredLineHeight;
  } finally {
    tp.dispose();
  }
}

int _modalPreviewContentMaxLines(
  BuildContext context, {
  required double slotHeight,
  required bool isOwnMessage,
  required bool showAvatar,
  required String? senderName,
  required bool hasReplyPreview,
  required bool hasBubbleMedia,
  required bool hasBubbleReactions,
}) {
  var textBudget =
      slotHeight -
      _modalPreviewTopPadding.h -
      _modalPreviewBottomPadding.h -
      _modalPreviewSafetyReserve.h;
  final hasSender = !isOwnMessage && showAvatar && senderName != null && senderName.isNotEmpty;
  if (hasSender) {
    textBudget -= _modalSenderRowHeight.h + _modalSenderGap.h;
  }
  if (hasReplyPreview) {
    textBudget -= _modalSenderGap.h + _modalReplyRowHeight.h;
  }
  if (hasBubbleMedia) {
    textBudget -= _modalSenderGap.h + _modalMediaHeight.h;
  }
  if (hasBubbleReactions) {
    textBudget -= _modalSenderGap.h + _modalReactionsHeight.h;
  }
  final colors = context.colors;
  final textColor = isOwnMessage ? colors.fillContentPrimary : colors.backgroundContentPrimary;
  final lh = math.max(_modalMessageLineHeight(context, textColor), 1.0);
  return math.max(1, (textBudget / lh).floor());
}

class MessageActionsScreen extends HookWidget {
  const MessageActionsScreen({
    super.key,
    required this.message,
    required this.pubkey,
    required this.onAddReaction,
    required this.onRemoveReaction,
    this.onDelete,
    this.onReply,
    this.senderName,
    this.senderPictureUrl,
    this.isGroupChat = false,
    this.isOffline = false,
    this.getChatMessageQuote,
  });

  final ChatMessage message;
  final String pubkey;
  final Future<void> Function(String emoji) onAddReaction;
  final Future<void> Function(String reactionId) onRemoveReaction;
  final Future<void> Function()? onDelete;
  final void Function(ChatMessage message)? onReply;
  final String? senderName;
  final String? senderPictureUrl;
  final bool isGroupChat;
  final bool isOffline;
  final ChatMessageQuoteData? Function(String? replyId)? getChatMessageQuote;

  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    required String pubkey,
    required Future<void> Function(String emoji) onAddReaction,
    required Future<void> Function(String reactionId) onRemoveReaction,
    Future<void> Function()? onDelete,
    void Function(ChatMessage message)? onReply,
    String? senderName,
    String? senderPictureUrl,
    bool isGroupChat = false,
    bool isOffline = false,
    ChatMessageQuoteData? Function(String? replyId)? getChatMessageQuote,
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
            senderName: senderName,
            senderPictureUrl: senderPictureUrl,
            isGroupChat: isGroupChat,
            isOffline: isOffline,
            getChatMessageQuote: getChatMessageQuote,
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
                    currentUserPubkey: pubkey,
                    onDelete: (isOwnMessage && onDelete != null && !isOffline)
                        ? handleDelete
                        : null,
                    onReaction: isOffline ? null : handleReaction,
                    onEmojiPicker: isOffline
                        ? null
                        : () => showEmojiPicker.value = !showEmojiPicker.value,
                    selectedEmojis: selectedEmojis,
                    onReply: onReply != null
                        ? () {
                            Navigator.of(context).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              onReply!(message);
                            });
                          }
                        : null,
                    senderName: senderName,
                    senderPictureUrl: senderPictureUrl,
                    isGroupChat: isGroupChat,
                    getChatMessageQuote: getChatMessageQuote,
                    bottomInset: showEmojiPicker.value
                        ? _emojiPickerReservedHeight.h + _modalToPickerGap.h
                        : 0,
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
    required this.currentUserPubkey,
    this.onReaction,
    this.onEmojiPicker,
    this.onDelete,
    this.selectedEmojis = const {},
    this.onReply,
    this.senderName,
    this.senderPictureUrl,
    this.isGroupChat = false,
    this.getChatMessageQuote,
    this.bottomInset = 0,
  });

  final ChatMessage message;
  final bool isOwnMessage;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onEmojiPicker;
  final String currentUserPubkey;
  final VoidCallback? onDelete;
  final Set<String> selectedEmojis;
  final VoidCallback? onReply;
  final String? senderName;
  final String? senderPictureUrl;
  final bool isGroupChat;
  final ChatMessageQuoteData? Function(String? replyId)? getChatMessageQuote;
  final double bottomInset;

  static const List<String> reactions = [
    '❤',
    '😀',
    '👍',
    '👎',
    '🤣',
    '🔥',
    '🦥',
  ];

  double _controlsEstimatedHeight() {
    var height = _modalSectionSpacing.h + 52.h;
    if (onReaction != null) {
      height += 40.h + _modalSectionSpacing.h;
    }
    if (onReply != null) {
      height += _modalButtonSpacing.h + 52.h;
    }
    if (onDelete != null) {
      height += _modalButtonSpacing.h + 52.h;
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final replyPreview = message.isReply ? getChatMessageQuote?.call(message.replyToId) : null;
    final maxSlateHeight = math.max(
      0.0,
      MediaQuery.sizeOf(context).height - (2 * _modalViewportVerticalInset.h) - bottomInset,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSlateHeight),
      child: LayoutBuilder(
        builder: (context, slateConstraints) {
          return WnSlate(
            shrinkWrapContent: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: slateConstraints.maxWidth,
                maxHeight: math.max(0.0, slateConstraints.maxHeight - 2),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _modalContentHorizontalPadding.w,
                  _modalContentVerticalPadding.h,
                  _modalContentHorizontalPadding.w,
                  _modalContentVerticalPadding.h,
                ),
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final showAvatar = shouldShowAvatar(
                      current: message,
                      next: null,
                      isOwnMessage: isOwnMessage,
                      isGroupChat: isGroupChat,
                    );
                    final previewMaxHeight = math.max(
                      0.0,
                      innerConstraints.maxHeight - _controlsEstimatedHeight(),
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (previewMaxHeight >= _modalMinPreviewHeight.h)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: previewMaxHeight),
                            child: LayoutBuilder(
                              builder: (context, slotConstraints) {
                                final maxLines = _modalPreviewContentMaxLines(
                                  context,
                                  slotHeight: slotConstraints.maxHeight,
                                  isOwnMessage: isOwnMessage,
                                  showAvatar: showAvatar,
                                  senderName: senderName,
                                  hasReplyPreview: replyPreview != null,
                                  hasBubbleMedia: message.mediaAttachments.isNotEmpty,
                                  hasBubbleReactions: message.reactions.byEmoji.isNotEmpty,
                                );
                                final shouldConstrainPreviewLines =
                                    message.content.runes.length > 32 ||
                                    message.content.contains('\n') ||
                                    replyPreview != null ||
                                    message.mediaAttachments.isNotEmpty ||
                                    message.reactions.byEmoji.isNotEmpty;
                                return Align(
                                  alignment: isOwnMessage ? Alignment.topRight : Alignment.topLeft,
                                  heightFactor: 1,
                                  child: ChatMessageBubble(
                                    message: message,
                                    isOwnMessage: isOwnMessage,
                                    currentUserPubkey: currentUserPubkey,
                                    showAvatar: showAvatar,
                                    senderName: senderName,
                                    senderPictureUrl: senderPictureUrl,
                                    isGroupChat: isGroupChat,
                                    replyPreview: replyPreview,
                                    contentMaxLines: shouldConstrainPreviewLines ? maxLines : null,
                                    bubbleWidthFactor: 0.865,
                                    forceTightHeight: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        if (onReaction != null) ...[
                          SizedBox(height: _modalSectionSpacing.h),
                          Row(
                            children: [
                              ...reactions.map(
                                (emoji) => Expanded(
                                  child: _ReactionButton(
                                    key: Key('reaction_$emoji'),
                                    colors: colors,
                                    emoji: emoji,
                                    isSelected: selectedEmojis.contains(emoji),
                                    onTap: () => onReaction!(emoji),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  key: const Key('emoji_picker_button'),
                                  onTap: onEmojiPicker,
                                  child: Center(
                                    child: WnIcon(
                                      WnIcons.addEmoji,
                                      color: colors.backgroundContentPrimary,
                                      size: 20.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: _modalSectionSpacing.h),
                        if (onReply != null) ...[
                          WnButton(
                            key: const Key('reply_button'),
                            text: context.l10n.reply,
                            type: WnButtonType.outline,
                            size: WnButtonSize.medium,
                            trailingIcon: WnIcons.reply,
                            onPressed: onReply,
                          ),
                          Gap(_modalButtonSpacing.h),
                        ],
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
                          Gap(_modalButtonSpacing.h),
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
                    );
                  },
                ),
              ),
            ),
          );
        },
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
      child: Center(
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
      ),
    );
  }
}
