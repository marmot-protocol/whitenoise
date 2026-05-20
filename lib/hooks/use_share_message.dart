import 'dart:io';
import 'dart:ui';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';

enum ShareMessageStatus { idle, sharing, error }

typedef ShareFn = Future<void> Function({Rect? sharePositionOrigin});

typedef ShareMessageResult = ({
  ShareMessageStatus status,
  ShareFn? share,
});

ShareMessageResult useShareMessage({
  String? text,
  List<String> filePaths = const [],
  void Function(Object error)? onError,
}) {
  final status = useState(ShareMessageStatus.idle);

  final trimmedText = text?.trim();
  final hasText = trimmedText != null && trimmedText.isNotEmpty;
  final hasFiles = filePaths.isNotEmpty;
  final canShare = hasText || hasFiles;

  Future<void> share({Rect? sharePositionOrigin}) async {
    if (!canShare || status.value == ShareMessageStatus.sharing) return;
    status.value = ShareMessageStatus.sharing;
    try {
      final params = ShareParams(
        text: hasText ? trimmedText : null,
        files: hasFiles ? filePaths.map(XFile.new).toList() : null,
        sharePositionOrigin: sharePositionOrigin,
      );
      await SharePlus.instance.share(params);
      status.value = ShareMessageStatus.idle;
    } catch (e) {
      status.value = ShareMessageStatus.error;
      onError?.call(e);
    }
  }

  return (
    status: status.value,
    share: canShare ? share : null,
  );
}

List<String> filterExistingFiles(Iterable<String> paths) {
  return paths.where((p) => p.isNotEmpty && File(p).existsSync()).toList();
}
