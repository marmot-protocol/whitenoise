import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class ChatRawDebugScreen extends HookConsumerWidget {
  final String groupId;

  const ChatRawDebugScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final (
      :messageCount,
      :getMessage,
      :getReversedMessageIndex,
      :getMessageById,
      :isLoading,
      :latestMessageId,
      :latestMessagePubkey,
      :getChatMessageQuote,
      :getAuthorMetadata,
    ) = useChatMessages(
      groupId,
    );

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.rawDebugViewTitle,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      color: colors.backgroundContentPrimary,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        _DebugHeader(
                          groupId: groupId,
                          messageCount: messageCount,
                          latestMessageId: latestMessageId,
                          latestMessagePubkey: latestMessagePubkey,
                        ),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: messageCount == 0
                              ? Center(
                                  child: Text(
                                    context.l10n.rawDebugViewMessageCount(0),
                                    style: typography.medium14.copyWith(
                                      color: colors.backgroundContentTertiary,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: messageCount,
                                  itemBuilder: (context, index) {
                                    final message = getMessage(index);
                                    final authorMetadata = getAuthorMetadata(message.pubkey);
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 8.h),
                                      child: _RawMessageCard(
                                        message: message,
                                        authorMetadata: authorMetadata,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DebugHeader extends StatelessWidget {
  const _DebugHeader({
    required this.groupId,
    required this.messageCount,
    required this.latestMessageId,
    required this.latestMessagePubkey,
  });

  final String groupId;
  final int messageCount;
  final String? latestMessageId;
  final String? latestMessagePubkey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () async {
        final text = [
          'group_id:              $groupId',
          'message_count:         $messageCount',
          if (latestMessageId != null) 'latest_message_id:     $latestMessageId',
          if (latestMessagePubkey != null) 'latest_message_pubkey: $latestMessagePubkey',
        ].join('\n');
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.rawDebugViewCopied),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DebugField(
              label: 'group_id',
              value: groupId,
              valueKey: const Key('debug_group_id'),
            ),
            SizedBox(height: 4.h),
            _DebugField(
              label: 'message_count',
              value: '$messageCount',
              valueKey: const Key('debug_message_count'),
            ),
            if (latestMessageId != null) ...[
              SizedBox(height: 4.h),
              _DebugField(label: 'latest_message_id', value: latestMessageId!),
            ],
            if (latestMessagePubkey != null) ...[
              SizedBox(height: 4.h),
              _DebugField(label: 'latest_message_pubkey', value: latestMessagePubkey!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebugField extends StatelessWidget {
  const _DebugField({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: typography.semiBold10.copyWith(
            color: colors.backgroundContentSecondary,
            fontFamily: 'monospace',
          ),
        ),
        Expanded(
          child: SelectableText(
            key: valueKey,
            value,
            style: typography.medium10.copyWith(
              color: colors.backgroundContentPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _RawMessageCard extends StatelessWidget {
  const _RawMessageCard({
    required this.message,
    required this.authorMetadata,
  });

  final ChatMessage message;
  final FlutterMetadata? authorMetadata;

  String _formatRaw() {
    final msg = message;
    final meta = authorMetadata;
    final buffer = StringBuffer();

    buffer.writeln('── message ──────────────────────────────────────');
    buffer.writeln('id:                  ${msg.id}');
    buffer.writeln('kind:                ${msg.kind}');
    buffer.writeln('pubkey:              ${msg.pubkey}');
    buffer.writeln('created_at:          ${msg.createdAt.toIso8601String()}');
    buffer.writeln('is_deleted:          ${msg.isDeleted}');
    buffer.writeln('is_reply:            ${msg.isReply}');
    if (msg.replyToId != null) {
      buffer.writeln('reply_to_id:         ${msg.replyToId}');
    }
    buffer.writeln('content:             ${msg.content}');

    buffer.writeln();
    buffer.writeln('── author ───────────────────────────────────────');
    if (meta != null) {
      if (meta.name != null) buffer.writeln('name:                ${meta.name}');
      if (meta.displayName != null) buffer.writeln('display_name:        ${meta.displayName}');
      if (meta.nip05 != null) buffer.writeln('nip05:               ${meta.nip05}');
      if (meta.picture != null) buffer.writeln('picture:             ${meta.picture}');
      if (meta.website != null) buffer.writeln('website:             ${meta.website}');
      if (meta.about != null) buffer.writeln('about:               ${meta.about}');
    } else {
      buffer.writeln('(no metadata loaded)');
    }

    buffer.writeln();
    buffer.writeln('── tags ─────────────────────────────────────────');
    if (msg.tags.isNotEmpty) {
      for (final tag in msg.tags) {
        buffer.writeln('  [${tag.join(', ')}]');
      }
    } else {
      buffer.writeln('  (none)');
    }

    buffer.writeln();
    buffer.writeln('── reactions ────────────────────────────────────');
    if (msg.reactions.byEmoji.isNotEmpty) {
      for (final r in msg.reactions.byEmoji) {
        buffer.writeln('  ${r.emoji}  count=${r.count}');
        for (final u in r.users) {
          buffer.writeln('    pubkey: $u');
        }
      }
    } else {
      buffer.writeln('  (none)');
    }
    if (msg.reactions.userReactions.isNotEmpty) {
      buffer.writeln('  raw user reactions:');
      for (final ur in msg.reactions.userReactions) {
        buffer.writeln('    reaction_id: ${ur.reactionId}');
        buffer.writeln('    user:        ${ur.user}');
        buffer.writeln('    emoji:       ${ur.emoji}');
        buffer.writeln('    created_at:  ${ur.createdAt.toIso8601String()}');
      }
    }

    buffer.writeln();
    buffer.writeln('── media ────────────────────────────────────────');
    if (msg.mediaAttachments.isNotEmpty) {
      for (final m in msg.mediaAttachments) {
        _appendMediaFile(buffer, m);
      }
    } else {
      buffer.writeln('  (none)');
    }

    buffer.writeln();
    buffer.writeln('── tokens ───────────────────────────────────────');
    if (msg.contentTokens.isNotEmpty) {
      for (final t in msg.contentTokens) {
        if (t.content != null) {
          buffer.writeln('  [${t.tokenType}] ${t.content}');
        } else {
          buffer.writeln('  [${t.tokenType}]');
        }
      }
    } else {
      buffer.writeln('  (none)');
    }

    return buffer.toString().trimRight();
  }

  void _appendMediaFile(StringBuffer buffer, MediaFile m) {
    buffer.writeln('  id:                  ${m.id}');
    buffer.writeln('  mls_group_id:        ${m.mlsGroupId}');
    buffer.writeln('  account_pubkey:      ${m.accountPubkey}');
    buffer.writeln('  file_path:           ${m.filePath}');
    buffer.writeln('  mime_type:           ${m.mimeType}');
    buffer.writeln('  media_type:          ${m.mediaType}');
    buffer.writeln('  blossom_url:         ${m.blossomUrl}');
    buffer.writeln('  nostr_key:           ${m.nostrKey}');
    buffer.writeln('  encrypted_hash:      ${m.encryptedFileHash}');
    if (m.originalFileHash != null) {
      buffer.writeln('  original_hash:       ${m.originalFileHash}');
    }
    if (m.nonce != null) buffer.writeln('  nonce:               ${m.nonce}');
    if (m.schemeVersion != null) {
      buffer.writeln('  scheme_version:      ${m.schemeVersion}');
    }
    if (m.fileMetadata != null) {
      final fm = m.fileMetadata!;
      if (fm.originalFilename != null) {
        buffer.writeln('  filename:            ${fm.originalFilename}');
      }
      if (fm.dimensions != null) buffer.writeln('  dimensions:          ${fm.dimensions}');
      if (fm.blurhash != null) buffer.writeln('  blurhash:            ${fm.blurhash}');
    }
    buffer.writeln('  created_at:          ${m.createdAt.toIso8601String()}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final raw = _formatRaw();

    return GestureDetector(
      key: Key('raw_message_card_${message.id}'),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: raw));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.rawDebugViewCopied),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: message.isDeleted
              ? colors.backgroundSecondary.withValues(alpha: 0.5)
              : colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: message.isDeleted
                ? colors.backgroundContentDestructive.withValues(alpha: 0.4)
                : colors.backgroundSecondary,
          ),
        ),
        child: SelectableText(
          raw,
          style: typography.medium10.copyWith(
            color: colors.backgroundContentPrimary,
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
