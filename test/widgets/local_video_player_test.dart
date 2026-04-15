import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/local_video_player.dart';

import '../fakes/fake_video_player_platform.dart';
import '../test_helpers.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 20; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  late FakeVideoPlayerPlatform fakeVideoPlatform;
  late Directory tempDir;
  late File videoFile;

  setUp(() {
    fakeVideoPlatform = setUpFakeVideoPlayerPlatform();
    tempDir = Directory.systemTemp.createTempSync('local_video_player_test');
    videoFile = File('${tempDir.path}/clip.mp4')..writeAsBytesSync([0, 0, 0, 0]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('LocalVideoPlayer', () {
    testWidgets('initializes a file video player', (tester) async {
      await mountWidget(
        LocalVideoPlayer(filePath: videoFile.path),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_player')), findsOneWidget);
      expect(fakeVideoPlatform.calls, contains('createWithOptions'));
      expect(fakeVideoPlatform.dataSources.first.uri, startsWith('file://'));
    });

    testWidgets('shows play indicator while paused', (tester) async {
      await mountWidget(
        LocalVideoPlayer(filePath: videoFile.path),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_play_indicator')), findsOneWidget);
      expect(find.byKey(const Key('video_play_icon')), findsOneWidget);
    });

    testWidgets('toggles playback when tapped', (tester) async {
      await mountWidget(
        LocalVideoPlayer(filePath: videoFile.path),
        tester,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('local_video_tap_area')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('local_video_tap_area')));
      await tester.pump();

      expect(fakeVideoPlatform.calls, contains('play'));
      expect(fakeVideoPlatform.calls, contains('pause'));
    });

    testWidgets('shows error placeholder when initialization fails', (tester) async {
      fakeVideoPlatform.forceInitError = true;

      await mountWidget(
        LocalVideoPlayer(filePath: videoFile.path),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_error_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('video_player')), findsNothing);
    });

    testWidgets('hides controls when showControls is false', (tester) async {
      await mountWidget(
        LocalVideoPlayer(filePath: videoFile.path, showControls: false),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_play_indicator')), findsNothing);
    });

    testWidgets('disposes and reinitializes when filePath changes', (tester) async {
      final secondVideoFile = File('${tempDir.path}/clip2.mp4')..writeAsBytesSync([0, 0, 0, 0]);
      var currentPath = videoFile.path;
      late StateSetter setState;

      await mountWidget(
        StatefulBuilder(
          builder: (context, setStateCallback) {
            setState = setStateCallback;
            return LocalVideoPlayer(filePath: currentPath);
          },
        ),
        tester,
      );
      await tester.pumpAndSettle();

      setState(() => currentPath = secondVideoFile.path);
      await tester.pumpAndSettle();
      await pumpUntil(
        tester,
        () => fakeVideoPlatform.calls.where((call) => call == 'createWithOptions').length == 2,
      );

      expect(fakeVideoPlatform.calls.where((call) => call == 'createWithOptions'), hasLength(2));
      final firstCreateIndex = fakeVideoPlatform.calls.indexOf('createWithOptions');
      final disposeIndex = fakeVideoPlatform.calls.indexOf('dispose');
      final secondCreateIndex = fakeVideoPlatform.calls.lastIndexOf('createWithOptions');

      expect(disposeIndex, greaterThan(firstCreateIndex));
      expect(disposeIndex, lessThan(secondCreateIndex));
      expect(fakeVideoPlatform.dataSources.last.uri, contains('clip2.mp4'));
    });
  });

  group('VideoPlayIndicator', () {
    testWidgets('honors visible and size parameters', (tester) async {
      await mountWidget(
        const VideoPlayIndicator(visible: false, size: 32),
        tester,
      );

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      final container = tester.widget<Container>(find.byType(Container));

      expect(opacity.opacity, 0);
      expect(container.constraints?.maxWidth, 32);
    });
  });
}
