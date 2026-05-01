import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';

enum SaveToGalleryStatus { idle, saving, success, error }

enum SaveToGalleryError { accessDenied, notEnoughSpace, notSupportedFormat, unexpected }

typedef SaveToGalleryResult = ({
  SaveToGalleryStatus status,
  VoidCallback? save,
  SaveToGalleryError? error,
  bool savedRecently,
});

SaveToGalleryResult useSaveToGallery({
  required String localPath,
  bool isVideo = false,
  void Function(SaveToGalleryError)? onError,
}) {
  final status = useState(SaveToGalleryStatus.idle);
  final error = useState<SaveToGalleryError?>(null);
  final savedRecently = useState(false);

  useEffect(() {
    savedRecently.value = false;
    error.value = null;
    return null;
  }, [localPath]);

  useEffect(() {
    if (!savedRecently.value) return null;
    final timer = Timer(const Duration(seconds: 2), () {
      savedRecently.value = false;
      status.value = SaveToGalleryStatus.idle;
    });
    return timer.cancel;
  }, [savedRecently.value]);

  void save() async {
    if (localPath.isEmpty) {
      status.value = SaveToGalleryStatus.error;
      error.value = SaveToGalleryError.unexpected;
      onError?.call(SaveToGalleryError.unexpected);
      return;
    }
    error.value = null;
    try {
      status.value = SaveToGalleryStatus.saving;
      if (isVideo) {
        await Gal.putVideo(localPath);
      } else {
        await Gal.putImage(localPath);
      }
      status.value = SaveToGalleryStatus.success;
      savedRecently.value = true;
    } on GalException catch (e) {
      status.value = SaveToGalleryStatus.error;
      final mapped = switch (e.type) {
        GalExceptionType.accessDenied => SaveToGalleryError.accessDenied,
        GalExceptionType.notEnoughSpace => SaveToGalleryError.notEnoughSpace,
        GalExceptionType.notSupportedFormat => SaveToGalleryError.notSupportedFormat,
        GalExceptionType.unexpected => SaveToGalleryError.unexpected,
      };
      error.value = mapped;
      onError?.call(mapped);
    } catch (_) {
      status.value = SaveToGalleryStatus.error;
      error.value = SaveToGalleryError.unexpected;
      onError?.call(SaveToGalleryError.unexpected);
    }
  }

  return (
    status: status.value,
    save: status.value == SaveToGalleryStatus.saving ? null : save,
    error: error.value,
    savedRecently: savedRecently.value,
  );
}
