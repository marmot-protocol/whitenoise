import 'dart:io' show File, IOOverrides;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_edit_profile.dart'
    show EditProfileLoadingState, EditProfileState, useEditProfile;
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_account_pubkey_notifier.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  FlutterMetadata? updatedMetadata;
  String? updatedPubkey;
  bool shouldThrowOnLoad = false;
  bool shouldThrowOnUpdate = false;
  bool shouldThrowOnUpload = false;

  FlutterMetadata _currentMetadata() {
    return updatedMetadata ??
        const FlutterMetadata(
          name: 'Test User',
          displayName: 'Test Display Name',
          about: 'Test About',
          nip05: 'test@example.com',
          picture: 'https://example.com/picture.jpg',
          banner: 'https://example.com/banner.jpg',
          website: 'https://example.com',
          lud06: 'lnurl1test',
          lud16: 'test@example.com',
          custom: {'lnurl': 'lnurl1test', 'other_field': 'other_value'},
        );
  }

  @override
  Future<User> crateApiUsersGetUser({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (shouldThrowOnLoad) {
      throw Exception('Load error');
    }
    return buildMockUser(
      pubkey,
      metadata: _currentMetadata(),
    );
  }

  @override
  Future<void> crateApiAccountsUpdateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {
    if (shouldThrowOnUpdate) {
      throw Exception('Update error');
    }
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
    if (shouldThrowOnUpload) {
      throw Exception('Upload error');
    }
    return 'https://example.com/uploaded.jpg';
  }
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
  EditProfileState state,
  TextEditingController displayNameController,
  TextEditingController aboutController,
  TextEditingController nip05Controller,
  Future<void> Function() loadProfile,
  void Function(String imagePath) onImageSelected,
  Future<bool> Function() updateProfileData,
  void Function() discardChanges,
})
result;

