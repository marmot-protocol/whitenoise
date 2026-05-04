import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final calls = <String>[];
  final dataSources = <DataSource>[];
  final streams = <int, StreamController<VideoEvent>>{};

  bool forceInitError = false;
  int nextPlayerId = 0;

  @override
  Future<void> init() async {
    calls.add('init');
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    calls.add('createWithOptions');
    final playerId = nextPlayerId++;
    final stream = StreamController<VideoEvent>();
    streams[playerId] = stream;
    dataSources.add(options.dataSource);

    if (forceInitError) {
      stream.addError(
        PlatformException(
          code: 'VideoError',
          message: 'Video player failed to initialize',
        ),
      );
    } else {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(640, 360),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return streams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    final controller = streams.remove(playerId);
    await controller?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    calls.add('setLooping');
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
    streams[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
    streams[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    calls.add('setVolume');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    calls.add('setPlaybackSpeed');
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    calls.add('getPosition');
    return Duration.zero;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    calls.add('seekTo');
  }

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }
}

FakeVideoPlayerPlatform setUpFakeVideoPlayerPlatform() {
  final fake = FakeVideoPlayerPlatform();
  VideoPlayerPlatform.instance = fake;
  return fake;
}
