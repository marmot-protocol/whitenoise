import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_media_upload.dart' show MediaUploadItem, MediaUploadStatus;
import 'package:whitenoise/widgets/chat_media_upload_preview.dart';
import 'package:whitenoise/widgets/wn_media_preview.dart';
import 'package:whitenoise/widgets/wn_spinner.dart';

import '../test_helpers.dart';

void main() {
  late Directory tempDir;
  late File testImageFile;
  late File testImageFile2;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('chat_media_preview_test');
    testImageFile = File('${tempDir.path}/test.jpg');
    testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
    testImageFile2 = File('${tempDir.path}/test2.jpg');
    testImageFile2.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  MediaUploadItem createItem({
    required String filePath,
    MediaUploadStatus status = MediaUploadStatus.uploaded,
    VoidCallback? retry,
  }) => (
    filePath: filePath,
    status: status,
    file: null,
    retry: retry,
  );

  group('ChatMediaUploadPreview', () {
    testWidgets('renders nothing when items is empty', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: const [],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byType(WnMediaPreview), findsNothing);
    });

    testWidgets('renders WnMediaPreview with items', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path)],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('chat_media_upload_preview')), findsOneWidget);
    });

    testWidgets('shows uploading overlay when current item is uploading', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path, status: MediaUploadStatus.uploading)],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('main_uploading_overlay')), findsOneWidget);
      expect(find.byType(WnSpinner), findsOneWidget);
    });

    testWidgets('does not show uploading overlay when item is uploaded', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path)],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('main_uploading_overlay')), findsNothing);
    });

    testWidgets('shows error overlay when current item has error', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path, status: MediaUploadStatus.error)],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('main_error_overlay')), findsOneWidget);
    });

    testWidgets('calls retry when error overlay is tapped', (tester) async {
      var retryCalled = false;
      await mountWidget(
        ChatMediaUploadPreview(
          items: [
            createItem(
              filePath: testImageFile.path,
              status: MediaUploadStatus.error,
              retry: () => retryCalled = true,
            ),
          ],
          onRemove: (_) {},
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('main_error_overlay')));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('calls onRemove with correct filePath when delete tapped', (tester) async {
      String? removedPath;
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path)],
          onRemove: (path) => removedPath = path,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('media_preview_delete_button')));
      await tester.pump();

      expect(removedPath, testImageFile.path);
    });

    testWidgets('handles multiple items and shows correct overlay for selected', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path),
            createItem(filePath: testImageFile2.path, status: MediaUploadStatus.uploading),
          ],
          onRemove: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('main_uploading_overlay')), findsNothing);

      await tester.tap(find.byKey(const Key('media_preview_thumbnail_1')));
      await tester.pump();

      expect(find.byKey(const Key('main_uploading_overlay')), findsOneWidget);
    });

    testWidgets('Image.file errorBuilder shows icon placeholder', (tester) async {
      await mountWidget(
        ChatMediaUploadPreview(
          items: [createItem(filePath: testImageFile.path)],
          onRemove: (_) {},
        ),
        tester,
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image).first);
      final context = tester.element(find.byType(Image).first);
      final fallback = image.errorBuilder!(context, Object(), StackTrace.empty);

      expect(fallback.key, const Key('image_tile_error_fallback'));
    });

    testWidgets('adjusts selectedIndex when items are removed', (tester) async {
      var currentItems = [
        createItem(filePath: testImageFile.path),
        createItem(filePath: testImageFile2.path),
      ];

      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setStateCallback) {
              setState = setStateCallback;
              return Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 500,
                  child: ChatMediaUploadPreview(
                    items: currentItems,
                    onRemove: (path) {
                      setState(() {
                        currentItems = currentItems.where((i) => i.filePath != path).toList();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('media_preview_thumbnail_1')));
      await tester.pump();

      setState(() {
        currentItems = [currentItems[0]];
      });
      await tester.pump();

      expect(find.byKey(const Key('chat_media_upload_preview')), findsOneWidget);
    });
  });
}
