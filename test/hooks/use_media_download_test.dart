import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

MediaFile _mediaFile({
  String id = 'media1',
  String filePath = '',
  String? originalFileHash = 'hash123',
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
);

class _MockApi extends MockWnApi {
  Completer<MediaFile>? downloadCompleter;
  bool shouldFail = false;
  String? lastDownloadedHash;

  @override
  Future<MediaFile> crateApiMediaFilesDownloadChatMedia({
    required String accountPubkey,
    required String groupId,
    required String originalFileHash,
  }) async {
    lastDownloadedHash = originalFileHash;
    if (shouldFail) {
      throw Exception('Download failed');
    }
    if (downloadCompleter != null) {
      return downloadCompleter!.future;
    }
    return _mediaFile(filePath: '/downloaded/path.jpg');
  }

  @override
  void reset() {
    downloadCompleter = null;
    shouldFail = false;
    lastDownloadedHash = null;
  }
}

final _api = _MockApi();

Future<MediaDownloadResult Function()> _pump(
  WidgetTester tester,
  MediaFile mediaFile,
) async {
  return await mountHook(tester, () => useMediaDownload(mediaFile: mediaFile));
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() => _api.reset());

  group('useMediaDownload', () {
    testWidgets('starts in loading state', (tester) async {
      _api.downloadCompleter = Completer<MediaFile>();
      final getResult = await _pump(tester, _mediaFile());

      expect(getResult().status, MediaDownloadStatus.loading);
      expect(getResult().localPath, isNull);
      expect(getResult().retry, isNull);
    });

    testWidgets('returns success immediately if file exists locally', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('media_test');
      final tempFile = File('${tempDir.path}/existing.jpg');
      tempFile.writeAsStringSync('test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final mediaFile = _mediaFile(filePath: tempFile.path);
      final getResult = await _pump(tester, mediaFile);
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.success);
      expect(getResult().localPath, tempFile.path);
      expect(getResult().retry, isNull);
    });

    testWidgets('downloads file when filePath is empty', (tester) async {
      final getResult = await _pump(tester, _mediaFile());
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.success);
      expect(getResult().localPath, '/downloaded/path.jpg');
      expect(_api.lastDownloadedHash, 'hash123');
    });

    testWidgets('returns error when originalFileHash is null', (tester) async {
      final getResult = await _pump(tester, _mediaFile(originalFileHash: null));
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.error);
      expect(getResult().retry, isNotNull);
    });

    testWidgets('returns error when download fails', (tester) async {
      _api.shouldFail = true;
      final getResult = await _pump(tester, _mediaFile());
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.error);
      expect(getResult().retry, isNotNull);
    });

    testWidgets('retry resets to loading and re-downloads', (tester) async {
      _api.shouldFail = true;
      final getResult = await _pump(tester, _mediaFile());
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.error);

      _api.shouldFail = false;
      _api.downloadCompleter = Completer<MediaFile>();

      getResult().retry!();
      await tester.pump();

      expect(getResult().status, MediaDownloadStatus.loading);

      _api.downloadCompleter!.complete(_mediaFile(filePath: '/retry/path.jpg'));
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.success);
      expect(getResult().localPath, '/retry/path.jpg');
    });

    testWidgets('does not provide retry callback when not in error state', (tester) async {
      final getResult = await _pump(tester, _mediaFile());
      await tester.pumpAndSettle();

      expect(getResult().status, MediaDownloadStatus.success);
      expect(getResult().retry, isNull);
    });
  });
}
