import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise_frb/src/rust/api/metadata.dart';
import 'package:whitenoise_frb/src/rust/frb_generated.dart';
import 'package:whitenoise/hooks/use_signup.dart';

import '../test_helpers.dart';

class MockApi implements RustLibApi {
  bool imageUploaded = false;
  FlutterMetadata? updatedMetadata;

  @override
  Future<String> crateApiUtilsGetDefaultBlossomServerUrl() async {
    return 'https://blossom.example.com';
  }

  @override
  Future<String> crateApiAccountsUploadAccountProfilePicture({
    required String pubkey,
    required String serverUrl,
    required String filePath,
    required String imageType,
  }) async {
    imageUploaded = true;
    return 'https://example.com/uploaded.jpg';
  }

  @override
  Future<void> crateApiAccountsUpdateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {
    updatedMetadata = metadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MockFile extends Fake implements File {
  _MockFile(this.path);

  @override
  final String path;

  @override
  bool existsSync() => true;

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    return Stream.value([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01]);
  }
}

late ({
  SignupState state,
  SubmitCallback submit,
  OnImageSelectedCallback onImageSelected,
  ClearErrorsCallback clearErrors,
})
result;

bool signupCalled = false;
bool shouldThrowOnSignup = false;

Future<String> mockSignup() async {
  if (shouldThrowOnSignup) {
    throw Exception('Network error');
  }
  signupCalled = true;
  return testPubkeyA;
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          result = useSignup(mockSignup);
          return const SizedBox();
        },
      ),
    ),
  );
}

late MockApi mockApi;

void main() {
  setUpAll(() {
    mockApi = MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    signupCalled = false;
    shouldThrowOnSignup = false;
    mockApi.imageUploaded = false;
    mockApi.updatedMetadata = null;
  });

  group('submit', () {
    testWidgets('sets error when displayName is empty', (tester) async {
      await _pump(tester);
      await result.submit(displayName: '');
      await tester.pump();

      expect(result.state.displayNameError, isNotNull);
    });

    testWidgets('calls signup callback', (tester) async {
      await _pump(tester);
      await result.submit(displayName: 'Test');

      expect(signupCalled, isTrue);
    });

    testWidgets('updates metadata', (tester) async {
      await _pump(tester);
      await result.submit(displayName: 'Test');

      expect(mockApi.updatedMetadata, isNotNull);
    });

    testWidgets('with image uploads to blossom', (tester) async {
      await IOOverrides.runZoned(
        () async {
          await _pump(tester);
          result.onImageSelected('/fake/image.jpg');
          await result.submit(displayName: 'Test');

          expect(mockApi.imageUploaded, isTrue);
        },
        createFile: (path) => _MockFile(path),
      );
    });

    testWidgets('with image includes url in metadata', (tester) async {
      await IOOverrides.runZoned(
        () async {
          await _pump(tester);
          result.onImageSelected('/fake/image.jpg');
          await result.submit(displayName: 'Test');

          expect(mockApi.updatedMetadata?.picture, 'https://example.com/uploaded.jpg');
        },
        createFile: (path) => _MockFile(path),
      );
    });

    testWidgets('sets friendly error message on failure', (tester) async {
      shouldThrowOnSignup = true;
      await _pump(tester);
      await result.submit(displayName: 'Test');
      await tester.pump();

      expect(result.state.error, 'Oh no! An error occurred, please try again.');
    });
  });

  group('clearErrors', () {
    testWidgets('clears error', (tester) async {
      shouldThrowOnSignup = true;
      await _pump(tester);
      await result.submit(displayName: 'Test');
      await tester.pump();

      expect(result.state.error, isNotNull);

      result.clearErrors();
      await tester.pump();

      expect(result.state.error, isNull);
    });

    testWidgets('clears displayNameError', (tester) async {
      await _pump(tester);
      await result.submit(displayName: '');
      await tester.pump();

      expect(result.state.displayNameError, isNotNull);

      result.clearErrors();
      await tester.pump();

      expect(result.state.displayNameError, isNull);
    });
  });
}
