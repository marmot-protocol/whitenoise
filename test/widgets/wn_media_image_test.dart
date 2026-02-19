import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_media_image.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

MediaFile _mediaFile({
  String id = 'media1',
  String filePath = '',
  String? originalFileHash = 'hash123',
  String? blurhash,
  String? dimensions,
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
  fileMetadata: blurhash != null || dimensions != null
      ? FileMetadata(blurhash: blurhash, dimensions: dimensions)
      : null,
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

  void resetDownload() {
    downloadCompleter = null;
    shouldFail = false;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.resetDownload());

  group('WnMediaImage', () {
    testWidgets('shows blurhash placeholder while loading', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      await mountWidget(
        WnMediaImage(
          mediaFile: _mediaFile(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
        tester,
      );

      expect(find.byKey(const Key('media_image_loading')), findsOneWidget);
      expect(find.byKey(const Key('media_image_viewer')), findsNothing);
      expect(find.byKey(const Key('media_image_error')), findsNothing);
    });

    testWidgets('shows error placeholder when download fails', (tester) async {
      _api.shouldFail = true;
      await mountWidget(
        WnMediaImage(mediaFile: _mediaFile()),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_error')), findsOneWidget);
      expect(find.byKey(const Key('media_image_viewer')), findsNothing);
    });

    testWidgets('shows error when originalFileHash is null', (tester) async {
      await mountWidget(
        WnMediaImage(mediaFile: _mediaFile(originalFileHash: null)),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_image_error')), findsOneWidget);
    });

    testWidgets('shows image viewer with fade transition when file exists locally', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('media_image_test');
      final tempFile = File('${tempDir.path}/test.png');
      tempFile.writeAsBytesSync(_minimalPng);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await mountWidget(
        WnMediaImage(mediaFile: _mediaFile(filePath: tempFile.path)),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fade_transition')), findsOneWidget);
      expect(find.byKey(const Key('media_image_viewer')), findsOneWidget);
      expect(find.byKey(const Key('media_image_file')), findsOneWidget);
    });

    testWidgets('fade transition animates from 0 to 1', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      final tempDir = Directory.systemTemp.createTempSync('media_image_fade_test');
      final tempFile = File('${tempDir.path}/test.png');
      tempFile.writeAsBytesSync(_minimalPng);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await mountWidget(
        WnMediaImage(
          mediaFile: _mediaFile(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        ),
        tester,
      );

      expect(find.byKey(const Key('fade_transition')), findsNothing);

      _api.downloadCompleter!.complete(
        _mediaFile(filePath: tempFile.path),
      );
      await tester.pump();
      await tester.pump();

      final fadeTransition = tester.widget<FadeTransition>(
        find.byKey(const Key('fade_transition')),
      );
      expect(fadeTransition.opacity.value, lessThan(1.0));

      await tester.pumpAndSettle();

      final completedFade = tester.widget<FadeTransition>(
        find.byKey(const Key('fade_transition')),
      );
      expect(completedFade.opacity.value, equals(1.0));
    });

    testWidgets('calls onTap callback', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      var tapped = false;
      await mountWidget(
        WnMediaImage(
          mediaFile: _mediaFile(),
          onTap: () => tapped = true,
        ),
        tester,
      );

      await tester.tap(find.byType(WnMediaImage));
      expect(tapped, isTrue);
    });

    testWidgets('constrains blurhash to image aspect ratio when dimensions available', (
      tester,
    ) async {
      _api.downloadCompleter = Completer<MediaFile>();
      await mountWidget(
        WnMediaImage(
          mediaFile: _mediaFile(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
            dimensions: '1920x1080',
          ),
        ),
        tester,
      );

      expect(find.byKey(const Key('media_image_loading')), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, closeTo(16 / 9, 0.01));
    });

    testWidgets('fills available space when dimensions not available', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      await mountWidget(
        WnMediaImage(
          mediaFile: _mediaFile(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
        tester,
      );

      expect(find.byKey(const Key('media_image_loading')), findsOneWidget);
      expect(find.byType(AspectRatio), findsNothing);
    });
  });
}

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