Future<void> _pump(WidgetTester tester, List overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        home: HookConsumer(
          builder: (context, ref, _) {
            final pubkey = ref.read(accountPubkeyProvider);
            result = useEditProfile(pubkey);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
}

void main() {
  late _MockApi mockApi;
  late List overrides;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.updatedMetadata = null;
    mockApi.updatedPubkey = null;
    mockApi.shouldThrowOnLoad = false;
    mockApi.shouldThrowOnUpdate = false;
    mockApi.shouldThrowOnUpload = false;
    overrides = [
      accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
    ];
  });

  group('loadProfile', () {
    testWidgets('loads profile data', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      expect(result.state.currentMetadata, isNotNull);
      expect(result.state.displayName, 'Test Display Name');
      expect(result.state.about, 'Test About');
      expect(result.state.nip05, 'test@example.com');
      expect(result.state.loadingState, EditProfileLoadingState.idle);
    });

    testWidgets('handles load errors', (tester) async {
      mockApi.shouldThrowOnLoad = true;
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      expect(result.state.error, isNotNull);
      expect(result.state.loadingState, EditProfileLoadingState.idle);
    });
  });

  group('controllers', () {
    testWidgets('updates state when display name controller changes', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      result.displayNameController.text = 'New Name';
      await tester.pump();

      expect(result.state.displayName, 'New Name');
    });

    testWidgets('updates state when about controller changes', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      result.aboutController.text = 'New About';
      await tester.pump();

      expect(result.state.about, 'New About');
    });

    testWidgets('updates state when nip05 controller changes', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      result.nip05Controller.text = 'new@example.com';
      await tester.pump();

      expect(result.state.nip05, 'new@example.com');
    });
  });

  group('hasUnsavedChanges', () {
    testWidgets('returns false when no changes', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      expect(result.state.hasUnsavedChanges, isFalse);
    });

    testWidgets('returns true when display name changed', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.displayNameController.text = 'New Name';
      await tester.pump();

      expect(result.state.hasUnsavedChanges, isTrue);
    });
  });

  group('discardChanges', () {
    testWidgets('resets to original values', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.displayNameController.text = 'New Name';
      result.aboutController.text = 'New About';
      await tester.pump();

      result.discardChanges();
      await tester.pump();

      expect(result.state.displayName, 'Test Display Name');
      expect(result.state.about, 'Test About');
      expect(result.displayNameController.text, 'Test Display Name');
      expect(result.aboutController.text, 'Test About');
      expect(result.state.hasUnsavedChanges, isFalse);
    });

    testWidgets('clears selectedImagePath', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.onImageSelected('/local/path/image.jpg');
      await tester.pump();

      expect(result.state.selectedImagePath, '/local/path/image.jpg');
      expect(result.state.hasUnsavedChanges, isTrue);

      result.discardChanges();
      await tester.pump();

      expect(result.state.selectedImagePath, isNull);
      expect(result.state.hasUnsavedChanges, isFalse);
    });
  });

  group('pictureUrl', () {
    testWidgets('returns selectedImagePath when set', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.onImageSelected('/local/path/image.jpg');
      await tester.pump();

      expect(result.state.pictureUrl, '/local/path/image.jpg');
    });

    testWidgets('returns currentMetadata picture when no selectedImagePath', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      expect(result.state.pictureUrl, 'https://example.com/picture.jpg');
    });

    testWidgets('returns currentMetadata picture when selectedImagePath is empty', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.onImageSelected('');
      await tester.pump();

      expect(result.state.pictureUrl, 'https://example.com/picture.jpg');
    });
  });

  group('updateProfileData', () {
    testWidgets('does nothing when hasUnsavedChanges is false', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      expect(result.state.hasUnsavedChanges, isFalse);
      expect(mockApi.updatedMetadata, isNull);

      await result.updateProfileData();
      await tester.pumpAndSettle();

      expect(mockApi.updatedMetadata, isNull);
      expect(result.state.loadingState, EditProfileLoadingState.idle);
    });

    testWidgets('saves profile successfully', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.displayNameController.text = 'New Name';
      result.aboutController.text = 'New About';
      await tester.pump();

      expect(result.state.hasUnsavedChanges, isTrue);

      await result.updateProfileData();
      await tester.pumpAndSettle();

      expect(result.state.loadingState, EditProfileLoadingState.idle);
      expect(result.state.error, isNull);
      expect(mockApi.updatedPubkey, testPubkeyA);
      expect(mockApi.updatedMetadata?.displayName, 'New Name');
      expect(mockApi.updatedMetadata?.about, 'New About');
      expect(result.state.displayName, 'New Name');
      expect(result.state.about, 'New About');
      expect(result.state.currentMetadata?.displayName, 'New Name');
      expect(result.state.currentMetadata?.about, 'New About');
      expect(result.state.hasUnsavedChanges, isFalse);
    });

    testWidgets('preserves custom fields and other metadata when updating', (tester) async {
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.displayNameController.text = 'Updated Name';
      result.aboutController.text = 'Updated About';
      await tester.pump();

      await result.updateProfileData();
      await tester.pumpAndSettle();

      expect(result.state.loadingState, EditProfileLoadingState.idle);
      expect(result.state.error, isNull);
      expect(mockApi.updatedMetadata?.displayName, 'Updated Name');
      expect(mockApi.updatedMetadata?.about, 'Updated About');
      expect(mockApi.updatedMetadata?.name, 'Test User');
      expect(mockApi.updatedMetadata?.banner, 'https://example.com/banner.jpg');
      expect(mockApi.updatedMetadata?.website, 'https://example.com');
      expect(mockApi.updatedMetadata?.lud06, 'lnurl1test');
      expect(mockApi.updatedMetadata?.lud16, 'test@example.com');
      expect(mockApi.updatedMetadata?.custom['lnurl'], 'lnurl1test');
      expect(mockApi.updatedMetadata?.custom['other_field'], 'other_value');
      expect(result.state.currentMetadata?.displayName, 'Updated Name');
      expect(result.state.currentMetadata?.about, 'Updated About');
      expect(result.state.currentMetadata?.name, 'Test User');
      expect(result.state.currentMetadata?.banner, 'https://example.com/banner.jpg');
      expect(result.state.currentMetadata?.custom['lnurl'], 'lnurl1test');
    });

    testWidgets('handles save errors', (tester) async {
      mockApi.shouldThrowOnUpdate = true;
      await _pump(tester, overrides);
      await tester.pump();

      await result.loadProfile();
      await tester.pumpAndSettle();

      result.displayNameController.text = 'New Name';
      await tester.pump();

      await result.updateProfileData();
      await tester.pumpAndSettle();

      expect(result.state.loadingState, EditProfileLoadingState.idle);
      expect(result.state.error, isNotNull);
      expect(result.state.hasUnsavedChanges, isTrue);
    });

    testWidgets('uploads image when selectedImagePath is set', (tester) async {
      await IOOverrides.runZoned(
        () async {
          await _pump(tester, overrides);
          await tester.pump();

          await result.loadProfile();
          await tester.pumpAndSettle();

          result.onImageSelected('/fake/image.jpg');
          await tester.pump();

          result.displayNameController.text = 'New Name';
          await tester.pump();

          await result.updateProfileData();
          await tester.pumpAndSettle();

          expect(result.state.loadingState, EditProfileLoadingState.idle);
          expect(result.state.error, isNull);
          expect(mockApi.updatedMetadata?.picture, 'https://example.com/uploaded.jpg');
          expect(result.state.selectedImagePath, isNull);
        },
        createFile: (path) => _MockFile(path),
      );
    });

    testWidgets('handles image upload errors', (tester) async {
      mockApi.shouldThrowOnUpload = true;
      await IOOverrides.runZoned(
        () async {
          await _pump(tester, overrides);
          await tester.pump();

          await result.loadProfile();
          await tester.pumpAndSettle();

          result.onImageSelected('/fake/image.jpg');
          await tester.pump();

          result.displayNameController.text = 'New Name';
          await tester.pump();

          await result.updateProfileData();
          await tester.pumpAndSettle();

          expect(result.state.loadingState, EditProfileLoadingState.idle);
          expect(result.state.error, isNotNull);
          expect(result.state.hasUnsavedChanges, isTrue);
          expect(result.state.selectedImagePath, '/fake/image.jpg');
        },
        createFile: (path) => _MockFile(path),
      );
    });
  });
}
