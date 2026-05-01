import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:gal/src/gal_platform_interface.dart';
import 'package:whitenoise/hooks/use_save_to_gallery.dart';

import '../test_helpers.dart';

base class _SuccessGalPlatform extends GalPlatform {
  @override
  Future<void> putImage(String path, {String? album}) async {}

  @override
  Future<void> putVideo(String path, {String? album}) async {}
}

base class _ErrorGalPlatform extends GalPlatform {
  final GalExceptionType type;
  _ErrorGalPlatform(this.type);

  @override
  Future<void> putImage(String path, {String? album}) async {
    throw GalException(
      type: type,
      platformException: PlatformException(code: type.code),
      stackTrace: StackTrace.current,
    );
  }

  @override
  Future<void> putVideo(String path, {String? album}) async {
    throw GalException(
      type: type,
      platformException: PlatformException(code: type.code),
      stackTrace: StackTrace.current,
    );
  }
}

base class _GenericErrorGalPlatform extends GalPlatform {
  @override
  Future<void> putImage(String path, {String? album}) async {
    throw Exception('Generic error');
  }

  @override
  Future<void> putVideo(String path, {String? album}) async {
    throw Exception('Generic error');
  }
}

base class _SlowGalPlatform extends GalPlatform {
  final Completer<void> completer;
  _SlowGalPlatform(this.completer);

  @override
  Future<void> putImage(String path, {String? album}) => completer.future;

  @override
  Future<void> putVideo(String path, {String? album}) => completer.future;
}

Widget _buildHookWidget(String path, void Function(SaveToGalleryResult) onResult) {
  return MaterialApp(
    locale: const Locale('en'),
    home: HookBuilder(
      builder: (context) {
        final result = useSaveToGallery(localPath: path);
        onResult(result);
        return const SizedBox.shrink();
      },
    ),
  );
}

void main() {
  group('useSaveToGallery', () {
    late GalPlatform galPlatform;

    setUp(() {
      galPlatform = GalPlatform.instance;
    });

    tearDown(() {
      GalPlatform.instance = galPlatform;
    });

    test('has correct initial state', () {
      expect(SaveToGalleryStatus.idle.name, 'idle');
      expect(SaveToGalleryStatus.saving.name, 'saving');
      expect(SaveToGalleryStatus.success.name, 'success');
      expect(SaveToGalleryStatus.error.name, 'error');
    });

    test('SaveToGalleryResult has correct structure', () {
      final SaveToGalleryResult result = (
        status: SaveToGalleryStatus.idle,
        save: () {},
        error: null,
        savedRecently: false,
      );

      expect(result.status, SaveToGalleryStatus.idle);
      expect(result.save, isA<void Function()>());
      expect(result.error, isNull);
      expect(result.savedRecently, isFalse);
    });

    test('SaveToGalleryResult has correct structure with error field', () {
      final SaveToGalleryResult result = (
        status: SaveToGalleryStatus.error,
        save: null,
        error: SaveToGalleryError.unexpected,
        savedRecently: false,
      );

      expect(result.status, SaveToGalleryStatus.error);
      expect(result.save, isNull);
      expect(result.error, isA<SaveToGalleryError>());
      expect(result.error, SaveToGalleryError.unexpected);
      expect(result.savedRecently, isFalse);
    });

    testWidgets('save() sets error status when localPath is empty', (tester) async {
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: ''),
      );

      hook().save!();
      await tester.pump();

      expect(hook().status, SaveToGalleryStatus.error);
      expect(hook().error, SaveToGalleryError.unexpected);
    });

    testWidgets('savedRecently is false initially', (tester) async {
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/path'),
      );

      expect(hook().savedRecently, isFalse);
    });

    testWidgets('savedRecently becomes true after successful save', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/path'),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(hook().savedRecently, isTrue);
    });

    testWidgets('savedRecently reverts to false after 2 seconds', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/path'),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(hook().savedRecently, isTrue);

      await tester.pump(const Duration(seconds: 2));

      expect(hook().savedRecently, isFalse);
    });

    testWidgets('status resets to idle after savedRecently timer fires', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/path'),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));

      expect(hook().status, SaveToGalleryStatus.idle);
    });

    testWidgets('savedRecently resets when localPath changes', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();

      late SaveToGalleryResult result;
      await tester.pumpWidget(_buildHookWidget('/path/a', (r) => result = r));
      await tester.pump();

      result.save!();
      await tester.pump();
      await tester.pump();

      expect(result.savedRecently, isTrue);

      await tester.pumpWidget(_buildHookWidget('/path/b', (r) => result = r));
      await tester.pump();

      expect(result.savedRecently, isFalse);
    });

    testWidgets('error resets when localPath changes', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);

      late SaveToGalleryResult result;
      await tester.pumpWidget(_buildHookWidget('/path/a', (r) => result = r));
      await tester.pump();

      result.save!();
      await tester.pump();
      await tester.pump();

      expect(result.error, SaveToGalleryError.accessDenied);

      await tester.pumpWidget(_buildHookWidget('/path/b', (r) => result = r));
      await tester.pump();

      expect(result.error, isNull);
    });

    testWidgets('onError called with accessDenied', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);

      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '/some/path',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.accessDenied);
    });

    testWidgets('onError called with notEnoughSpace', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.notEnoughSpace);

      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '/some/path',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.notEnoughSpace);
    });

    testWidgets('onError called with notSupportedFormat', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.notSupportedFormat);

      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '/some/path',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.notSupportedFormat);
    });

    testWidgets('onError called with unexpected GalException', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.unexpected);

      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '/some/path',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.unexpected);
    });

    testWidgets('onError called with unexpected on generic exception', (tester) async {
      GalPlatform.instance = _GenericErrorGalPlatform();

      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '/some/path',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.unexpected);
    });

    testWidgets('onError called with unexpected when localPath is empty', (tester) async {
      SaveToGalleryError? receivedError;
      final hook = await mountHook(
        tester,
        () => useSaveToGallery(
          localPath: '',
          onError: (err) => receivedError = err,
        ),
      );

      hook().save!();
      await tester.pump();

      expect(receivedError, SaveToGalleryError.unexpected);
    });

    testWidgets('save is null while saving', (tester) async {
      final completer = Completer<void>();
      GalPlatform.instance = _SlowGalPlatform(completer);

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/path'),
      );

      hook().save!();
      await tester.pump();

      expect(hook().save, isNull);

      completer.complete();
      await tester.pump();
      await tester.pump();

      expect(hook().save, isNotNull);
    });

    testWidgets('save() calls putVideo when isVideo is true and succeeds', (tester) async {
      GalPlatform.instance = _SuccessGalPlatform();

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/video.mp4', isVideo: true),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(hook().savedRecently, isTrue);
    });

    testWidgets('save() handles GalException when saving video', (tester) async {
      GalPlatform.instance = _ErrorGalPlatform(GalExceptionType.accessDenied);

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/video.mp4', isVideo: true),
      );

      hook().save!();
      await tester.pump();
      await tester.pump();

      expect(hook().error, SaveToGalleryError.accessDenied);
    });

    testWidgets('save is null while saving video', (tester) async {
      final completer = Completer<void>();
      GalPlatform.instance = _SlowGalPlatform(completer);

      final hook = await mountHook(
        tester,
        () => useSaveToGallery(localPath: '/some/video.mp4', isVideo: true),
      );

      hook().save!();
      await tester.pump();

      expect(hook().save, isNull);

      completer.complete();
      await tester.pump();
      await tester.pump();

      expect(hook().save, isNotNull);
    });
  });
}
