import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/wn_message_media.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

MediaFile _mediaFile({
  String id = 'media1',
  String filePath = '',
  String? originalFileHash = 'hash123',
  String? blurhash,
}) => MediaFile(
  id: id,
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: filePath,
  originalFileHash: originalFileHash,
  encryptedFileHash: 'encrypted123',
  mimeType: 'image/jpeg',
  mediaType: 'image',
  blossomUrl: 'https://example.com/media',
  nostrKey: 'nostr123',
  createdAt: DateTime(2024),
  fileMetadata: blurhash != null ? FileMetadata(blurhash: blurhash) : null,
);

class _MockApi extends MockWnApi {
  Completer<MediaFile>? downloadCompleter;
  bool shouldFail = false;

  @override
  Future<MediaFile> crateApiMediaFilesDownloadChatMedia({
    required String accountPubkey,
    required String groupId,
    required String originalFileHash,
  }) async {
    if (shouldFail) throw Exception('Download failed');
    if (downloadCompleter != null) return downloadCompleter!.future;
    return _mediaFile(filePath: '/downloaded/path.jpg');
  }
}

final _api = _MockApi();

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

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.downloadCompleter = null;
    _api.shouldFail = false;
  });

  group('ChatMessageMedia', () {
    testWidgets('creates a tile for each media file', (tester) async {
      _api.shouldFail = true;
      await mountWidget(
        ChatMessageMedia(
          mediaFiles: [
            _mediaFile(id: '1'),
            _mediaFile(id: '2'),
            _mediaFile(id: '3'),
          ],
        ),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_placeholder')), findsNWidgets(3));
    });

    testWidgets('delegates to WnMessageMedia', (tester) async {
      await mountWidget(
        ChatMessageMedia(mediaFiles: [_mediaFile()]),
        tester,
      );

      expect(find.byType(WnMessageMedia), findsOneWidget);
    });

    testWidgets('passes onMediaTap as onTileTap', (tester) async {
      await mountWidget(
        ChatMessageMedia(
          mediaFiles: [_mediaFile()],
          onMediaTap: (_) {},
        ),
        tester,
      );

      final mediaWidget = tester.widget<WnMessageMedia>(find.byType(WnMessageMedia));
      expect(mediaWidget.onTileTap, isNotNull);
    });

    testWidgets('renders empty when mediaFiles is empty', (tester) async {
      await mountWidget(
        const ChatMessageMedia(mediaFiles: []),
        tester,
      );

      expect(find.byKey(const Key('error_placeholder')), findsNothing);
      expect(find.byKey(const Key('loading_placeholder')), findsNothing);
      expect(find.byKey(const Key('media_image')), findsNothing);
    });

    testWidgets('shows error placeholder when download fails', (tester) async {
      _api.shouldFail = true;
      await mountWidget(
        ChatMessageMedia(mediaFiles: [_mediaFile()]),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('media_image')), findsNothing);
    });

    testWidgets('shows error when originalFileHash is null', (tester) async {
      await mountWidget(
        ChatMessageMedia(mediaFiles: [_mediaFile(originalFileHash: null)]),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_placeholder')), findsOneWidget);
    });

    testWidgets('shows loading placeholder while downloading', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      await mountWidget(
        ChatMessageMedia(mediaFiles: [_mediaFile()]),
        tester,
      );

      expect(find.byKey(const Key('loading_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('media_image')), findsNothing);
    });

    testWidgets('shows image with fade transition on success', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('chat_media_test');
      final tempFile = File('${tempDir.path}/test.png');
      tempFile.writeAsBytesSync(_minimalPng);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await mountWidget(
        ChatMessageMedia(mediaFiles: [_mediaFile(filePath: tempFile.path)]),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fade_transition')), findsOneWidget);
      expect(find.byKey(const Key('media_image')), findsOneWidget);
    });

    testWidgets('shows blurhash placeholder when blurhash provided', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      await mountWidget(
        ChatMessageMedia(
          mediaFiles: [_mediaFile(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj')],
        ),
        tester,
      );

      expect(find.byKey(const Key('blurhash_placeholder')), findsOneWidget);
    });

    testWidgets('placeholder and image have the same size', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('chat_media_size_test');
      final tempFile = File('${tempDir.path}/test.png');
      tempFile.writeAsBytesSync(_minimalPng);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final completer = Completer<MediaFile>();
      _api.downloadCompleter = completer;

      await mountWidget(
        ChatMessageMedia(
          mediaFiles: [
            _mediaFile(
              blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
            ),
          ],
        ),
        tester,
      );

      final placeholderSize = tester
          .renderObject<RenderBox>(find.byKey(const Key('blurhash_placeholder')))
          .size;

      completer.complete(_mediaFile(filePath: tempFile.path));
      await tester.pumpAndSettle();

      final imageSize = tester.renderObject<RenderBox>(find.byKey(const Key('media_image'))).size;

      expect(imageSize, placeholderSize);
    });
  });
}
