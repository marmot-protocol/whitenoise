import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnMessageBubbleStory extends StatelessWidget {
  const WnMessageBubbleStory({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const _shortText = 'Hey, are you coming tonight?';
const _longText =
    "What if all the world's inside your head? Just creations of your own. "
    'Your devils and your gods.';
const _replyWidget = _SampleQuote();

final _oneReaction = [
  EmojiReaction(emoji: '👍', count: BigInt.from(3), users: const []),
];
final _threeReactions = [
  EmojiReaction(emoji: '👍', count: BigInt.from(3), users: const []),
  EmojiReaction(emoji: '❤️', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '😂', count: BigInt.from(5), users: const []),
];
final _twelveReactions = [
  EmojiReaction(emoji: '👍', count: BigInt.from(42), users: const []),
  EmojiReaction(emoji: '❤️', count: BigInt.from(17), users: const []),
  EmojiReaction(emoji: '😂', count: BigInt.from(8), users: const []),
  EmojiReaction(emoji: '🔥', count: BigInt.from(5), users: const []),
  EmojiReaction(emoji: '🎉', count: BigInt.from(3), users: const []),
  EmojiReaction(emoji: '😍', count: BigInt.from(2), users: const []),
  EmojiReaction(emoji: '🙏', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '💯', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '🚀', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '👀', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '😎', count: BigInt.one, users: const []),
  EmojiReaction(emoji: '⚡', count: BigInt.one, users: const []),
];

const _samplePictureUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Camponotus_flavomarginatus_ant.jpg/320px-Camponotus_flavomarginatus_ant.jpg';

Widget _sampleAvatar(BuildContext context) => WnAvatar(
  displayName: 'Trent Reznor',
  size: WnAvatarSize.xSmall,
  color: AvatarColor.values[2],
);

Widget _sampleAvatarWithImage(BuildContext context) => WnAvatar(
  pictureUrl: _samplePictureUrl,
  displayName: 'Trent Reznor',
  size: WnAvatarSize.xSmall,
  color: AvatarColor.values[2],
);

@widgetbook.UseCase(name: 'Message Bubble', type: WnMessageBubbleStory)
Widget wnMessageBubbleShowcase(BuildContext context) {
  final colors = context.colors;

  final direction = context.knobs.object.dropdown<MessageDirection>(
    label: 'Direction',
    options: MessageDirection.values,
    initialOption: MessageDirection.incoming,
    labelBuilder: (v) => v.name,
  );

  final text = context.knobs.string(label: 'Content', initialValue: _shortText);

  final showTail = context.knobs.boolean(
    label: 'Show Tail',
    initialValue: true,
  );

  final showAvatar = context.knobs.boolean(
    label: 'Show Avatar',
    initialValue: false,
  );

  final showReply = context.knobs.boolean(
    label: 'Show Reply',
    initialValue: false,
  );

  final reactionsCount = context.knobs.object.dropdown<int>(
    label: 'Reactions',
    options: [0, 1, 3, 12],
    initialOption: 0,
    labelBuilder: (v) => switch (v) {
      0 => 'None',
      1 => 'One',
      3 => 'Three',
      _ => 'Twelve',
    },
  );

  final reactions = switch (reactionsCount) {
    1 => _oneReaction,
    3 => _threeReactions,
    12 => _twelveReactions,
    _ => <EmojiReaction>[],
  };

  final isIncoming = direction == MessageDirection.incoming;
  final avatarColorSet = AvatarColor.values[2].toColorSet(colors);

  return Scaffold(
    backgroundColor: colors.backgroundSecondary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to explore variants.',
          style: TextStyle(
            fontSize: 14,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        WnMessageBubble(
          direction: direction,
          isDeleted: false,
          showTail: showTail,
          content: text.isNotEmpty ? text : null,
          replyContent: showReply ? _replyWidget : null,
          reactions: reactions,
          timestamp: '12:29',
          avatar: isIncoming && showAvatar ? _sampleAvatar(context) : null,
          senderName: isIncoming && showAvatar ? 'Trent Reznor' : null,
          senderNameColor: isIncoming && showAvatar
              ? avatarColorSet.border
              : null,
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        Text(
          'All Variants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Left column: incoming. Right column: outgoing.',
          style: TextStyle(
            fontSize: 13,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _VariantsGrid(colors: colors),
      ],
    ),
  );
}

class _VariantsGrid extends StatelessWidget {
  const _VariantsGrid({required this.colors});

  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _VariantColumn(
            direction: MessageDirection.incoming,
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VariantColumn(
            direction: MessageDirection.outgoing,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _VariantColumn extends StatelessWidget {
  const _VariantColumn({required this.direction, required this.colors});

  final MessageDirection direction;
  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final label = direction == MessageDirection.incoming
        ? 'Incoming'
        : 'Outgoing';
    final isIncoming = direction == MessageDirection.incoming;
    final avatarColorSet = AvatarColor.values[2].toColorSet(colors);

    final mediaPlaceholder = Container(
      height: 80,
      decoration: BoxDecoration(
        color: colors.borderTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '[ image ]',
          style: TextStyle(
            color: colors.backgroundContentTertiary,
            fontSize: 12,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _Variant(
          label: 'Text — with tail',
          direction: direction,
          content: _shortText,
          showTail: true,
        ),
        _Variant(
          label: 'Text — no tail',
          direction: direction,
          content: _shortText,
          showTail: false,
        ),
        _Variant(
          label: 'Long text',
          direction: direction,
          content: _longText,
          showTail: true,
        ),
        if (isIncoming) ...[
          _Variant(
            label: 'Avatar (initials) + name',
            direction: direction,
            content: _shortText,
            showTail: true,
            avatar: _sampleAvatar(context),
            senderName: 'Trent Reznor',
            senderNameColor: avatarColorSet.border,
          ),
          _Variant(
            label: 'Avatar (image) + name',
            direction: direction,
            content: _shortText,
            showTail: true,
            avatar: _sampleAvatarWithImage(context),
            senderName: 'Trent Reznor',
            senderNameColor: avatarColorSet.border,
          ),
          _Variant(
            label: 'Avatar + name + reply',
            direction: direction,
            content: _shortText,
            showTail: true,
            avatar: _sampleAvatar(context),
            senderName: 'Trent Reznor',
            senderNameColor: avatarColorSet.border,
            replyContent: _replyWidget,
          ),
        ],
        _Variant(
          label: 'With reply',
          direction: direction,
          content: _shortText,
          showTail: true,
          replyContent: _replyWidget,
        ),
        _Variant(
          label: '1 reaction',
          direction: direction,
          content: _shortText,
          showTail: true,
          reactions: _oneReaction,
        ),
        _Variant(
          label: '3 reactions',
          direction: direction,
          content: _shortText,
          showTail: true,
          reactions: _threeReactions,
        ),
        _Variant(
          label: '12 reactions (wrapping)',
          direction: direction,
          content: _shortText,
          showTail: true,
          reactions: _twelveReactions,
        ),
        _Variant(
          label: 'Media only',
          direction: direction,
          showTail: true,
          mediaContent: mediaPlaceholder,
        ),
        _Variant(
          label: 'Media + caption',
          direction: direction,
          content: 'Check this out!',
          showTail: true,
          mediaContent: mediaPlaceholder,
        ),
        _Variant(
          label: 'Deleted — with tail',
          direction: direction,
          isDeleted: true,
          showTail: true,
        ),
        _Variant(
          label: 'Deleted — no tail',
          direction: direction,
          isDeleted: true,
          showTail: false,
        ),
        if (isIncoming)
          _Variant(
            label: 'Deleted — avatar + name',
            direction: direction,
            isDeleted: true,
            showTail: true,
            avatar: _sampleAvatar(context),
            senderName: 'Trent Reznor',
            senderNameColor: avatarColorSet.border,
          ),
      ],
    );
  }
}

class _Variant extends StatelessWidget {
  const _Variant({
    required this.label,
    required this.direction,
    required this.showTail,
    this.isDeleted = false,
    this.content,
    this.replyContent,
    this.mediaContent,
    this.reactions = const [],
    this.avatar,
    this.senderName,
    this.senderNameColor,
  });

  final String label;
  final MessageDirection direction;
  final bool showTail;
  final bool isDeleted;
  final String? content;
  final Widget? replyContent;
  final Widget? mediaContent;
  final List<EmojiReaction> reactions;
  final Widget? avatar;
  final String? senderName;
  final Color? senderNameColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.backgroundContentTertiary,
            ),
          ),
          const SizedBox(height: 4),
          WnMessageBubble(
            direction: direction,
            isDeleted: isDeleted,
            deletedLabel: isDeleted ? 'This message was deleted.' : null,
            showTail: showTail,
            content: content,
            replyContent: replyContent,
            mediaContent: mediaContent,
            reactions: reactions,
            timestamp: '12:29',
            avatar: avatar,
            senderName: senderName,
            senderNameColor: senderNameColor,
          ),
        ],
      ),
    );
  }
}

class _SampleQuote extends StatelessWidget {
  const _SampleQuote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Wes Borland',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.backgroundContentTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'There may be something good in silence.',
            style: TextStyle(
              fontSize: 13,
              color: colors.backgroundContentSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
