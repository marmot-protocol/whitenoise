import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';

class MessageMediaTile extends ConsumerWidget {
  const MessageMediaTile({
    super.key,
    required this.mediaFile,
    required this.size,
  });

  final MediaFile mediaFile;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimension = size.w;
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(mediaFile),
      ),
    );

    return SizedBox(
      width: dimension,
      height: dimension,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            download.isDownloaded
                ? Image.file(
                  File(download.mediaFile.filePath),
                  key: ValueKey('image_${download.mediaFile.originalFileHash}'),
                  fit: BoxFit.cover,
                  width: dimension,
                  height: dimension,
                  errorBuilder: (_, _, _) => _buildBlurhash(dimension),
                )
                : _buildBlurhash(dimension),
      ),
    );
  }

  Widget _buildBlurhash(double dimension) {
    return SizedBox(
      width: dimension,
      height: dimension,
      child: BlurhashPlaceholder(
        key: ValueKey('blurhash_${mediaFile.originalFileHash}'),
        hash: mediaFile.fileMetadata?.blurhash,
        width: dimension,
        height: dimension,
      ),
    );
  }
}
