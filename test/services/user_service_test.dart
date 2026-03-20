import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  final subscribeCalls = <String>[];
  bool shouldThrowOnSubscribe = false;

  @override
  Stream<UserStreamItem> crateApiUsersSubscribeToUser({
    required String pubkey,
  }) {
    subscribeCalls.add(pubkey);
    if (shouldThrowOnSubscribe) {
      return Stream.error(Exception('Failed to subscribe to user'));
    }
    return super.crateApiUsersSubscribeToUser(pubkey: pubkey);
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
    mockApi.reset();
    mockApi.shouldThrowOnSubscribe = false;
    mockApi.subscribeCalls.clear();
    service = const UserService(testPubkeyA);
  });

  group('watchUser', () {
    test('emits the initial snapshot user', () async {
      mockApi.seedUserInitialSnapshot(
        testPubkeyA,
        metadata: const FlutterMetadata(displayName: 'Initial User', custom: {}),
      );

      final user = await service.watchUser().first;

      expect(user.pubkey, testPubkeyA);
      expect(user.metadata.displayName, 'Initial User');
      expect(mockApi.subscribeCalls, [testPubkeyA]);
    });

    test('emits later updates after the initial snapshot', () async {
      mockApi.seedUserInitialSnapshot(
        testPubkeyA,
        metadata: const FlutterMetadata(displayName: 'Before', custom: {}),
      );

      final users = <User>[];
      final completer = Completer<List<User>>();
      late final StreamSubscription<User> subscription;
      subscription = service.watchUser().listen((user) {
        users.add(user);
        if (users.length == 2 && !completer.isCompleted) {
          completer.complete(List<User>.from(users));
          subscription.cancel();
        }
      });

      await Future<void>.delayed(Duration.zero);
      mockApi.emitUserUpdate(
        testPubkeyA,
        trigger: UserUpdateTrigger.metadataChanged,
        metadata: const FlutterMetadata(displayName: 'After', custom: {}),
      );

      final emittedUsers = await completer.future;

      expect(emittedUsers.map((user) => user.metadata.displayName), ['Before', 'After']);
    });
  });

  group('watchMetadata', () {
    test('maps user snapshots to metadata snapshots', () async {
      mockApi.seedUserInitialSnapshot(
        testPubkeyA,
        metadata: const FlutterMetadata(name: 'alice', custom: {}),
      );

      final metadata = await service.watchMetadata().first;

      expect(metadata.name, 'alice');
    });
  });

  group('stream-first helpers', () {
    test('getInitialUser returns the first streamed user', () async {
      mockApi.seedUserInitialSnapshot(
        testPubkeyA,
        metadata: const FlutterMetadata(displayName: 'First User', custom: {}),
      );

      final user = await service.getInitialUser();

      expect(user.metadata.displayName, 'First User');
    });

    test('getInitialMetadata returns the first streamed metadata', () async {
      mockApi.seedUserInitialSnapshot(
        testPubkeyA,
        metadata: const FlutterMetadata(displayName: 'First Metadata', custom: {}),
      );

      final metadata = await service.getInitialMetadata();

      expect(metadata.displayName, 'First Metadata');
    });

    test('propagates stream errors from subscribeToUser', () async {
      mockApi.shouldThrowOnSubscribe = true;

      expect(service.getInitialMetadata(), throwsException);
    });
  });
}
