import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

enum MediaDownloadStatus { loading, success, error }

typedef MediaDownloadResult = ({
  MediaDownloadStatus status,
  String? localPath,
  VoidCallback? retry,
});

MediaDownloadResult useMediaDownload({required MediaFile mediaFile}) {
  final status = useState(MediaDownloadStatus.loading);
  final localPath = useState<String?>(null);
  final downloadStarted = useRef(false);
  final retryTrigger = useState(0);

  useEffect(() {
    downloadStarted.value = false;
    status.value = MediaDownloadStatus.loading;
    localPath.value = null;
    return null;
  }, [mediaFile.id, retryTrigger.value]);

  useEffect(() {
    if (downloadStarted.value) return null;
    downloadStarted.value = true;

    Future<void> download() async {
      final existingPath = mediaFile.filePath;
      if (existingPath.isNotEmpty && File(existingPath).existsSync()) {
        localPath.value = existingPath;
        status.value = MediaDownloadStatus.success;
        return;
      }

      final fileHash = mediaFile.originalFileHash;
      if (fileHash == null || fileHash.isEmpty) {
        status.value = MediaDownloadStatus.error;
        return;
      }

      try {
        final result = await downloadChatMedia(
          accountPubkey: mediaFile.accountPubkey,
          groupId: mediaFile.mlsGroupId,
          originalFileHash: fileHash,
        );
        localPath.value = result.filePath;
        status.value = MediaDownloadStatus.success;
      } catch (_) {
        status.value = MediaDownloadStatus.error;
      }
    }

    download();
    return null;
  }, [mediaFile.id, retryTrigger.value]);

  void retry() {
    retryTrigger.value++;
  }

  return (
    status: status.value,
    localPath: localPath.value,
    retry: status.value == MediaDownloadStatus.error ? retry : null,
  );
}
