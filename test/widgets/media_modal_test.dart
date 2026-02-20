import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/media_image.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

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
  });
}
