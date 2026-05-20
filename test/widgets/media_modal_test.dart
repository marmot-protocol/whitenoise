import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:gal/src/gal_platform_interface.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/media_image.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/media_video.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
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

base class _VideoSuccessGalPlatform extends GalPlatform {
  @override
  Future<void> putVideo(String path, {String? album}) async {}
}

base class _VideoErrorGalPlatform extends GalPlatform {
  final GalExceptionType type;
  _VideoErrorGalPlatform(this.type);

  @override
  Future<void> putVideo(String path, {String? album}) async {
    throw GalException(
      type: type,
      platformException: PlatformException(code: type.code),
      stackTrace: StackTrace.current,
    );
  }
}

MediaFile _mediaFile(
  String id, {
  String filePath = '',
  String? blurhash,
  String? dimensions,
  String mimeType = 'image/jpeg',
  String mediaType = 'image',
}) => MediaFile(
  id: id,
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: filePath,
  originalFileHash: 'hash$id',
  encryptedFileHash: 'encrypted$id',
  mimeType: mimeType,
  mediaType: mediaType,
  blossomUrl: 'https://example.com/$id',
  nostrKey: 'nostr$id',
  createdAt: DateTime(2024),
  fileMetadata: (blurhash != null || dimensions != null)
      ? FileMetadata(blurhash: blurhash, dimensions: dimensions)
      : null,
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

  await tester.tap(find.byKey(const Key('media_modal_download_button_0')));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _openAndLongPress(
  WidgetTester tester,
  String filePath,
  String id, {
  bool tapSave = true,
}) async {
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

  await tester.longPress(find.byKey(const Key('media_content_tap_area')));
  await tester.pump();
  await tester.pump();
  await tester.pump();

  if (tapSave) {
    await tester.tap(find.byKey(const Key('media_action_save')));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

Future<void> _openAndTapDownloadVideo(
  WidgetTester tester,
  String filePath,
  String id,
) async {
  await mountWidget(
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => MediaModal.show(
          context: context,
          mediaFiles: [
            _mediaFile(id, filePath: filePath, mimeType: 'video/mp4', mediaType: 'video'),
          ],
        ),
        child: const Text('Open'),
      ),
    ),
    tester,
  );

  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(find.byKey(const Key('media_modal_download_button_0')));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _openAndLongPressVideo(
  WidgetTester tester,
  String filePath,
  String id, {
  bool tapSave = true,
}) async {
  await mountWidget(
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => MediaModal.show(
          context: context,
          mediaFiles: [
            _mediaFile(id, filePath: filePath, mimeType: 'video/mp4', mediaType: 'video'),
          ],
        ),
        child: const Text('Open'),
      ),
    ),
    tester,
  );

  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  await tester.longPress(find.byKey(const Key('media_content_tap_area')));
  await tester.pump();
  await tester.pump();
  await tester.pump();

  if (tapSave) {
    await tester.tap(find.byKey(const Key('media_action_save')));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('MediaModal', () {
    late GalPlatform galPlatform;

    setUp(() {
      galPlatform = GalPlatform.instance;
    });

    tearDown(() {
      GalPlatform.instance = galPlatform;
    });

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

    testWidgets('renders video media with video viewer', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [
                _mediaFile(
                  '1',
                  mimeType: 'video/mp4',
                  mediaType: 'video',
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(MediaVideo), findsOneWidget);
      expect(find.byKey(const Key('media_image_0')), findsNothing);
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

    testWidgets('wraps download button in AspectRatio when image has dimensions', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('1', dimensions: '1600x900')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final aspectRatio = tester.widget<AspectRatio>(
        find
            .ancestor(
              of: find.byKey(const Key('media_modal_download_button_0')),
              matching: find.byType(AspectRatio),
            )
            .first,
      );
      expect(aspectRatio.aspectRatio, 1600 / 900);
    });

    testWidgets('does not wrap download button in AspectRatio when image has no dimensions', (
      tester,
    ) async {
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

      expect(
        find.ancestor(
          of: find.byKey(const Key('media_modal_download_button_0')),
          matching: find.byType(AspectRatio),
        ),
        findsNothing,
      );
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

    testWidgets('shows checkmark on download button after saving to gallery', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_checkmark');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_c1');

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.checkmark);
    });

    testWidgets('checkmark reverts to download icon after timeout', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_revert');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_c2');

      var button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.checkmark);

      await tester.pump(const Duration(seconds: 2));

      button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.download);
    });

    testWidgets('download button re-enables after save so image can be saved multiple times', (
      tester,
    ) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_reenable');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'save_r1');

      await tester.pump(const Duration(seconds: 2));

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('media_modal_download_button_0')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('long press saves to gallery successfully', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_lp_success');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndLongPress(tester, file.path, 'lp_s1');

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.checkmark);
    });

    testWidgets('long press shows error notice when save fails', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);
      final dir = Directory.systemTemp.createTempSync('mm_lp_error');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndLongPress(tester, file.path, 'lp_e1');

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Permission denied to save image'), findsOneWidget);
    });

    testWidgets('long press shows action chooser with save and share', (tester) async {
      final dir = Directory.systemTemp.createTempSync('mm_lp_chooser');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndLongPress(tester, file.path, 'lp_chooser_1', tapSave: false);

      expect(find.byKey(const Key('media_action_save')), findsOneWidget);
      expect(find.byKey(const Key('media_action_share')), findsOneWidget);
    });

    testWidgets('long press is disabled when media is not downloaded', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [_mediaFile('lp_d1')],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final gestureDetector = tester.widget<GestureDetector>(
        find.byKey(const Key('media_content_tap_area')),
      );
      expect(gestureDetector.onLongPress, isNull);
    });

    testWidgets('shows download button for video media', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [
                _mediaFile('vid_btn_1', mimeType: 'video/mp4', mediaType: 'video'),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_download_button_0')), findsOneWidget);
    });

    testWidgets('video download button saves to gallery successfully', (tester) async {
      GalPlatform.instance = _VideoSuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_vid_success');
      final file = File('${dir.path}/test.mp4')..writeAsBytesSync([0]);
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownloadVideo(tester, file.path, 'vid_dl_s1');

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.checkmark);
    });

    testWidgets('video long press saves to gallery successfully', (tester) async {
      GalPlatform.instance = _VideoSuccessGalPlatform();
      final dir = Directory.systemTemp.createTempSync('mm_vid_lp_success');
      final file = File('${dir.path}/test.mp4')..writeAsBytesSync([0]);
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndLongPressVideo(tester, file.path, 'vid_lp_s1');

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_download_button_0')),
      );
      expect(button.icon, WnIcons.checkmark);
    });

    testWidgets('video long press shows error notice when save fails', (tester) async {
      GalPlatform.instance = _VideoErrorGalPlatform(GalExceptionType.accessDenied);
      final dir = Directory.systemTemp.createTempSync('mm_vid_lp_err');
      final file = File('${dir.path}/test.mp4')..writeAsBytesSync([0]);
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndLongPressVideo(tester, file.path, 'vid_lp_e1');

      expect(find.byType(WnSystemNotice), findsOneWidget);
    });

    testWidgets('system notice for errors is rendered inside the slate', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);
      final dir = Directory.systemTemp.createTempSync('mm_notice_slate');
      final file = File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
      addTearDown(() => dir.deleteSync(recursive: true));

      await _openAndTapDownload(tester, file.path, 'notice_slate_1');

      expect(
        find.descendant(
          of: find.byKey(const Key('media_modal_slate')),
          matching: find.byType(WnSystemNotice),
        ),
        findsOneWidget,
      );
    });

    testWidgets('video download button is overlaid on the video player', (tester) async {
      await mountWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => MediaModal.show(
              context: context,
              mediaFiles: [
                _mediaFile('vid_ar_1', mimeType: 'video/mp4', mediaType: 'video'),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
        tester,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_download_button_0')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MediaVideo),
          matching: find.byKey(const Key('media_modal_download_button_0')),
        ),
        findsOneWidget,
      );
    });
  });
}
