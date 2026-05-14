import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/profile_service.dart';
import 'package:whitenoise_frb/src/rust/api/metadata.dart';
import 'package:whitenoise_frb/src/rust/frb_generated.dart';

import '../test_helpers.dart';

class _MockApi implements RustLibApi {
  FlutterMetadata? updatedMetadata;
  String? updatedPubkey;
  String? uploadedPubkey;
  String? uploadedServerUrl;
  String? uploadedFilePath;
  String? uploadedImageType;

  @override
  Future<void> crateApiAccountsUpdateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {
    updatedPubkey = pubkey;
    updatedMetadata = metadata;
  }

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
    uploadedPubkey = pubkey;
    uploadedServerUrl = serverUrl;
    uploadedFilePath = filePath;
    uploadedImageType = imageType;
    return 'https://example.com/uploaded.jpg';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _MockApi mockApi;
  late ProfileService service;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.updatedMetadata = null;
    mockApi.updatedPubkey = null;
    mockApi.uploadedPubkey = null;
    service = const ProfileService(testPubkeyA);
  });

  group('setProfile', () {
    test('calls API with pubkey', () async {
      await service.setProfile(displayName: 'Test');

      expect(mockApi.updatedPubkey, testPubkeyA);
    });

    test('passes displayName to metadata', () async {
      await service.setProfile(displayName: 'Test Name');

      expect(mockApi.updatedMetadata?.displayName, 'Test Name');
    });

    test('passes about to metadata', () async {
      await service.setProfile(displayName: 'Test', about: 'Bio');

      expect(mockApi.updatedMetadata?.about, 'Bio');
    });

    test('passes pictureUrl to metadata', () async {
      await service.setProfile(displayName: 'Test', pictureUrl: 'https://pic.url');

      expect(mockApi.updatedMetadata?.picture, 'https://pic.url');
    });

    test('passes nip05 to metadata', () async {
      await service.setProfile(displayName: 'Test', nip05: 'user@example.com');

      expect(mockApi.updatedMetadata?.nip05, 'user@example.com');
    });
  });

  group('uploadProfilePicture', () {
    test('throws when file does not exist', () async {
      expect(
        () => service.uploadProfilePicture(filePath: '/nonexistent/file.jpg'),
        throwsException,
      );
    });

    group('when file exists', () {
      late File testFile;

      setUp(() async {
        final tempDir = await Directory.systemTemp.createTemp('profile_test');
        testFile = File('${tempDir.path}/test.jpg');
        const jpegHeader = [0xFF, 0xD8, 0xFF, 0xE0];
        await testFile.writeAsBytes(jpegHeader);
      });

      test('uploads image with expected pubkey', () async {
        await service.uploadProfilePicture(filePath: testFile.path);

        expect(mockApi.uploadedPubkey, testPubkeyA);
      });

      test('uploads to expected blossom server url', () async {
        await service.uploadProfilePicture(filePath: testFile.path);

        expect(mockApi.uploadedServerUrl, 'https://blossom.example.com');
      });

      test('uploads image with expected mime type', () async {
        await service.uploadProfilePicture(filePath: testFile.path);

        expect(mockApi.uploadedImageType, 'image/jpeg');
      });

      test('returns uploaded URL', () async {
        final result = await service.uploadProfilePicture(filePath: testFile.path);

        expect(result, 'https://example.com/uploaded.jpg');
      });
    });
  });
}
