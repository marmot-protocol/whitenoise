import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/media_image.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/media_video.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_share_plus.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

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

Future<void> _openModal(WidgetTester tester, List<MediaFile> files) async {
  await mountWidget(
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => MediaModal.show(
          context: context,
          mediaFiles: files,
        ),
        child: const Text('Open'),
      ),
    ),
    tester,
  );

  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

File _writeTempPng(String prefix) {
  final dir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/test.png')..writeAsBytesSync(Uint8List.fromList(_minimalPng));
}

File _writeTempVideo(String prefix) {
  final dir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/test.mp4')..writeAsBytesSync([0]);
}

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('MediaModal', () {
    tearDown(clearSharePlusMock);

    testWidgets('renders overlay background', (tester) async {
      await _openModal(tester, [_mediaFile('1')]);

      expect(find.byType(WnOverlay), findsOneWidget);
    });

    testWidgets('renders modal with single media', (tester) async {
      await _openModal(tester, [_mediaFile('1')]);

      expect(find.byKey(const Key('media_page_view')), findsOneWidget);
      expect(find.byKey(const Key('media_modal_slate')), findsOneWidget);
      expect(find.byKey(const Key('media_thumbnail_strip')), findsNothing);
    });

    testWidgets('renders video media with video viewer', (tester) async {
      await _openModal(tester, [
        _mediaFile('1', mimeType: 'video/mp4', mediaType: 'video'),
      ]);

      expect(find.byType(MediaVideo), findsOneWidget);
      expect(find.byKey(const Key('media_image_0')), findsNothing);
    });

    testWidgets('renders thumbnail strip for multiple media', (tester) async {
      await _openModal(tester, [_mediaFile('1'), _mediaFile('2'), _mediaFile('3')]);

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
      await _openModal(tester, [_mediaFile('1')]);
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
      await _openModal(tester, [_mediaFile('1')]);
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
      await _openModal(tester, [_mediaFile('1'), _mediaFile('2'), _mediaFile('3')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('thumbnail_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_2')), findsOneWidget);
    });

    testWidgets('shows error placeholder for media with empty filePath', (tester) async {
      await _openModal(tester, [
        _mediaFile('1', blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
      ]);
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
      await _openModal(tester, [_mediaFile('1')]);
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

    testWidgets('wraps share button in AspectRatio when image has dimensions', (tester) async {
      await _openModal(tester, [_mediaFile('1', dimensions: '1600x900')]);
      await tester.pumpAndSettle();

      final aspectRatio = tester.widget<AspectRatio>(
        find
            .ancestor(
              of: find.byKey(const Key('media_modal_share_button_0')),
              matching: find.byType(AspectRatio),
            )
            .first,
      );
      expect(aspectRatio.aspectRatio, 1600 / 900);
    });

    testWidgets('does not wrap share button in AspectRatio when image has no dimensions', (
      tester,
    ) async {
      await _openModal(tester, [_mediaFile('1')]);
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byKey(const Key('media_modal_share_button_0')),
          matching: find.byType(AspectRatio),
        ),
        findsNothing,
      );
    });

    testWidgets('page view uses NeverScrollableScrollPhysics when zoomed', (tester) async {
      await _openModal(tester, [_mediaFile('1'), _mediaFile('2')]);
      await tester.pumpAndSettle();

      final mediaImage = tester.widget<MediaImage>(find.byKey(const Key('media_image_0')));
      mediaImage.onZoomChanged?.call(true);
      await tester.pump();

      final pageView = tester.widget<PageView>(find.byKey(const Key('media_page_view')));
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('share button is disabled when media is not downloaded', (tester) async {
      await _openModal(tester, [_mediaFile('share_d1')]);

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_share_button_0')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('share button is enabled when media is downloaded', (tester) async {
      final file = _writeTempPng('mm_share_enabled');

      await _openModal(tester, [_mediaFile('share_e1', filePath: file.path)]);

      final button = tester.widget<WnIconButton>(
        find.byKey(const Key('media_modal_share_button_0')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping share button invokes SharePlus', (tester) async {
      final calls = mockSharePlus();
      final file = _writeTempPng('mm_share_tap');

      await _openModal(tester, [_mediaFile('share_t1', filePath: file.path)]);

      await tester.tap(find.byKey(const Key('media_modal_share_button_0')));
      await tester.pumpAndSettle();

      expect(calls, isNotEmpty);
    });

    testWidgets('long press invokes SharePlus when media is downloaded', (tester) async {
      final calls = mockSharePlus();
      final file = _writeTempPng('mm_lp_share');

      await _openModal(tester, [_mediaFile('lp_share_1', filePath: file.path)]);

      await tester.longPress(find.byKey(const Key('media_content_tap_area')));
      await tester.pumpAndSettle();

      expect(calls, isNotEmpty);
    });

    testWidgets('long press is disabled when media is not downloaded', (tester) async {
      await _openModal(tester, [_mediaFile('lp_d1')]);

      final gestureDetector = tester.widget<GestureDetector>(
        find.byKey(const Key('media_content_tap_area')),
      );
      expect(gestureDetector.onLongPress, isNull);
    });

    testWidgets('share failure shows error notice inside the slate', (tester) async {
      mockSharePlusFailing();
      final file = _writeTempPng('mm_share_err');

      await _openModal(tester, [_mediaFile('share_err_1', filePath: file.path)]);

      await tester.tap(find.byKey(const Key('media_modal_share_button_0')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('media_modal_slate')),
          matching: find.byType(WnSystemNotice),
        ),
        findsOneWidget,
      );
      expect(find.text('Failed to share'), findsOneWidget);
    });

    testWidgets('shows share button for video media', (tester) async {
      await _openModal(tester, [
        _mediaFile('vid_btn_1', mimeType: 'video/mp4', mediaType: 'video'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_share_button_0')), findsOneWidget);
    });

    testWidgets('video share button invokes SharePlus when media is downloaded', (tester) async {
      final calls = mockSharePlus();
      final file = _writeTempVideo('mm_vid_share');

      await _openModal(tester, [
        _mediaFile(
          'vid_share_1',
          filePath: file.path,
          mimeType: 'video/mp4',
          mediaType: 'video',
        ),
      ]);

      await tester.tap(find.byKey(const Key('media_modal_share_button_0')));
      await tester.pumpAndSettle();

      expect(calls, isNotEmpty);
    });

    testWidgets('share button is overlaid on the video player', (tester) async {
      await _openModal(tester, [
        _mediaFile('vid_ar_1', mimeType: 'video/mp4', mediaType: 'video'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_modal_share_button_0')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MediaVideo),
          matching: find.byKey(const Key('media_modal_share_button_0')),
        ),
        findsOneWidget,
      );
    });
  });
}
