import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_media_upload.dart' show MediaUploadItem, MediaUploadStatus;
import 'package:whitenoise/widgets/wn_media_upload_preview.dart';
import 'package:whitenoise/widgets/wn_spinner.dart';

import '../test_helpers.dart';

void main() {
  late Directory tempDir;
  late File testImageFile;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('media_preview_test');
    testImageFile = File('${tempDir.path}/test.jpg');
    testImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  MediaUploadItem createItem({
    required String filePath,
    MediaUploadStatus status = MediaUploadStatus.uploading,
    VoidCallback? retry,
  }) => (
    filePath: filePath,
    status: status,
    file: null,
    retry: retry,
  );

  group('WnMediaUploadPreview', () {
    testWidgets('displays add more button', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: const [],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('add_more_button')), findsOneWidget);
    });

    testWidgets('calls onAddMore when add button tapped', (tester) async {
      var addMoreCalled = false;
      await mountWidget(
        WnMediaUploadPreview(
          items: const [],
          onRemove: (_) {},
          onAddMore: () => addMoreCalled = true,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('add_more_button')));
      await tester.pump();

      expect(addMoreCalled, isTrue);
    });

    testWidgets('displays thumbnail for each item', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(Key('thumbnail_${testImageFile.path}')), findsOneWidget);
    });

    testWidgets('displays multiple thumbnails', (tester) async {
      final file1 = File('${tempDir.path}/test1.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
      final file2 = File('${tempDir.path}/test2.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: file1.path, status: MediaUploadStatus.uploaded),
            createItem(filePath: file2.path, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(Key('thumbnail_${file1.path}')), findsOneWidget);
      expect(find.byKey(Key('thumbnail_${file2.path}')), findsOneWidget);
    });

    testWidgets('shows spinner for uploading items', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('uploading_overlay')), findsOneWidget);
      expect(find.byType(WnSpinner), findsOneWidget);
    });

    testWidgets('does not show spinner for uploaded items', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('uploading_overlay')), findsNothing);
    });

    testWidgets('shows error overlay for error items', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path, status: MediaUploadStatus.error),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('error_overlay')), findsOneWidget);
    });

    testWidgets('tapping error overlay calls retry', (tester) async {
      var retryCalled = false;
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(
              filePath: testImageFile.path,
              status: MediaUploadStatus.error,
              retry: () => retryCalled = true,
            ),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('error_overlay')));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('shows error placeholder when image fails to load', (tester) async {
      final nonExistentPath = '${tempDir.path}/does_not_exist.jpg';

      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: nonExistentPath, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('thumbnail_error_placeholder')), findsOneWidget);
    });

    testWidgets('shows remove button on each thumbnail', (tester) async {
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (_) {},
          onAddMore: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('remove_button')), findsOneWidget);
    });

    testWidgets('calls onRemove with correct filePath when remove tapped', (tester) async {
      String? removedPath;
      await mountWidget(
        WnMediaUploadPreview(
          items: [
            createItem(filePath: testImageFile.path, status: MediaUploadStatus.uploaded),
          ],
          onRemove: (path) => removedPath = path,
          onAddMore: () {},
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('remove_button')));
      await tester.pump();

      expect(removedPath, testImageFile.path);
    });
  });
}
