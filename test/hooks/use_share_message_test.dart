import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_share_message.dart';

import '../test_helpers.dart';

void main() {
  group('useShareMessage', () {
    testWidgets('share is null when there is no text and no files', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(),
      );

      expect(hook().share, isNull);
      expect(hook().status, ShareMessageStatus.idle);
    });

    testWidgets('share is null when text is only whitespace and no files', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(text: '   '),
      );

      expect(hook().share, isNull);
    });

    testWidgets('share is callable when text is provided', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(text: 'hello'),
      );

      expect(hook().share, isNotNull);
    });

    testWidgets('share is callable when files are provided', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(filePaths: const ['/tmp/x.jpg']),
      );

      expect(hook().share, isNotNull);
    });

    testWidgets('share is callable when both text and files are provided', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(
          text: 'note',
          filePaths: const ['/tmp/x.jpg'],
        ),
      );

      expect(hook().share, isNotNull);
    });

    testWidgets('share stays callable while an earlier share is in flight', (tester) async {
      final hook = await mountHook(
        tester,
        () => useShareMessage(text: 'hi'),
      );

      // Kick off a share — we never await it because the platform channel
      // isn't mocked here. We only need to verify the callable reference
      // doesn't get nulled out while sharing is in flight.
      unawaited(hook().share!());
      await tester.pump();

      expect(hook().share, isNotNull);
    });

    test('ShareMessageStatus enum has expected values', () {
      expect(ShareMessageStatus.idle.name, 'idle');
      expect(ShareMessageStatus.sharing.name, 'sharing');
      expect(ShareMessageStatus.error.name, 'error');
    });

    test('ShareMessageResult has correct structure', () {
      final ShareMessageResult result = (
        status: ShareMessageStatus.idle,
        share: ({sharePositionOrigin}) async {},
      );
      expect(result.status, ShareMessageStatus.idle);
      expect(result.share, isA<ShareFn>());
    });

    group('filterExistingFiles', () {
      test('returns only existing non-empty paths', () async {
        final tempDir = await Directory.systemTemp.createTemp('filter_test');
        addTearDown(() => tempDir.delete(recursive: true));
        final realFile = File('${tempDir.path}/real.txt');
        await realFile.writeAsString('x');

        final result = filterExistingFiles([
          '',
          realFile.path,
          '${tempDir.path}/does_not_exist.txt',
        ]);

        expect(result, [realFile.path]);
      });

      test('returns empty list when given no paths', () {
        expect(filterExistingFiles(const []), isEmpty);
      });

      test('filters out empty strings', () {
        expect(filterExistingFiles(const ['', '']), isEmpty);
      });
    });
  });
}
