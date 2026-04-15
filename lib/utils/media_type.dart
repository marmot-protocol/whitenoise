import 'package:mime/mime.dart' show lookupMimeType;
import 'package:whitenoise/src/rust/api/media_files.dart';

const _videoExtensions = {'.mp4', '.mov', '.m4v', '.webm', '.mkv', '.avi'};

bool isVideoMediaFile(MediaFile mediaFile) {
  return _isVideoValue(mediaFile.mediaType) || _isVideoValue(mediaFile.mimeType);
}

bool isVideoFilePath(String filePath) {
  final path = filePath.toLowerCase();
  final mimeType = lookupMimeType(filePath);
  return _isVideoValue(mimeType) || _videoExtensions.any(path.endsWith);
}

bool _isVideoValue(String? value) {
  final trimmed = value?.trim().toLowerCase();
  if (trimmed == null || trimmed.isEmpty) return false;
  final normalized = trimmed.split(';').first.trim();
  if (normalized.isEmpty) return false;
  if (normalized == 'video') return true;

  final parts = normalized.split('/');
  return parts.length == 2 && parts[0] == 'video' && parts[1].isNotEmpty;
}
