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
    final registeredPubkeys = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      registerSignerCallback: (pubkey) async {
        if (pubkey == testPubkeyA) {
          throw Exception('signer unavailable');
        }
        registeredPubkeys.add(pubkey);
      },
    );

    await registry.reconcile([
      _account(testPubkeyA, AccountType.external_),
      _account(testPubkeyB, AccountType.external_),
      _account(testPubkeyC, AccountType.local),
      _account(testPubkeyD, AccountType.external_),
    ]);

    expect(registeredPubkeys, [testPubkeyB, testPubkeyD]);
  });

  test('reconcile rethrows when a required account registration fails', () async {
    final registeredPubkeys = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: true,
      registerSignerCallback: (pubkey) async {
        if (pubkey == testPubkeyB) {
          throw Exception('active signer unavailable');
        }
        registeredPubkeys.add(pubkey);
      },
    );

    await expectLater(
      registry.reconcile(
        [
          _account(testPubkeyA, AccountType.external_),
          _account(testPubkeyB, AccountType.external_),
          _account(testPubkeyD, AccountType.external_),
        ],
        requiredPubkeys: {testPubkeyB},
      ),
      throwsException,
    );

    expect(registeredPubkeys, [testPubkeyA]);
  });

  test('reconcile skips Android callback registration when disabled', () async {
    final registeredPubkeys = <String>[];
    final registry = ExternalSignerCallbackRegistry(
      enabled: false,
      registerSignerCallback: (pubkey) async {
        registeredPubkeys.add(pubkey);
      },
    );

    await registry.reconcile([
      _account(testPubkeyA, AccountType.external_),
    ]);

    expect(registeredPubkeys, isEmpty);
  });
}
