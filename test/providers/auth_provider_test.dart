import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/is_adding_account_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_secure_storage.dart';
import '../test_helpers.dart';

class _MockRustLibApi implements RustLibApi {
  var metadataCompleter = Completer<FlutterMetadata>();
  String? metadataCalledWithPubkey;
  String? logoutCalledWithPubkey;
  String? loginCancelCalledWithPubkey;
  final Set<String> existingAccounts = {};
  Object? getAccountError;
  Object? getAccountsError;
  List<Account> allAccounts = [];
  Map<String, AccountType> accountTypes = {};
  bool loginWithSignerCalled = false;
  String? loginWithSignerPubkey;
  Object? loginWithSignerError;
  bool registerExternalSignerCalled = false;
  FutureOr<String> Function(String)? signEventCallback;
  FutureOr<String> Function(String, String)? nip04EncryptCallback;
  FutureOr<String> Function(String, String)? nip04DecryptCallback;
  FutureOr<String> Function(String, String)? nip44EncryptCallback;
  FutureOr<String> Function(String, String)? nip44DecryptCallback;

  @override
  Future<Account> crateApiAccountsGetAccount({required String pubkey}) async {
    if (getAccountError != null) {
      throw getAccountError!;
    }
    if (!existingAccounts.contains(pubkey)) {
      throw const ApiError.whitenoise(message: 'Account not found');
    }
    return Account(
      pubkey: pubkey,
      accountType: accountTypes[pubkey] ?? AccountType.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerStart({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    loginWithSignerCalled = true;
    loginWithSignerPubkey = pubkey;
    signEventCallback = signEvent;
    nip04EncryptCallback = nip04Encrypt;
    nip04DecryptCallback = nip04Decrypt;
    nip44EncryptCallback = nip44Encrypt;
    nip44DecryptCallback = nip44Decrypt;
    if (loginWithSignerError != null) {
      throw loginWithSignerError!;
    }
    existingAccounts.add(pubkey);
    accountTypes[pubkey] = AccountType.external_;
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerPublishDefaultRelays({
    required String pubkey,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerWithCustomRelay({
    required String pubkey,
    required String relayUrl,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<void> crateApiSignerRegisterExternalSigner({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    registerExternalSignerCalled = true;
    signEventCallback = signEvent;
    nip04EncryptCallback = nip04Encrypt;
    nip04DecryptCallback = nip04Decrypt;
    nip44EncryptCallback = nip44Encrypt;
    nip44DecryptCallback = nip44Decrypt;
  }

  @override
  Future<Account> crateApiAccountsCreateIdentity() async {
    existingAccounts.add(testPubkeyC);
    return Account(
      pubkey: testPubkeyC,
      accountType: AccountType.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LoginResult> crateApiAccountsLoginStart({
    required String nsecOrHexPrivkey,
  }) async {
    existingAccounts.add(testPubkeyB);
    return LoginResult(
      account: Account(
        pubkey: testPubkeyB,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiAccountsLoginPublishDefaultRelays({
    required String pubkey,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiAccountsLoginWithCustomRelay({
    required String pubkey,
    required String relayUrl,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<void> crateApiAccountsLoginCancel({required String pubkey}) async {
    loginCancelCalledWithPubkey = pubkey;
  }

  @override
  Future<void> crateApiAccountsLogout({required String pubkey}) async {
    logoutCalledWithPubkey = pubkey;
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) {
    metadataCalledWithPubkey = pubkey;
    return metadataCompleter.future;
  }

  @override
  Future<List<Account>> crateApiAccountsGetAccounts() async {
    if (getAccountsError != null) {
      throw getAccountsError!;
    }
    return allAccounts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late ProviderContainer container;
  late _MockRustLibApi mockApi;
  late MockSecureStorage mockStorage;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockApi = _MockRustLibApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.metadataCompleter = Completer<FlutterMetadata>();
    mockApi.metadataCalledWithPubkey = null;
    mockApi.logoutCalledWithPubkey = null;
    mockApi.existingAccounts.clear();
    mockApi.getAccountError = null;
    mockApi.getAccountsError = null;
    mockApi.allAccounts = [];
    mockApi.accountTypes = {};
    mockApi.loginWithSignerCalled = false;
    mockApi.loginWithSignerPubkey = null;
    mockApi.loginWithSignerError = null;
    mockApi.registerExternalSignerCalled = false;
    mockApi.signEventCallback = null;
    mockApi.nip04EncryptCallback = null;
    mockApi.nip04DecryptCallback = null;
    mockApi.nip44EncryptCallback = null;
    mockApi.nip44DecryptCallback = null;
    mockStorage = MockSecureStorage();
    container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
    );
  });

  tearDown(() => container.dispose());

  group('AuthNotifier', () {
    group('build', () {
      group('when secure storage has no pubkey', () {
        test('returns null', () async {
          await container.read(authProvider.future);
          expect(container.read(authProvider).value, isNull);
        });
      });

      group('when pubkey is only in secure storage', () {
        setUp(() async {
          mockApi.existingAccounts.clear();
          await mockStorage.write(key: 'active_account_pubkey', value: 'stale_pubkey');
        });
        test('returns null', () async {
          final pubkey = await container.read(authProvider.future);
          expect(pubkey, isNull);
          expect(await mockStorage.read(key: 'active_account_pubkey'), isNull);
        });

        test('clears secure storage', () async {
          await container.read(authProvider.future);
          expect(await mockStorage.read(key: 'active_account_pubkey'), isNull);
        });
      });

      group('when getAccount fails with unexpected error', () {
        setUp(() async {
          mockApi.getAccountError = const ApiError.whitenoise(message: 'Network error');
          await mockStorage.write(key: 'active_account_pubkey', value: 'stored_pubkey');
        });

        test('returns stored pubkey', () async {
          final pubkey = await container.read(authProvider.future);
          expect(pubkey, 'stored_pubkey');
        });

        test('does not clear secure storage', () async {
          await container.read(authProvider.future);
          expect(await mockStorage.read(key: 'active_account_pubkey'), 'stored_pubkey');
        });
      });

      group('when pubkey is in secure storage and rust crate db', () {
        setUp(() async {
          mockApi.existingAccounts.add('stored_pubkey');
          await mockStorage.write(key: 'active_account_pubkey', value: 'stored_pubkey');
        });
        test('returns expected pubkey', () async {
          final pubkey = await container.read(authProvider.future);
          expect(pubkey, 'stored_pubkey');
        });

        test('does not clear secure storage', () async {
          await container.read(authProvider.future);
          expect(await mockStorage.read(key: 'active_account_pubkey'), 'stored_pubkey');
        });
      });
    });

    group('loginStart', () {
      test('sets state to pubkey', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(container.read(authProvider).value, testPubkeyB);
      });

      test('returns LoginResult with complete status', () async {
        final result = await container.read(authProvider.notifier).loginStart('nsec123');
        expect(result.account.pubkey, testPubkeyB);
        expect(result.status, LoginStatus.complete);
      });

      test('does not prefetch account metadata', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('completes login without metadata prefetch', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(container.read(authProvider).value, testPubkeyB);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        expect(container.read(isAddingAccountProvider), true);
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('loginPublishDefaultRelays', () {
      test('sets state to pubkey on complete', () async {
        final result = await container
            .read(authProvider.notifier)
            .loginPublishDefaultRelays(testPubkeyA);
        expect(result.status, LoginStatus.complete);
        expect(container.read(authProvider).value, testPubkeyA);
      });

      test('does not prefetch metadata', () async {
        await container.read(authProvider.notifier).loginPublishDefaultRelays(testPubkeyA);
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        await container.read(authProvider.notifier).loginPublishDefaultRelays(testPubkeyA);
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('loginWithCustomRelay', () {
      test('sets state to pubkey on complete', () async {
        final result = await container
            .read(authProvider.notifier)
            .loginWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(result.status, LoginStatus.complete);
        expect(container.read(authProvider).value, testPubkeyA);
      });

      test('does not prefetch metadata', () async {
        await container
            .read(authProvider.notifier)
            .loginWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        await container
            .read(authProvider.notifier)
            .loginWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('loginCancel', () {
      test('calls Rust API loginCancel with correct pubkey', () async {
        await container.read(authProvider.notifier).loginCancel(testPubkeyA);
        expect(mockApi.loginCancelCalledWithPubkey, testPubkeyA);
      });
    });

    group('loginExternalSignerPublishDefaultRelays', () {
      test('sets state to pubkey on complete', () async {
        final result = await container
            .read(authProvider.notifier)
            .loginExternalSignerPublishDefaultRelays(testPubkeyA);
        expect(result.status, LoginStatus.complete);
        expect(container.read(authProvider).value, testPubkeyA);
      });

      test('does not prefetch metadata', () async {
        await container
            .read(authProvider.notifier)
            .loginExternalSignerPublishDefaultRelays(testPubkeyA);
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        await container
            .read(authProvider.notifier)
            .loginExternalSignerPublishDefaultRelays(testPubkeyA);
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('loginExternalSignerWithCustomRelay', () {
      test('sets state to pubkey on complete', () async {
        final result = await container
            .read(authProvider.notifier)
            .loginExternalSignerWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(result.status, LoginStatus.complete);
        expect(container.read(authProvider).value, testPubkeyA);
      });

      test('does not prefetch metadata', () async {
        await container
            .read(authProvider.notifier)
            .loginExternalSignerWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        await container
            .read(authProvider.notifier)
            .loginExternalSignerWithCustomRelay(testPubkeyA, 'wss://relay.example.com');
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('signup', () {
      test('returns created pubkey', () async {
        final pubkey = await container.read(authProvider.notifier).signup();
        expect(pubkey, testPubkeyC);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        expect(container.read(isAddingAccountProvider), true);
        await container.read(authProvider.notifier).signup();
        expect(container.read(isAddingAccountProvider), false);
      });
    });

    group('logout', () {
      test('clears state when no other accounts', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        await container.read(authProvider.notifier).logout();
        expect(container.read(authProvider).value, isNull);
      });

      test('clears storage when no other accounts', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        await container.read(authProvider.notifier).logout();
        expect(await mockStorage.read(key: 'active_account_pubkey'), isNull);
      });

      test('calls Rust API logout', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        await container.read(authProvider.notifier).logout();
        expect(mockApi.logoutCalledWithPubkey, testPubkeyB);
      });

      test('does nothing when not authenticated', () async {
        await container.read(authProvider.future);
        await container.read(authProvider.notifier).logout();
        expect(mockApi.logoutCalledWithPubkey, isNull);
        expect(container.read(authProvider).value, isNull);
      });

      test('switches to another account when available', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        mockApi.existingAccounts.add('other_pubkey');
        mockApi.allAccounts = [
          Account(
            accountType: AccountType.local,
            pubkey: 'other_pubkey',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        final nextPubkey = await container.read(authProvider.notifier).logout();
        expect(nextPubkey, 'other_pubkey');
        expect(container.read(authProvider).value, 'other_pubkey');
        expect(await mockStorage.read(key: 'active_account_pubkey'), 'other_pubkey');
      });

      test('filters out logged-out account when switching', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        mockApi.existingAccounts.add(testPubkeyD);
        mockApi.allAccounts = [
          Account(
            accountType: AccountType.local,
            pubkey: testPubkeyB,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Account(
            accountType: AccountType.local,
            pubkey: testPubkeyD,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        final nextPubkey = await container.read(authProvider.notifier).logout();
        expect(nextPubkey, testPubkeyD);
        expect(container.read(authProvider).value, testPubkeyD);
      });

      test('returns null when no other accounts', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        final nextPubkey = await container.read(authProvider.notifier).logout();
        expect(nextPubkey, isNull);
      });

      test('returns null when getAccounts fails', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        mockApi.getAccountsError = Exception('Network error');
        final nextPubkey = await container.read(authProvider.notifier).logout();
        expect(nextPubkey, isNull);
        expect(container.read(authProvider).value, isNull);
      });
    });

    group('resetAuth', () {
      test('clears state', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(container.read(authProvider).value, testPubkeyB);

        await container.read(authProvider.notifier).resetAuth();
        expect(container.read(authProvider).value, isNull);
      });

      test('clears secure storage', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        expect(await mockStorage.read(key: 'active_account_pubkey'), testPubkeyB);

        await container.read(authProvider.notifier).resetAuth();
        expect(await mockStorage.read(key: 'active_account_pubkey'), isNull);
      });

      test('does not call Rust API logout', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        await container.read(authProvider.notifier).resetAuth();
        expect(mockApi.logoutCalledWithPubkey, isNull);
      });
    });

    group('switchProfile', () {
      test('updates state to new pubkey', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        mockApi.existingAccounts.add('new_pubkey');
        await container.read(authProvider.notifier).switchProfile('new_pubkey');
        expect(container.read(authProvider).value, 'new_pubkey');
      });

      test('updates storage with new pubkey', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        mockApi.existingAccounts.add('new_pubkey');
        await container.read(authProvider.notifier).switchProfile('new_pubkey');
        expect(await mockStorage.read(key: 'active_account_pubkey'), 'new_pubkey');
      });

      test('clears state when account not found', () async {
        await container.read(authProvider.notifier).loginStart('nsec123');
        await container.read(authProvider.notifier).switchProfile('nonexistent');
        expect(container.read(authProvider).value, isNull);
        expect(await mockStorage.read(key: 'active_account_pubkey'), isNull);
      });
    });

    group('loginExternalSignerStart', () {
      test('sets state to pubkey on success', () async {
        await container
            .read(authProvider.notifier)
            .loginExternalSignerStart(
              pubkey: testPubkeyA,
            );
        expect(container.read(authProvider).value, testPubkeyA);
      });

      test('returns LoginResult with complete status', () async {
        final result = await container
            .read(authProvider.notifier)
            .loginExternalSignerStart(
              pubkey: testPubkeyA,
            );
        expect(result.account.pubkey, testPubkeyA);
        expect(result.status, LoginStatus.complete);
      });

      test('calls Rust API loginExternalSignerStart', () async {
        await container
            .read(authProvider.notifier)
            .loginExternalSignerStart(
              pubkey: testPubkeyA,
            );
        expect(mockApi.loginWithSignerCalled, isTrue);
        expect(mockApi.loginWithSignerPubkey, testPubkeyA);
      });

      test('does not prefetch metadata', () async {
        await container
            .read(authProvider.notifier)
            .loginExternalSignerStart(
              pubkey: testPubkeyA,
            );
        expect(mockApi.metadataCalledWithPubkey, isNull);
      });

      test('resets isAddingAccountProvider to false', () async {
        container.read(isAddingAccountProvider.notifier).set(true);
        await container
            .read(authProvider.notifier)
            .loginExternalSignerStart(
              pubkey: testPubkeyA,
            );
        expect(container.read(isAddingAccountProvider), false);
      });

      test('handles disconnect failure gracefully', () async {
        mockApi.loginWithSignerError = const ApiError.whitenoise(message: 'Test error');

        await expectLater(
          () => container
              .read(authProvider.notifier)
              .loginExternalSignerStart(
                pubkey: testPubkeyA,
              ),
          throwsA(isA<ApiError>()),
        );
      });
    });

    group('build with external account', () {
      test('re-registers external signer callbacks', () async {
        mockApi.existingAccounts.add(testPubkeyA);
        mockApi.accountTypes[testPubkeyA] = AccountType.external_;
        await mockStorage.write(key: 'active_account_pubkey', value: testPubkeyA);

        await container.read(authProvider.future);

        expect(mockApi.registerExternalSignerCalled, isTrue);
      });

      test('does not re-register for local account', () async {
        mockApi.existingAccounts.add(testPubkeyA);
        mockApi.accountTypes[testPubkeyA] = AccountType.local;
        await mockStorage.write(key: 'active_account_pubkey', value: testPubkeyA);

        await container.read(authProvider.future);

        expect(mockApi.registerExternalSignerCalled, isFalse);
      });
    });
  });
}
