import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/media_video.dart';

import '../fakes/fake_video_player_platform.dart';
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
  mimeType: 'video/mp4',
  mediaType: 'video',
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
    return _mediaFile(filePath: '/downloaded/path.mp4');
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.downloadCompleter = null;
    _api.shouldFail = false;
  });

  group('MediaVideo', () {
    testWidgets('shows loading placeholder while downloading', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();

      await mountWidget(
        MediaVideo(
          mediaFile: _mediaFile(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
        tester,
      );

      expect(find.byKey(const Key('media_video_loading')), findsOneWidget);
      expect(find.byKey(const Key('blurhash_placeholder')), findsOneWidget);
    });

    testWidgets('shows error placeholder when download fails', (tester) async {
      _api.shouldFail = true;

      await mountWidget(
        MediaVideo(mediaFile: _mediaFile()),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_video_error')), findsOneWidget);
      expect(find.byKey(const Key('media_video_player')), findsNothing);
    });

    testWidgets('shows local video player when file exists locally', (tester) async {
      setUpFakeVideoPlayerPlatform();
      final tempDir = Directory.systemTemp.createTempSync('media_video_test');
      final tempFile = File('${tempDir.path}/test.mp4');
      tempFile.writeAsBytesSync([0, 0, 0, 0]);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await mountWidget(
        MediaVideo(mediaFile: _mediaFile(filePath: tempFile.path)),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media_video_player')), findsOneWidget);
      expect(find.byKey(const Key('video_player')), findsOneWidget);
    });
  });
}
