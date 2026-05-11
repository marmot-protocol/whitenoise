import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/external_signer_callback_registry.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';

import '../test_helpers.dart';

Account _account(String pubkey, AccountType accountType) {
  return Account(
    pubkey: pubkey,
    accountType: accountType,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  test('reconcile keeps registering optional accounts after one registration fails', () async {
    final recordedRegistrations = <String>[];
    final registeredPubkeys = <String>{};
    final registrationFutures = <String, Future<void>>{};
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      registerSignerCallback: (pubkey) async {
        if (pubkey == testPubkeyA) {
          throw Exception('signer unavailable');
        }
        recordedRegistrations.add(pubkey);
      },
    );

    await registry.reconcile(
      [
        _account(testPubkeyA, AccountType.external_),
        _account(testPubkeyB, AccountType.external_),
        _account(testPubkeyC, AccountType.local),
        _account(testPubkeyD, AccountType.external_),
      ],
      registeredExternalSignerPubkeys: registeredPubkeys,
      externalSignerRegistrationFutures: registrationFutures,
    );

    expect(recordedRegistrations, [testPubkeyB, testPubkeyD]);
  });

  test('reconcile rethrows when a required account registration fails', () async {
    final recordedRegistrations = <String>[];
    final registeredPubkeys = <String>{};
    final registrationFutures = <String, Future<void>>{};
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      registerSignerCallback: (pubkey) async {
        if (pubkey == testPubkeyB) {
          throw Exception('active signer unavailable');
        }
        recordedRegistrations.add(pubkey);
      },
    );

    await expectLater(
      registry.reconcile(
        [
          _account(testPubkeyA, AccountType.external_),
          _account(testPubkeyB, AccountType.external_),
          _account(testPubkeyD, AccountType.external_),
        ],
        registeredExternalSignerPubkeys: registeredPubkeys,
        externalSignerRegistrationFutures: registrationFutures,
        requiredPubkeys: {testPubkeyB},
      ),
      throwsException,
    );

    expect(recordedRegistrations, [testPubkeyA]);
  });

  test('reconcile rethrows when requireAll registration fails', () async {
    final registeredPubkeys = <String>{};
    final registrationFutures = <String, Future<void>>{};
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      registerSignerCallback: (pubkey) async {
        if (pubkey == testPubkeyB) {
          throw Exception('signer unavailable');
        }
      },
    );

    await expectLater(
      registry.reconcile(
        [
          _account(testPubkeyA, AccountType.external_),
          _account(testPubkeyB, AccountType.external_),
        ],
        registeredExternalSignerPubkeys: registeredPubkeys,
        externalSignerRegistrationFutures: registrationFutures,
        requireAll: true,
      ),
      throwsException,
    );
  });

  test('ensureRegistered returns when account lookup fails without known accounts', () async {
    final recordedRegistrations = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      getAccounts: () async => throw Exception('accounts unavailable'),
      registerSignerCallback: (pubkey) async {
        recordedRegistrations.add(pubkey);
      },
    );

    await registry.ensureRegistered(
      registeredExternalSignerPubkeys: <String>{},
      externalSignerRegistrationFutures: <String, Future<void>>{},
    );

    expect(recordedRegistrations, isEmpty);
  });

  test('ensureRegistered rethrows account lookup failure when all accounts are required', () async {
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      getAccounts: () async => throw Exception('accounts unavailable'),
    );

    await expectLater(
      registry.ensureRegistered(
        registeredExternalSignerPubkeys: <String>{},
        externalSignerRegistrationFutures: <String, Future<void>>{},
        requireAll: true,
      ),
      throwsException,
    );
  });

  test('ensureRegistered reconciles known accounts when account lookup fails', () async {
    final recordedRegistrations = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      getAccounts: () async => throw Exception('accounts unavailable'),
      registerSignerCallback: (pubkey) async {
        recordedRegistrations.add(pubkey);
      },
    );

    await registry.ensureRegistered(
      registeredExternalSignerPubkeys: <String>{},
      externalSignerRegistrationFutures: <String, Future<void>>{},
      knownAccounts: [
        _account(testPubkeyA, AccountType.external_),
        _account(testPubkeyB, AccountType.local),
      ],
    );

    expect(recordedRegistrations, [testPubkeyA]);
  });

  test('reconcile skips Android callback registration when disabled', () async {
    final recordedRegistrations = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: false,
      registerSignerCallback: (pubkey) async {
        recordedRegistrations.add(pubkey);
      },
    );

    await registry.reconcile(
      [
        _account(testPubkeyA, AccountType.external_),
      ],
      registeredExternalSignerPubkeys: <String>{},
      externalSignerRegistrationFutures: <String, Future<void>>{},
    );

    expect(recordedRegistrations, isEmpty);
  });

  test('reconcile uses owner-owned registration state across registry instances', () async {
    final recordedRegistrations = <String>[];
    final registeredPubkeys = <String>{};
    final registrationFutures = <String, Future<void>>{};

    ExternalSignerCallbackRegistry newRegistry() {
      return ExternalSignerCallbackRegistry(
        enabled: true,
        registerSignerCallback: (pubkey) async {
          recordedRegistrations.add(pubkey);
        },
      );
    }

    for (final registry in [newRegistry(), newRegistry()]) {
      await registry.reconcile(
        [
          _account(testPubkeyA, AccountType.external_),
        ],
        registeredExternalSignerPubkeys: registeredPubkeys,
        externalSignerRegistrationFutures: registrationFutures,
      );
    }

    expect(recordedRegistrations, [testPubkeyA]);
  });
}
