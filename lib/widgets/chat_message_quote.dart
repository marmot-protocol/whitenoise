import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_message_quote.dart';

class ChatMessageQuote extends StatelessWidget {
  const ChatMessageQuote({
    super.key,
    required this.data,
    this.currentUserPubkey,
    this.onTap,
    this.onCancel,
    this.authorColor,
  });

  final ChatMessageQuoteData data;
  final String? currentUserPubkey;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final Color? authorColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final author = data.isNotFound
        ? l10n.unknownUser
        : (currentUserPubkey != null && data.authorPubkey == currentUserPubkey
              ? l10n.you
              : presentName(data.authorMetadata) ?? l10n.unknownUser);

    final text = data.isNotFound ? l10n.messageNotFound : data.content;

    if (data.mediaFile != null) {
      return _ChatMessageQuoteWithMedia(
        author: author,
        text: text,
        mediaFile: data.mediaFile!,
        onTap: onTap,
        onCancel: onCancel,
        authorColor: authorColor,
      );
    }

    return WnMessageQuote(
      author: author,
      text: text,
      onTap: onTap,
      onCancel: onCancel,
      authorColor: authorColor,
    );
  }
}

class _ChatMessageQuoteWithMedia extends HookWidget {
  const _ChatMessageQuoteWithMedia({
    required this.author,
    required this.text,
    required this.mediaFile,
    this.onTap,
    this.onCancel,
    this.authorColor,
  });

  final String author;
  final String text;
  final MediaFile mediaFile;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final Color? authorColor;

  @override
  Widget build(BuildContext context) {
    final download = useMediaDownload(mediaFile: mediaFile);

    ImageProvider? image;
    if (download.status == MediaDownloadStatus.success && download.localPath != null) {
      image = FileImage(File(download.localPath!));
    }

    return WnMessageQuote(
      author: author,
      text: text,
      image: image,
      onTap: onTap,
      onCancel: onCancel,
      authorColor: authorColor,
    );
  }
}
