import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/utils/media_type.dart';

import '../test_helpers.dart';

MediaFile _mediaFile({
  String mimeType = 'image/jpeg',
  String mediaType = 'image',
}) => MediaFile(
  id: 'media1',
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: '/path/to/file',
  originalFileHash: 'hash123',
  encryptedFileHash: 'encrypted123',
  mimeType: mimeType,
  mediaType: mediaType,
  blossomUrl: 'https://example.com/media',
  nostrKey: 'nostr123',
  createdAt: DateTime(2024),
);

void main() {
  group('media type helpers', () {
    test('detects video media type', () {
      expect(isVideoMediaFile(_mediaFile(mediaType: 'video')), isTrue);
    });

    test('detects video mime type', () {
      expect(isVideoMediaFile(_mediaFile(mimeType: 'video/mp4')), isTrue);
    });

    test('detects video mime type with parameters', () {
      expect(isVideoMediaFile(_mediaFile(mimeType: 'video/mp4; codecs=h264')), isTrue);
    });

    test('does not treat images as video', () {
      expect(isVideoMediaFile(_mediaFile()), isFalse);
    });

    test('does not treat malformed media values as video', () {
      expect(isVideoMediaFile(_mediaFile(mimeType: 'video/', mediaType: '')), isFalse);
      expect(isVideoMediaFile(_mediaFile(mimeType: 'notvideo/mp4', mediaType: '')), isFalse);
      expect(isVideoMediaFile(_mediaFile(mimeType: '', mediaType: '')), isFalse);
    });

    test('detects common video file extensions', () {
      expect(isVideoFilePath('/path/to/clip.mp4'), isTrue);
      expect(isVideoFilePath('/path/to/clip.mov'), isTrue);
    });

    test('does not treat image file paths as video', () {
      expect(isVideoFilePath('/path/to/photo.jpg'), isFalse);
    });
  });
}
