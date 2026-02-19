import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whitenoise/hooks/use_media_upload.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

import '../test_helpers.dart';

MediaFile _mediaFile({String filePath = '/uploaded/path.jpg'}) => MediaFile(
  id: 'media1',
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: filePath,
  originalFileHash: 'hash123',
  encryptedFileHash: 'encrypted123',
  mimeType: 'image/jpeg',
  mediaType: 'image',
  blossomUrl: 'https://example.com/media',
  nostrKey: 'nostr123',
  createdAt: DateTime(2024),
);

class _MockImagePicker extends ImagePicker {
  List<XFile> filesToReturn = [];
  int pickCallCount = 0;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    pickCallCount++;
    return filesToReturn;
  }
}

void main() {
  late _MockImagePicker mockPicker;
  late Completer<MediaFile> uploadCompleter;
  late bool shouldFailUpload;
  late int uploadCallCount;
  late List<String> uploadedFilePaths;

  Future<MediaFile> mockUpload({
    required String accountPubkey,
    required String groupId,
    required String filePath,
  }) async {
    uploadCallCount++;
    uploadedFilePaths.add(filePath);
    if (shouldFailUpload) {
      throw Exception('Upload failed');
    }
    if (uploadCompleter.isCompleted) {
      return _mediaFile(filePath: filePath);
    }
    return uploadCompleter.future;
  }

  setUp(() {
    mockPicker = _MockImagePicker();
    uploadCompleter = Completer<MediaFile>();
    shouldFailUpload = false;
    uploadCallCount = 0;
    uploadedFilePaths = [];
  });

  Future<MediaUploadState Function()> pump(WidgetTester tester) async {
    return await mountHook(
      tester,
      () => useMediaUpload(
        pubkey: testPubkeyA,
        groupId: testGroupId,
        imagePicker: mockPicker,
        uploadFn: mockUpload,
      ),
    );
  }

  group('useMediaUpload', () {
    testWidgets('starts with empty items', (tester) async {
      final getResult = await pump(tester);

      expect(getResult().items, isEmpty);
    });

    testWidgets('starts with canSend false', (tester) async {
      final getResult = await pump(tester);

      expect(getResult().canSend, isFalse);
    });

    testWidgets('starts with empty uploadedFiles', (tester) async {
      final getResult = await pump(tester);

      expect(getResult().uploadedFiles, isEmpty);
    });

    group('pickImages', () {
      testWidgets('calls image picker', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [];

        await getResult().pickImages();
        await tester.pump();

        expect(mockPicker.pickCallCount, 1);
      });

      testWidgets('does not add items when user cancels', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [];

        await getResult().pickImages();
        await tester.pump();

        expect(getResult().items, isEmpty);
      });

      testWidgets('adds item in uploading state when image is selected', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pump();

        expect(getResult().items.length, 1);
        expect(getResult().items.first.status, MediaUploadStatus.uploading);
        expect(getResult().items.first.filePath, '/path/to/image.jpg');
      });

      testWidgets('adds multiple items when multiple images selected', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [
          XFile('/path/to/image1.jpg'),
          XFile('/path/to/image2.jpg'),
        ];

        await getResult().pickImages();
        await tester.pump();

        expect(getResult().items.length, 2);
      });

      testWidgets('starts upload for each picked image', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [
          XFile('/path/to/image1.jpg'),
          XFile('/path/to/image2.jpg'),
        ];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(uploadCallCount, 2);
        expect(uploadedFilePaths, contains('/path/to/image1.jpg'));
        expect(uploadedFilePaths, contains('/path/to/image2.jpg'));
      });

      testWidgets('skips duplicate file paths when picking images', (tester) async {
        final getResult = await pump(tester);
        uploadCompleter.complete(_mediaFile());

        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.length, 1);
        final uploadsAfterFirst = uploadCallCount;

        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.length, 1);
        expect(uploadCallCount, uploadsAfterFirst);
      });

      testWidgets('appends to existing items when picking more images', (tester) async {
        final getResult = await pump(tester);
        uploadCompleter.complete(_mediaFile());

        mockPicker.filesToReturn = [XFile('/path/to/image1.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        mockPicker.filesToReturn = [XFile('/path/to/image2.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.length, 2);
      });
    });

    group('upload success', () {
      testWidgets('updates item to uploaded status', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.first.status, MediaUploadStatus.uploaded);
      });

      testWidgets('stores MediaFile in item', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.first.file, isNotNull);
        expect(getResult().items.first.file!.blossomUrl, 'https://example.com/media');
      });

      testWidgets('sets canSend to true when all items uploaded', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().canSend, isTrue);
      });

      testWidgets('includes file in uploadedFiles', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().uploadedFiles.length, 1);
      });
    });

    group('upload failure', () {
      testWidgets('updates item to error status', (tester) async {
        shouldFailUpload = true;
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.first.status, MediaUploadStatus.error);
      });

      testWidgets('provides retry callback', (tester) async {
        shouldFailUpload = true;
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().items.first.retry, isNotNull);
      });

      testWidgets('canSend is false when any item has error', (tester) async {
        shouldFailUpload = true;
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().canSend, isFalse);
      });

      testWidgets('retry resets item to uploading status', (tester) async {
        shouldFailUpload = true;
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pumpAndSettle();
        expect(getResult().items.first.status, MediaUploadStatus.error);

        shouldFailUpload = false;
        uploadCompleter = Completer<MediaFile>();
        getResult().items.first.retry!();
        await tester.pump();

        expect(getResult().items.first.status, MediaUploadStatus.uploading);
      });

      testWidgets('retry triggers new upload', (tester) async {
        shouldFailUpload = true;
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pumpAndSettle();

        final initialUploadCount = uploadCallCount;
        shouldFailUpload = false;
        uploadCompleter.complete(_mediaFile());

        getResult().items.first.retry!();
        await tester.pumpAndSettle();

        expect(uploadCallCount, initialUploadCount + 1);
        expect(getResult().items.first.status, MediaUploadStatus.uploaded);
      });
    });

    group('removeItem', () {
      testWidgets('removes item by filePath', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [
          XFile('/path/to/image1.jpg'),
          XFile('/path/to/image2.jpg'),
        ];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();
        expect(getResult().items.length, 2);

        getResult().removeItem('/path/to/image1.jpg');
        await tester.pump();

        expect(getResult().items.length, 1);
        expect(getResult().items.first.filePath, '/path/to/image2.jpg');
      });

      testWidgets('updates canSend when error item removed', (tester) async {
        final getResult = await pump(tester);

        mockPicker.filesToReturn = [XFile('/path/to/good.jpg')];
        uploadCompleter.complete(_mediaFile());
        await getResult().pickImages();
        await tester.pumpAndSettle();

        shouldFailUpload = true;
        uploadCompleter = Completer<MediaFile>();
        mockPicker.filesToReturn = [XFile('/path/to/bad.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().canSend, isFalse);

        getResult().removeItem('/path/to/bad.jpg');
        await tester.pump();

        expect(getResult().canSend, isTrue);
      });
    });

    group('clearAll', () {
      testWidgets('removes all items', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [
          XFile('/path/to/image1.jpg'),
          XFile('/path/to/image2.jpg'),
        ];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();
        expect(getResult().items.length, 2);

        getResult().clearAll();
        await tester.pump();

        expect(getResult().items, isEmpty);
      });

      testWidgets('resets canSend to false', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();
        expect(getResult().canSend, isTrue);

        getResult().clearAll();
        await tester.pump();

        expect(getResult().canSend, isFalse);
      });

      testWidgets('clears uploadedFiles', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();
        expect(getResult().uploadedFiles, isNotEmpty);

        getResult().clearAll();
        await tester.pump();

        expect(getResult().uploadedFiles, isEmpty);
      });
    });

    group('canSend', () {
      testWidgets('is false when items are still uploading', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [XFile('/path/to/image.jpg')];

        await getResult().pickImages();
        await tester.pump();

        expect(getResult().items.first.status, MediaUploadStatus.uploading);
        expect(getResult().canSend, isFalse);
      });

      testWidgets('is false when some items have errors', (tester) async {
        final getResult = await pump(tester);

        mockPicker.filesToReturn = [XFile('/path/to/good.jpg')];
        uploadCompleter.complete(_mediaFile());
        await getResult().pickImages();
        await tester.pumpAndSettle();

        shouldFailUpload = true;
        uploadCompleter = Completer<MediaFile>();
        mockPicker.filesToReturn = [XFile('/path/to/bad.jpg')];
        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().canSend, isFalse);
      });

      testWidgets('is true when all items are uploaded', (tester) async {
        final getResult = await pump(tester);
        mockPicker.filesToReturn = [
          XFile('/path/to/image1.jpg'),
          XFile('/path/to/image2.jpg'),
        ];
        uploadCompleter.complete(_mediaFile());

        await getResult().pickImages();
        await tester.pumpAndSettle();

        expect(getResult().canSend, isTrue);
      });
    });
  });
}
