import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/src/gal_exception.dart';
import 'package:gal/src/gal_platform_interface.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/media_image.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

base class _SuccessGalPlatform extends GalPlatform {
  @override
  Future<void> putImage(String path, {String? album}) async {}
}

base class _ErrorGalPlatform extends GalPlatform {
  final GalExceptionType type;
  _ErrorGalPlatform(this.type);

  @override
  Future<void> putImage(String path, {String? album}) async {
    throw GalException(
      type: type,
      platformException: PlatformException(code: type.code),
      stackTrace: StackTrace.current,
    );
  }
}

base class _GenericErrorGalPlatform extends GalPlatform {
  @override
  Future<void> putImage(String path, {String? album}) async {
    throw Exception('Generic error');
  }
}

MediaFile _mediaFile(String id, {String filePath = '', String? blurhash}) => MediaFile(
  id: id,
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: filePath,
  originalFileHash: 'hash$id',
  encryptedFileHash: 'encrypted$id',
  mimeType: 'image/jpeg',
  mediaType: 'image',
  blossomUrl: 'https://example.com/$id',
  nostrKey: 'nostr$id',
  createdAt: DateTime(2024),
  fileMetadata: blurhash != null ? FileMetadata(blurhash: blurhash) : null,
);

// Minimal valid 1x1 PNG. Required because Image.file with invalid bytes
// causes the native image codec to hang the test pump loop.
const _minimalPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE2,
  0x21,
  0xBC,
  0x33,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

// Opens the modal with a file-backed MediaFile and taps the download button.
// Three pumps after the tap are required because:
//   1. First pump: Gal.putImage microtask resolves, status changes, useEffect
//      fires addPostFrameCallback for onSaveSuccess/onSaveError.
//   2. Second pump: postFrameCallback runs, MediaModal hook state updates.
//   3. Third pump: MediaModal rebuilds and the WnSystemNotice becomes visible.
Future<void> _openAndTapDownload(
  WidgetTester tester,
  String filePath,
  String id,
) async {
  await mountWidget(
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => MediaModal.show(
          context: context,
          mediaFiles: [_mediaFile(id, filePath: filePath)],
        ),
        child: const Text('Open'),
      ),
    ),
    tester,
  );

  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.byKey(const Key('media_modal_download_button')));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('MediaModal', () {
    testWidgets('renders overlay background', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(WnOverlay), findsOneWidget);
    });

    testWidgets('renders modal with single media', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_page_view')), findsOneWidget);
      expect(find.byKey(const Key('media_modal_slate')), findsOneWidget);
      expect(find.byKey(const Key('media_thumbnail_strip')), findsNothing);
    });

    testWidgets('renders thumbnail strip for multiple media', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1'), _mediaFile('2'), _mediaFile('3')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_thumbnail_strip')), findsOneWidget);
      expect(find.byKey(const Key('thumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('thumbnail_1')), findsOneWidget);
      expect(find.byKey(const Key('thumbnail_2')), findsOneWidget);
    });

    testWidgets('displays sender name when provided', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
              senderName: 'Alice',
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_sender_name')), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays localized unknown user when no sender name', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Unknown user'), findsOneWidget);
    });

    testWidgets('displays relative timestamp when provided', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
              timestamp: DateTime.now(),
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_timestamp')), findsOneWidget);
      expect(find.text('just now'), findsOneWidget);
    });

    testWidgets('close button pops modal', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_slate')), findsOneWidget);

      await tester.tap(find.byKey(const Key('media_modal_close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_slate')), findsNothing);
    });

    testWidgets('starts at initialIndex', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1'), _mediaFile('2'), _mediaFile('3')],
              initialIndex: 1,
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_1')), findsOneWidget);
    });

    testWidgets('tapping thumbnail navigates to that image', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1'), _mediaFile('2'), _mediaFile('3')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('thumbnail_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_2')), findsOneWidget);
    });

    testWidgets('shows error placeholder for media with empty filePath', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [
                _mediaFile('1', blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_error')), findsOneWidget);
      expect(find.byKey(const Key('media_image_viewer')), findsNothing);
    });

    testWidgets('avatar uses color from senderPubkey', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
              senderPubkey: testPubkeyA,
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.fromPubkey(testPubkeyA));
    });

    testWidgets('avatar uses neutral color when senderPubkey is null', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.neutral);
    });

    testWidgets('tapping content toggles fullscreen and hides header', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1')],
              senderName: 'Alice',
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_sender_name')), findsOneWidget);

      final tapArea = tester.widget<GestureDetector>(
        find.byKey(const Key('media_content_tap_area')),
      );
      tapArea.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_sender_name')), findsNothing);
    });

    testWidgets('page view uses NeverScrollableScrollPhysics when zoomed', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1'), _mediaFile('2')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final mediaImage = tester.widget<MediaImage>(find.byKey(const Key('media_image_0')));
      mediaImage.onZoomChanged?.call(true);
      await tester.pump();

      final pageView = tester.widget<PageView>(find.byKey(const Key('media_page_view')));
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('shows success system notice after saving to gallery', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_success');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_s1');

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Image saved to gallery'), findsOneWidget);
    });

    testWidgets('shows error system notice when gallery save fails with permission denied', (
      tester,
    ) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);
      final dir = Directory.systemTemp.createTempSync('mm_access');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_e1');

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Permission denied to save image'), findsOneWidget);
    });

    testWidgets('shows error system notice when gallery save fails with not enough space', (
      tester,
    ) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.notEnoughSpace);
      final dir = Directory.systemTemp.createTempSync('mm_space');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_e2');

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Not enough storage space'), findsOneWidget);
    });

    testWidgets('shows error system notice when gallery save fails with unsupported format', (
      tester,
    ) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.notSupportedFormat);
      final dir = Directory.systemTemp.createTempSync('mm_format');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_e3');

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Image format not supported'), findsOneWidget);
    });

    testWidgets(
      'shows error system notice when gallery save fails with unexpected GalException',
      (tester) async {
        GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.unexpected);
        final dir = Directory.systemTemp.createTempSync('mm_unexpected');
        final file = File('${dir.path}/test.png')
          ..writeAsBytesSync(Uint8List.fromList(_minimalPng));
        addTearDown(() => dir.deleteSync(recursive: true));

        await _openAndTapDownload(tester, file.path, 'save_e4');

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to save image to gallery'), findsOneWidget);
      },
    );

    testWidgets(
      'shows error system notice when gallery save fails with generic exception',
      (tester) async {
        GalPlatform.instance = _GenericErrorGalPlatform();
        final dir = Directory.systemTemp.createTempSync('mm_generic');
        final file = File('${dir.path}/test.png')
          ..writeAsBytesSync(Uint8List.fromList(_minimalPng));
        addTearDown(() => dir.deleteSync(recursive: true));

        await _openAndTapDownload(tester, file.path, 'save_e5');

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to save image to gallery'), findsOneWidget);
      },
    );

    testWidgets('success notice auto-dismisses after timeout', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_dismiss');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_d1');

      expect(find.byType(WnSystemNotice), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(WnSystemNotice), findsNothing);
    });

    testWidgets('download button re-enables after save so image can be saved multiple times', (
      tester,
    ) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_reenable');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_r1');

      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('media_modal_download_button')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
