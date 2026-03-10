import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/debug_info_pill.dart';
import 'package:whitenoise/widgets/debug_key_value_row.dart';
import 'package:whitenoise/widgets/debug_section_card.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

Future<void> _copyDebugText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.rawDebugViewCopied),
      duration: const Duration(seconds: 2),
    ),
  );
}

class ChatRawDebugScreen extends HookConsumerWidget {
  final String groupId;

  const ChatRawDebugScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final debugLog = ref.read(messageDebugLogProvider.notifier);
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
      debugLog: debugLog,
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
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
                    itemCount: messageCount == 0 ? messageCount + 5 : messageCount + 4,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _DebugHeader(
                            groupId: groupId,
                            messageCount: messageCount,
                            latestMessageId: latestMessageId,
                            latestMessagePubkey: latestMessagePubkey,
                          ),
                        );
                      }
                      if (index == 1) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _SendLogSection(groupId: groupId),
                        );
                      }
                      if (index == 2) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _StreamLogSection(groupId: groupId),
                        );
                      }
                      if (index == 3) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _RatchetTreeSection(groupId: groupId),
                        );
                      }
                      if (index == 4 && messageCount == 0) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 32.h),
                            child: Text(
                              context.l10n.rawDebugViewMessageCount(0),
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentTertiary,
                              ),
                            ),
                          ),
                        );
                      }
                      final messageIndex = index - 4;
                      if (messageIndex < 0 || messageIndex >= messageCount) {
                        return const SizedBox.shrink();
                      }
                      final message = getMessage(messageIndex);
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
    final copyText = [
      'group_id:              $groupId',
      'message_count:         $messageCount',
      if (latestMessageId != null) 'latest_message_id:     $latestMessageId',
      if (latestMessagePubkey != null) 'latest_message_pubkey: $latestMessagePubkey',
    ].join('\n');

    return DebugSectionCard(
      title: 'Session Overview',
      subtitle: 'Group context and top-level counters',
      onCopy: () => _copyDebugText(context, copyText),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DebugKeyValueRow(
            label: 'group_id',
            value: groupId,
            valueKey: const Key('debug_group_id'),
          ),
          SizedBox(height: 4.h),
          DebugKeyValueRow(
            label: 'message_count',
            value: '$messageCount',
            valueKey: const Key('debug_message_count'),
          ),
          if (latestMessageId != null) ...[
            SizedBox(height: 4.h),
            DebugKeyValueRow(label: 'latest_message_id', value: latestMessageId!),
          ],
          if (latestMessagePubkey != null) ...[
            SizedBox(height: 4.h),
            DebugKeyValueRow(label: 'latest_message_pubkey', value: latestMessagePubkey!),
          ],
        ],
      ),
    );
  }
}

