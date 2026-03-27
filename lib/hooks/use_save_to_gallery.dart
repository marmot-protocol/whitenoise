import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:whitenoise/l10n/l10n.dart';

enum SaveToGalleryStatus { idle, saving, success, error }

typedef SaveToGalleryResult = ({
  SaveToGalleryStatus status,
  VoidCallback? save,
  String? errorMessage,
});

SaveToGalleryResult useSaveToGallery({
  required String localPath,
  required BuildContext context,
}) {
  final status = useState(SaveToGalleryStatus.idle);
  final errorMessage = useState<String?>(null);
  final l10n = context.l10n;

  void save() async {
    try {
      status.value = SaveToGalleryStatus.saving;
      await Gal.putImage(localPath);
      status.value = SaveToGalleryStatus.success;
    } on GalException catch (e) {
      status.value = SaveToGalleryStatus.error;
      switch (e.type) {
        case GalExceptionType.accessDenied:
          errorMessage.value = l10n.saveToGalleryPermissionDenied;
        case GalExceptionType.notEnoughSpace:
          errorMessage.value = l10n.saveToGalleryNotEnoughSpace;
        case GalExceptionType.notSupportedFormat:
          errorMessage.value = l10n.saveToGalleryNotSupportedFormat;
        case GalExceptionType.unexpected:
          errorMessage.value = l10n.saveToGalleryError;
      }
    } catch (e) {
      status.value = SaveToGalleryStatus.error;
      errorMessage.value = l10n.saveToGalleryError;
    } finally {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => status.value = SaveToGalleryStatus.idle,
      );
    }
  }

  return (
    status: status.value,
    save: status.value == SaveToGalleryStatus.saving ? null : save,
    errorMessage: errorMessage.value,
  );
}
