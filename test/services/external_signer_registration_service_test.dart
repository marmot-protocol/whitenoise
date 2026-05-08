import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/external_signer_registration_service.dart';
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
    final service = ExternalSignerRegistrationService(
      registerExternalSigner: (pubkey) async {
        if (pubkey == testPubkeyA) {
          throw Exception('signer unavailable');
        }
        registeredPubkeys.add(pubkey);
      },
    );

    await service.reconcile([
      _account(testPubkeyA, AccountType.external_),
      _account(testPubkeyB, AccountType.external_),
      _account(testPubkeyC, AccountType.local),
      _account(testPubkeyD, AccountType.external_),
    ]);

    expect(registeredPubkeys, [testPubkeyB, testPubkeyD]);
  });

  test('reconcile rethrows when a required account registration fails', () async {
    final registeredPubkeys = <String>[];
    final service = ExternalSignerRegistrationService(
      registerExternalSigner: (pubkey) async {
        if (pubkey == testPubkeyB) {
          throw Exception('active signer unavailable');
        }
        registeredPubkeys.add(pubkey);
      },
    );

    await expectLater(
      service.reconcile(
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
}