class _SendLogSection extends ConsumerWidget {
  const _SendLogSection({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final state = ref.watch(messageDebugLogProvider);
    final forGroup = state.sendLog.where((e) => e.groupId == groupId).toList();
    final copyText = forGroup.map(_formatSendLogEntry).join('\n\n');

    if (forGroup.isEmpty) {
      return const DebugSectionCard(
        title: 'Send Log',
        subtitle: 'No attempts captured for this group',
        child: Text(
          'send_log: (no attempts for this group)',
          style: TextStyle(fontFamily: 'monospace'),
        ),
      );
    }

    return DebugSectionCard(
      title: 'Send Log',
      subtitle: '${forGroup.length} entries',
      onCopy: () => _copyDebugText(context, copyText),
      borderColor: colors.accent.emerald.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...forGroup
              .take(10)
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.6)),
                    ),
                    child: SelectableText(
                      _formatSendLogEntry(e),
                      style: typography.medium10.copyWith(
                        color: _statusColor(colors, e.status),
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
          if (forGroup.length > 10)
            Text(
              '+${forGroup.length - 10} more entries',
              style: typography.medium10.copyWith(
                color: colors.backgroundContentTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(SemanticColors colors, MessageSendStatus status) {
    return switch (status) {
      MessageSendStatus.started => colors.backgroundContentSecondary,
      MessageSendStatus.ok => colors.backgroundContentPrimary,
      MessageSendStatus.failed => colors.fillDestructive,
    };
  }

  String _formatSendLogEntry(MessageSendLogEntry e) {
    final time = e.timestamp.toIso8601String();
    final statusStr = e.status.name.toUpperCase();
    final parts = <String>['$time $statusStr'];
    if (e.contentLen != null) parts.add('len=${e.contentLen}');
    if (e.mediaCount != null && e.mediaCount! > 0) parts.add('media=${e.mediaCount}');
    if (e.replyToId != null) parts.add('replyTo=${e.replyToId}');
    if (e.resultId != null && e.resultId!.isNotEmpty) parts.add('id=${e.resultId}');
    if (e.error != null) parts.add('error=${e.error}');
    if (e.stackTrace != null) {
      parts.add('stack=${e.stackTrace.toString().split('\n').take(2).join(' ')}');
    }
    return parts.join(' ');
  }
}

class _StreamLogSection extends ConsumerWidget {
  const _StreamLogSection({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final state = ref.watch(messageDebugLogProvider);
    final forGroup = state.streamLog.where((e) => e.groupId == groupId).toList();
    final copyText = forGroup.map(_formatStreamEvent).join('\n');

    if (forGroup.isEmpty) {
      return const DebugSectionCard(
        title: 'Stream Log',
        subtitle: 'No stream events captured for this group',
        child: Text(
          'stream_log: (no events for this group)',
          style: TextStyle(fontFamily: 'monospace'),
        ),
      );
    }

    return DebugSectionCard(
      title: 'Stream Log',
      subtitle: '${forGroup.length} events',
      onCopy: () => _copyDebugText(context, copyText),
      borderColor: colors.accent.sky.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...forGroup
              .take(20)
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.6)),
                    ),
                    child: SelectableText(
                      _formatStreamEvent(e),
                      style: typography.medium10.copyWith(
                        color: _eventColor(colors, e.eventType),
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
          if (forGroup.length > 20)
            Text(
              '+${forGroup.length - 20} more events',
              style: typography.medium10.copyWith(
                color: colors.backgroundContentTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Color _eventColor(SemanticColors colors, MessageStreamEventType eventType) {
    return switch (eventType) {
      MessageStreamEventType.connected => colors.backgroundContentPrimary,
      MessageStreamEventType.snapshot => colors.backgroundContentPrimary,
      MessageStreamEventType.update => colors.backgroundContentSecondary,
      MessageStreamEventType.lagged => colors.fillDestructive,
      MessageStreamEventType.streamError => colors.fillDestructive,
      MessageStreamEventType.disconnected => colors.backgroundContentTertiary,
    };
  }

  String _formatStreamEvent(MessageStreamEventEntry e) {
    final time = e.timestamp.toIso8601String();
    final typeName = e.eventType.name.toUpperCase();
    final parts = <String>['$time $typeName'];
    if (e.messageCount != null) parts.add('count=${e.messageCount}');
    if (e.trigger != null) parts.add('trigger=${e.trigger}');
    if (e.messageId != null) {
      final shortId = e.messageId!.length > 8 ? '${e.messageId!.substring(0, 8)}…' : e.messageId!;
      parts.add('msgId=$shortId');
    }
    if (e.laggedCount != null) parts.add('lagged=${e.laggedCount}');
    if (e.error != null) parts.add('error=${e.error}');
    return parts.join(' ');
  }
}

class _RatchetTreeSection extends HookConsumerWidget {
  const _RatchetTreeSection({required this.groupId});

  final String groupId;

  String _shortKey(String value) {
    if (value.length <= 24) {
      return value;
    }
    return '${value.substring(0, 14)}…${value.substring(value.length - 8)}';
  }

  String _formatTreeInfo(RatchetTreeInfo info) {
    final buffer = StringBuffer();
    buffer.writeln('tree_hash:       ${info.treeHash}');
    buffer.writeln('serialized_len:  ${info.serializedTree.length ~/ 2} bytes');
    buffer.writeln();
    buffer.writeln('leaf_nodes (${info.leafNodes.length}):');
    for (final leaf in info.leafNodes) {
      final shortCred = leaf.credentialIdentity.length > 16
          ? '${leaf.credentialIdentity.substring(0, 16)}…'
          : leaf.credentialIdentity;
      final shortEnc = leaf.encryptionKey.length > 16
          ? '${leaf.encryptionKey.substring(0, 16)}…'
          : leaf.encryptionKey;
      final shortSig = leaf.signatureKey.length > 16
          ? '${leaf.signatureKey.substring(0, 16)}…'
          : leaf.signatureKey;
      buffer.writeln('  [${leaf.index}] cred=$shortCred');
      buffer.writeln('      enc_key=$shortEnc');
      buffer.writeln('      sig_key=$shortSig');
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final ratchetFuture = useMemoized(
      () => getRatchetTreeInfo(accountPubkey: accountPubkey, groupId: groupId),
      [accountPubkey, groupId],
    );

    return FutureBuilder<RatchetTreeInfo>(
      future: ratchetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DebugSectionCard(
            title: 'Ratchet Tree',
            subtitle: 'Loading group tree snapshot',
            borderColor: colors.accent.amber.border,
            child: Row(
              children: [
                SizedBox(
                  width: 12.w,
                  height: 12.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.backgroundContentSecondary,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'ratchet_tree: loading…',
                  style: typography.medium10.copyWith(
                    color: colors.backgroundContentTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return DebugSectionCard(
            title: 'Ratchet Tree',
            subtitle: 'Unable to load tree snapshot',
            borderColor: colors.borderDestructiveSecondary,
            child: Text(
              'ratchet_tree: ${snapshot.error}',
              style: typography.medium10.copyWith(
                color: colors.fillDestructive,
                fontFamily: 'monospace',
              ),
            ),
          );
        }
        final info = snapshot.data!;
        final text = _formatTreeInfo(info);
        final serializedBytes = info.serializedTree.length ~/ 2;
        return DebugSectionCard(
          title: 'Ratchet Tree',
          subtitle: '${info.leafNodes.length} leaves',
          onCopy: () => _copyDebugText(context, text),
          borderColor: colors.accent.amber.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  DebugInfoPill(label: 'leaves ${info.leafNodes.length}'),
                  DebugInfoPill(label: 'size $serializedBytes bytes'),
                ],
              ),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.7)),
                ),
                child: DebugKeyValueRow(
                  label: 'tree_hash',
                  value: info.treeHash,
                  labelWidth: 70.w,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Leaf nodes',
                style: typography.semiBold10.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              ...info.leafNodes.map(
                (leaf) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaf [${leaf.index}]',
                          style: typography.semiBold10.copyWith(
                            color: colors.backgroundContentPrimary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        DebugKeyValueRow(
                          label: 'credential',
                          value: _shortKey(leaf.credentialIdentity),
                          labelWidth: 70.w,
                        ),
                        SizedBox(height: 4.h),
                        DebugKeyValueRow(
                          label: 'enc_key',
                          value: _shortKey(leaf.encryptionKey),
                          labelWidth: 70.w,
                        ),
                        SizedBox(height: 4.h),
                        DebugKeyValueRow(
                          label: 'sig_key',
                          value: _shortKey(leaf.signatureKey),
                          labelWidth: 70.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Raw snapshot',
                style: typography.semiBold10.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
              ),
              SizedBox(height: 6.h),
              SelectableText(
                text,
                style: typography.medium10.copyWith(
                  color: colors.backgroundContentPrimary,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
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

  String _shortId(String value) {
    if (value.length <= 12) {
      return value;
    }
    return '${value.substring(0, 12)}…';
  }

  String _shortPubkey(String value) {
    if (value.length <= 18) {
      return value;
    }
    return '${value.substring(0, 10)}…${value.substring(value.length - 6)}';
  }

  String _contentPreview(String value) {
    final normalized = value.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) {
      return '(empty)';
    }
    if (normalized.length <= 110) {
      return normalized;
    }
    return '${normalized.substring(0, 110)}…';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final raw = _formatRaw();
    final tagsCount = message.tags.length;
    final emojiReactionCount = message.reactions.byEmoji.length;
    final mediaCount = message.mediaAttachments.length;
    final tokenCount = message.contentTokens.length;

    return InkWell(
      key: Key('raw_message_card_${message.id}'),
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _copyDebugText(context, raw),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: message.isDeleted
              ? colors.backgroundSecondary.withValues(alpha: 0.7)
              : colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: message.isDeleted
                ? colors.backgroundContentDestructive.withValues(alpha: 0.55)
                : colors.borderTertiary.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.16),
              blurRadius: 12.r,
              offset: Offset(0, 7.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Message ${_shortId(message.id)}',
                    style: typography.semiBold12.copyWith(
                      color: colors.backgroundContentPrimary,
                      letterSpacing: 0.2.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: message.isDeleted
                        ? colors.intentionErrorBackground
                        : colors.intentionInfoBackground,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    message.isDeleted ? 'Deleted' : 'Active',
                    style: typography.medium10.copyWith(
                      color: message.isDeleted
                          ? colors.intentionErrorContent
                          : colors.intentionInfoContent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              message.createdAt.toIso8601String(),
              style: typography.medium10.copyWith(color: colors.backgroundContentSecondary),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                DebugInfoPill(label: 'kind ${message.kind}'),
                DebugInfoPill(label: message.isReply ? 'reply' : 'root'),
                DebugInfoPill(label: '$tagsCount tags'),
                DebugInfoPill(label: '$emojiReactionCount reactions'),
                DebugInfoPill(label: '$mediaCount media'),
                DebugInfoPill(label: '$tokenCount tokens'),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: colors.backgroundPrimary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.85)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DebugKeyValueRow(label: 'id', value: message.id, labelWidth: 56.w),
                  SizedBox(height: 5.h),
                  DebugKeyValueRow(
                    label: 'pubkey',
                    value: _shortPubkey(message.pubkey),
                    labelWidth: 56.w,
                  ),
                  SizedBox(height: 5.h),
                  DebugKeyValueRow(
                    label: 'content',
                    value: _contentPreview(message.content),
                    labelWidth: 56.w,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: colors.backgroundPrimary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.85)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.data_object_rounded,
                        size: 12.w,
                        color: colors.backgroundContentSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Raw payload (tap card to copy)',
                          style: typography.semiBold10.copyWith(
                            color: colors.backgroundContentSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SelectableText(
                    raw,
                    style: typography.medium10.copyWith(
                      color: colors.backgroundContentPrimary,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
