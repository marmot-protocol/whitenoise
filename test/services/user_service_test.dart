import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  FlutterMetadata nonBlockingMetadataResult = const FlutterMetadata(custom: {});
  FlutterMetadata blockingMetadataResult = const FlutterMetadata(
    name: 'blocking_sync_result',
    custom: {},
  );

  User? nonBlockingUserResult;
  User? blockingUserResult;
  bool getUserShouldThrow = false;
  bool getMetadataShouldThrow = false;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    if (getMetadataShouldThrow) throw Exception('Failed to fetch metadata');
    return blockingDataSync ? blockingMetadataResult : nonBlockingMetadataResult;
  }

  @override
  Future<User> crateApiUsersGetUser({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    if (getUserShouldThrow) {
      throw Exception('Failed to fetch user');
    }
    final result = blockingDataSync ? blockingUserResult : nonBlockingUserResult;
    if (result == null) {
      throw Exception('No mock result configured');
    }
    return result;
  }
}

void main() {
  late _MockApi mockApi;
  late UserService service;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.nonBlockingMetadataResult = const FlutterMetadata(custom: {});
    mockApi.blockingMetadataResult = const FlutterMetadata(
      name: 'blocking_sync_result',
      custom: {},
    );
    mockApi.getMetadataShouldThrow = false;
    mockApi.nonBlockingUserResult = null;
    mockApi.blockingUserResult = null;
    mockApi.getUserShouldThrow = false;
    service = const UserService(testPubkeyA);
  });

  group('fetchMetadata', () {
    group('when metadata has name', () {
      setUp(() {
        mockApi.nonBlockingMetadataResult = const FlutterMetadata(
          name: 'Test',
          custom: {},
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchMetadata();

        expect(result.name, 'Test');
      });
    });

    group('when metadata has displayName', () {
      setUp(() {
        mockApi.nonBlockingMetadataResult = const FlutterMetadata(
          displayName: 'Display',
          custom: {},
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchMetadata();

        expect(result.displayName, 'Display');
      });
    });

    group('when metadata has picture', () {
      setUp(() {
        mockApi.nonBlockingMetadataResult = const FlutterMetadata(
          picture: 'https://example.com/pic.jpg',
          custom: {},
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchMetadata();

        expect(result.picture, 'https://example.com/pic.jpg');
      });
    });

    group('when metadata is empty', () {
      test('returns blocking sync result', () async {
        final result = await service.fetchMetadata();

        expect(result.name, 'blocking_sync_result');
      });
    });

    group('when metadata has empty strings for name, displayName and picture', () {
      setUp(() {
        mockApi.nonBlockingMetadataResult = const FlutterMetadata(
          name: '',
          displayName: '',
          picture: '',
          custom: {},
        );
      });

      test('returns blocking sync result', () async {
        final result = await service.fetchMetadata();

        expect(result.name, 'blocking_sync_result');
      });
    });

    group('when API throws', () {
      setUp(() {
        mockApi.getMetadataShouldThrow = true;
      });

      test('rethrows the exception', () async {
        expect(() => service.fetchMetadata(), throwsException);
      });
    });
  });

  group('fetchUser', () {
    final now = DateTime.now();

    group('when user has complete metadata', () {
      setUp(() {
        mockApi.nonBlockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(name: 'Test User', custom: {}),
          createdAt: now,
          updatedAt: now,
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchUser();

        expect(result, isNotNull);
        expect(result!.metadata.name, 'Test User');
      });
    });

    group('when user has displayName', () {
      setUp(() {
        mockApi.nonBlockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(displayName: 'Display Name', custom: {}),
          createdAt: now,
          updatedAt: now,
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchUser();

        expect(result, isNotNull);
        expect(result!.metadata.displayName, 'Display Name');
      });
    });

    group('when user has picture', () {
      setUp(() {
        mockApi.nonBlockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(
            picture: 'https://example.com/pic.jpg',
            custom: {},
          ),
          createdAt: now,
          updatedAt: now,
        );
      });

      test('returns non-blocking result', () async {
        final result = await service.fetchUser();

        expect(result, isNotNull);
        expect(result!.metadata.picture, 'https://example.com/pic.jpg');
      });
    });

    group('when user has empty metadata', () {
      setUp(() {
        mockApi.nonBlockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(custom: {}),
          createdAt: now,
          updatedAt: now,
        );
        mockApi.blockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(name: 'Blocking Sync User', custom: {}),
          createdAt: now,
          updatedAt: now,
        );
      });

      test('returns blocking sync result', () async {
        final result = await service.fetchUser();

        expect(result, isNotNull);
        expect(result!.metadata.name, 'Blocking Sync User');
      });
    });

    group('when user has empty strings for metadata fields', () {
      setUp(() {
        mockApi.nonBlockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(
            name: '',
            displayName: '',
            picture: '',
            custom: {},
          ),
          createdAt: now,
          updatedAt: now,
        );
        mockApi.blockingUserResult = User(
          pubkey: testPubkeyA,
          metadata: const FlutterMetadata(name: 'Blocking Sync User', custom: {}),
          createdAt: now,
          updatedAt: now,
        );
      });

      test('returns blocking sync result', () async {
        final result = await service.fetchUser();

        expect(result, isNotNull);
        expect(result!.metadata.name, 'Blocking Sync User');
      });
    });

    group('when getUser throws an error', () {
      setUp(() {
        mockApi.getUserShouldThrow = true;
      });

      test('returns null', () async {
        final result = await service.fetchUser();

        expect(result, isNull);
      });
    });
  });
}
