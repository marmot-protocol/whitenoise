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
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
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
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                    itemCount: messageCount + 5,
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

class _SendLogSection extends ConsumerWidget {
  const _SendLogSection({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final state = ref.watch(messageDebugLogProvider);
    final forGroup = state.sendLog.where((e) => e.groupId == groupId).toList();

    if (forGroup.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'send_log: (no attempts for this group)',
          style: typography.medium10.copyWith(
            color: colors.backgroundContentTertiary,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final text = forGroup.map(_formatSendLogEntry).join('\n\n');
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
            Text(
              'send_log (${forGroup.length} entries, tap to copy):',
              style: typography.semiBold10.copyWith(
                color: colors.backgroundContentSecondary,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 6.h),
            ...forGroup
                .take(10)
                .map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
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
          ],
        ),
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

    if (forGroup.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'stream_log: (no events for this group)',
          style: typography.medium10.copyWith(
            color: colors.backgroundContentTertiary,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final text = forGroup.map(_formatStreamEvent).join('\n');
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
            Text(
              'stream_log (${forGroup.length} events, tap to copy):',
              style: typography.semiBold10.copyWith(
                color: colors.backgroundContentSecondary,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 6.h),
            ...forGroup
                .take(20)
                .map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
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
          ],
        ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final snapshot = useFuture(
      useMemoized(
        () => groups_api.getRatchetTreeInfo(
          accountPubkey: accountPubkey,
          groupId: groupId,
        ),
        [accountPubkey, groupId],
      ),
    );

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'ratchet_tree: loading...',
          style: typography.medium10.copyWith(
            color: colors.backgroundContentTertiary,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'ratchet_tree: error: ${snapshot.error}',
          style: typography.medium10.copyWith(
            color: colors.fillDestructive,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final info = snapshot.data!;
    final buffer = StringBuffer();
    buffer.writeln('tree_hash: ${info.treeHash}');
    buffer.writeln('serialized_tree (${info.serializedTree.length ~/ 2} bytes):');
    // Show first 128 hex chars then truncate
    if (info.serializedTree.length > 128) {
      buffer.writeln('  ${info.serializedTree.substring(0, 128)}...');
    } else {
      buffer.writeln('  ${info.serializedTree}');
    }
    buffer.writeln('leaf_nodes (${info.leafNodes.length}):');
    for (final leaf in info.leafNodes) {
      buffer.writeln('  [${leaf.index}] identity: ${leaf.credentialIdentity}');
      buffer.writeln('       enc_key:  ${leaf.encryptionKey.substring(0, 16)}...');
      buffer.writeln('       sig_key:  ${leaf.signatureKey.substring(0, 16)}...');
    }

    final text = buffer.toString().trimRight();

    return GestureDetector(
      onTap: () async {
        // Copy full data including complete keys
        final fullBuffer = StringBuffer();
        fullBuffer.writeln('tree_hash: ${info.treeHash}');
        fullBuffer.writeln('serialized_tree: ${info.serializedTree}');
        fullBuffer.writeln('leaf_nodes (${info.leafNodes.length}):');
        for (final leaf in info.leafNodes) {
          fullBuffer.writeln('  [${leaf.index}]');
          fullBuffer.writeln('    identity:       ${leaf.credentialIdentity}');
          fullBuffer.writeln('    encryption_key: ${leaf.encryptionKey}');
          fullBuffer.writeln('    signature_key:  ${leaf.signatureKey}');
        }
        await Clipboard.setData(ClipboardData(text: fullBuffer.toString().trimRight()));
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
            Text(
              'ratchet_tree (tap to copy full data):',
              style: typography.semiBold10.copyWith(
                color: colors.backgroundContentSecondary,
                fontFamily: 'monospace',
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
