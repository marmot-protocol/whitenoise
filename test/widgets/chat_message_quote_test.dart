import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPngBytes = [
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
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
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
  MediaFile? downloadedMediaFile;

  @override
  Future<MediaFile> crateApiMediaFilesDownloadChatMedia({
    required String accountPubkey,
    required String groupId,
    required String originalFileHash,
  }) async {
    if (shouldFail) {
      throw Exception('Download failed');
    }
    if (downloadCompleter != null) {
      return downloadCompleter!.future;
    }
    return downloadedMediaFile ?? _mediaFile(filePath: '/downloaded/path.jpg');
  }
}

final _api = _MockApi();

ChatMessageQuoteData _quoteData({
  String messageId = 'test-message-id',
  String authorPubkey = testPubkeyA,
  FlutterMetadata? authorMetadata,
  String content = 'Quote content',
  MediaFile? mediaFile,
  bool isNotFound = false,
}) => (
  messageId: messageId,
  authorPubkey: authorPubkey,
  authorMetadata: authorMetadata,
  content: content,
  mediaFile: mediaFile,
  isNotFound: isNotFound,
);

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.downloadCompleter = null;
    _api.shouldFail = false;
    _api.downloadedMediaFile = null;
  });

  group('ChatMessageQuote', () {
    testWidgets('renders author displayName from authorMetadata when present', (tester) async {
      await mountWidget(
        ChatMessageQuote(
          data: _quoteData(
            authorMetadata: const FlutterMetadata(displayName: 'Test Author', custom: {}),
          ),
        ),
        tester,
      );

      expect(find.text('Test Author'), findsOneWidget);
    });

    testWidgets('renders author name from authorMetadata when displayName is null', (tester) async {
      await mountWidget(
        ChatMessageQuote(
          data: _quoteData(
            authorMetadata: const FlutterMetadata(name: 'Fallback Name', custom: {}),
          ),
        ),
        tester,
      );

      expect(find.text('Fallback Name'), findsOneWidget);
    });

    testWidgets('renders unknown user when authorMetadata is null', (tester) async {
      await mountWidget(
        ChatMessageQuote(data: _quoteData()),
        tester,
      );

      expect(find.text('Unknown user'), findsOneWidget);
    });

    testWidgets('renders You when currentUserPubkey equals authorPubkey', (tester) async {
      await mountWidget(
        ChatMessageQuote(
          data: _quoteData(),
          currentUserPubkey: testPubkeyA,
        ),
        tester,
      );

      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders Unknown user when isNotFound', (tester) async {
      await mountWidget(
        ChatMessageQuote(data: _quoteData(content: 'ignored', isNotFound: true)),
        tester,
      );

      expect(find.text('Unknown user'), findsOneWidget);
    });

    testWidgets('renders Message not found when isNotFound', (tester) async {
      await mountWidget(
        ChatMessageQuote(data: _quoteData(content: 'ignored', isNotFound: true)),
        tester,
      );

      expect(find.text('Message not found'), findsOneWidget);
    });

    testWidgets('renders content when not isNotFound', (tester) async {
      await mountWidget(
        ChatMessageQuote(data: _quoteData(content: 'This is the quote content')),
        tester,
      );

      expect(find.text('This is the quote content'), findsOneWidget);
    });

    testWidgets('shows cancel button when onCancel is provided', (tester) async {
      await mountWidget(
        ChatMessageQuote(
          data: _quoteData(),
          onCancel: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('cancel_quote_button')), findsOneWidget);
    });

    testWidgets('hides cancel button when onCancel is null', (tester) async {
      await mountWidget(
        ChatMessageQuote(data: _quoteData()),
        tester,
      );

      expect(find.byKey(const Key('cancel_quote_button')), findsNothing);
    });

    testWidgets('calls onCancel when cancel button is tapped', (tester) async {
      var cancelCalled = false;
      await mountWidget(
        ChatMessageQuote(
          data: _quoteData(),
          onCancel: () => cancelCalled = true,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('cancel_quote_button')));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    group('onTap', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapCalled = false;
        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(),
            onTap: () => tapCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('message_quote_tap_area')));
        await tester.pumpAndSettle();

        expect(tapCalled, isTrue);
      });

      testWidgets('no tap area key when onTap is null', (tester) async {
        await mountWidget(
          ChatMessageQuote(data: _quoteData()),
          tester,
        );

        expect(find.byKey(const Key('message_quote_tap_area')), findsNothing);
      });

      testWidgets('works with both onTap and onCancel', (tester) async {
        var tapCalled = false;
        var cancelCalled = false;
        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(),
            onTap: () => tapCalled = true,
            onCancel: () => cancelCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('cancel_quote_button')));
        await tester.pumpAndSettle();
        expect(cancelCalled, isTrue);
        expect(tapCalled, isFalse);
      });
    });

    group('media thumbnail', () {
      testWidgets('shows thumbnail when media file exists locally', (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('quote_test');
        final tempFile = File('${tempDir.path}/image.jpg');
        tempFile.writeAsBytesSync(_testPngBytes);
        addTearDown(() => tempDir.deleteSync(recursive: true));

        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(mediaFile: _mediaFile(filePath: tempFile.path)),
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quote_thumbnail')), findsOneWidget);
      });

      testWidgets('shows thumbnail after download completes', (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('quote_test');
        final tempFile = File('${tempDir.path}/downloaded.jpg');
        tempFile.writeAsBytesSync(_testPngBytes);
        addTearDown(() => tempDir.deleteSync(recursive: true));

        _api.downloadedMediaFile = _mediaFile(filePath: tempFile.path);

        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(mediaFile: _mediaFile()),
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quote_thumbnail')), findsOneWidget);
      });

      testWidgets('does not show thumbnail when no media file', (tester) async {
        await mountWidget(
          ChatMessageQuote(data: _quoteData()),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quote_thumbnail')), findsNothing);
      });

      testWidgets('does not show thumbnail while download is in progress', (tester) async {
        _api.downloadCompleter = Completer<MediaFile>();

        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(mediaFile: _mediaFile()),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('quote_thumbnail')), findsNothing);
      });

      testWidgets('does not show thumbnail when download fails', (tester) async {
        _api.shouldFail = true;

        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(mediaFile: _mediaFile()),
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('quote_thumbnail')), findsNothing);
      });
    });

    group('authorColor', () {
      testWidgets('passes authorColor to WnMessageQuote', (tester) async {
        const customColor = Colors.purple;
        await mountWidget(
          ChatMessageQuote(
            data: _quoteData(
              authorMetadata: const FlutterMetadata(name: 'Test Author', custom: {}),
            ),
            authorColor: customColor,
          ),
          tester,
        );

        final textWidget = tester.widget<Text>(find.text('Test Author'));
        expect(textWidget.style?.color, customColor);
      });
    });
  });
}
