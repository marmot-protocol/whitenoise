import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

final _logger = Logger('useMediaUpload');

enum MediaUploadStatus { uploading, uploaded, error }

typedef MediaUploadItem = ({
  String filePath,
  MediaUploadStatus status,
  MediaFile? file,
  VoidCallback? retry,
});

typedef MediaUploadState = ({
  List<MediaUploadItem> items,
  bool canSend,
  List<MediaFile> uploadedFiles,
  Future<void> Function() pickImages,
  void Function(String filePath) removeItem,
  VoidCallback clearAll,
});

typedef UploadFunction =
    Future<MediaFile> Function({
      required String accountPubkey,
      required String groupId,
      required String filePath,
    });

MediaUploadState useMediaUpload({
  required String pubkey,
  required String groupId,
  ImagePicker? imagePicker,
  UploadFunction? uploadFn,
}) {
  final items = useState<List<MediaUploadItem>>([]);
  final picker = useMemoized(() => imagePicker ?? ImagePicker(), [imagePicker]);
  final upload = uploadFn ?? uploadChatMedia;

  List<MediaUploadItem> updateItem(
    List<MediaUploadItem> currentItems,
    String filePath,
    MediaUploadItem Function(MediaUploadItem) update,
  ) {
    return currentItems.map((item) {
      if (item.filePath == filePath) {
        return update(item);
      }
      return item;
    }).toList();
  }

  Future<void> performUpload(String filePath) async {
    _logger.info('performUpload START filePath=$filePath groupId=$groupId');
    try {
      final file = await upload(
        accountPubkey: pubkey,
        groupId: groupId,
        filePath: filePath,
      );
      _logger.info(
        'performUpload OK filePath=$filePath blossomUrl=${file.blossomUrl} '
        'mimeType=${file.mimeType} mediaType=${file.mediaType}',
      );
      items.value = updateItem(
        items.value,
        filePath,
        (item) => (
          filePath: item.filePath,
          status: MediaUploadStatus.uploaded,
          file: file,
          retry: null,
        ),
      );
    } catch (e, st) {
      _logger.severe('performUpload FAILED filePath=$filePath groupId=$groupId', e, st);
      items.value = updateItem(
        items.value,
        filePath,
        (item) => (
          filePath: item.filePath,
          status: MediaUploadStatus.error,
          file: null,
          retry: () {
            _logger.info('performUpload retry filePath=$filePath');
            items.value = updateItem(
              items.value,
              filePath,
              (i) => (
                filePath: i.filePath,
                status: MediaUploadStatus.uploading,
                file: null,
                retry: null,
              ),
            );
            unawaited(performUpload(filePath));
          },
        ),
      );
    }
  }

  Future<void> pickImages() async {
    _logger.info('pickImages groupId=$groupId');
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (pickedFiles.isEmpty) {
      _logger.info('pickImages no files selected');
      return;
    }

    final existingPaths = items.value.map((item) => item.filePath).toSet();
    final uniqueFiles = pickedFiles.where((xFile) => !existingPaths.contains(xFile.path)).toList();
    if (uniqueFiles.isEmpty) {
      _logger.info('pickImages all ${pickedFiles.length} files already queued, skipping');
      return;
    }

    _logger.info(
      'pickImages picked=${pickedFiles.length} unique=${uniqueFiles.length} groupId=$groupId',
    );

    final newItems = uniqueFiles.map((xFile) {
      return (
            filePath: xFile.path,
            status: MediaUploadStatus.uploading,
            file: null,
            retry: null,
          )
          as MediaUploadItem;
    }).toList();

    items.value = [...items.value, ...newItems];

    for (final item in newItems) {
      unawaited(performUpload(item.filePath));
    }
  }

  void removeItem(String filePath) {
    items.value = items.value.where((item) => item.filePath != filePath).toList();
  }

  void clearAll() {
    items.value = [];
  }

  final canSend =
      items.value.isNotEmpty &&
      items.value.every((item) => item.status == MediaUploadStatus.uploaded);

  final uploadedFiles = items.value
      .where((item) => item.status == MediaUploadStatus.uploaded && item.file != null)
      .map((item) => item.file!)
      .toList();

  return (
    items: items.value,
    canSend: canSend,
    uploadedFiles: uploadedFiles,
    pickImages: pickImages,
    removeItem: removeItem,
    clearAll: clearAll,
  );
}
