import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:logging/logging.dart';
import 'package:whitenoise/services/android_signer_service.dart';
import 'package:whitenoise_frb/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('ExternalSignerCallbackRegistry');

class ExternalSignerCallbackRegistry {
  ExternalSignerCallbackRegistry({
    bool? enabled,
    Future<List<accounts_api.Account>> Function()? getAccounts,
    Future<void> Function(String pubkey)? registerSignerCallback,
  }) : _enabled = enabled ?? (defaultTargetPlatform == TargetPlatform.android),
       _getAccounts = getAccounts ?? accounts_api.getAccounts,
       _registerSignerCallback =
           registerSignerCallback ?? const AndroidSignerService().registerExternalSigner;

  final bool _enabled;
  final Future<List<accounts_api.Account>> Function() _getAccounts;
  final Future<void> Function(String pubkey) _registerSignerCallback;

  Future<void> ensureRegistered({
    required Set<String> registeredExternalSignerPubkeys,
    required Map<String, Future<void>> externalSignerRegistrationFutures,
    Iterable<accounts_api.Account> knownAccounts = const [],
    Set<String> requiredPubkeys = const {},
    bool requireAll = false,
  }) async {
    if (!_enabled) return;

    List<accounts_api.Account> persistedAccounts;
    try {
      persistedAccounts = await _getAccounts();
    } catch (e, stackTrace) {
      if (knownAccounts.isEmpty) {
        _logger.warning('Failed to reconcile external signers', e, stackTrace);
        if (requireAll) rethrow;
        return;
      }
      _logger.warning('Failed to fetch accounts while reconciling external signers', e, stackTrace);
      await reconcile(
        knownAccounts,
        registeredExternalSignerPubkeys: registeredExternalSignerPubkeys,
        externalSignerRegistrationFutures: externalSignerRegistrationFutures,
        requiredPubkeys: requiredPubkeys,
        requireAll: requireAll,
      );
      return;
    }

    await reconcile(
      [...persistedAccounts, ...knownAccounts],
      registeredExternalSignerPubkeys: registeredExternalSignerPubkeys,
      externalSignerRegistrationFutures: externalSignerRegistrationFutures,
      requiredPubkeys: requiredPubkeys,
      requireAll: requireAll,
    );
  }

  Future<void> reconcile(
    Iterable<accounts_api.Account> accounts, {
    required Set<String> registeredExternalSignerPubkeys,
    required Map<String, Future<void>> externalSignerRegistrationFutures,
    Set<String> requiredPubkeys = const {},
    bool requireAll = false,
  }) async {
    if (!_enabled) return;

    final externalAccountsByPubkey = <String, accounts_api.Account>{};
    for (final account in accounts) {
      if (account.accountType == accounts_api.AccountType.external_) {
        externalAccountsByPubkey[account.pubkey] = account;
      }
    }

    registeredExternalSignerPubkeys.removeWhere(
      (pubkey) => !externalAccountsByPubkey.containsKey(pubkey),
    );

    if (externalAccountsByPubkey.isEmpty) return;

    _logger.fine(
      'Ensuring external signer callbacks for ${externalAccountsByPubkey.length} account(s)',
    );
    await _registerMissingExternalSigners(
      externalAccountsByPubkey.values,
      registeredExternalSignerPubkeys: registeredExternalSignerPubkeys,
      externalSignerRegistrationFutures: externalSignerRegistrationFutures,
      requiredPubkeys: requireAll ? externalAccountsByPubkey.keys.toSet() : requiredPubkeys,
    );
  }

  Future<void> _registerMissingExternalSigners(
    Iterable<accounts_api.Account> accounts, {
    required Set<String> registeredExternalSignerPubkeys,
    required Map<String, Future<void>> externalSignerRegistrationFutures,
    Set<String> requiredPubkeys = const {},
  }) async {
    for (final account in accounts) {
      try {
        await _registerExternalSignerIfMissing(
          account,
          registeredExternalSignerPubkeys: registeredExternalSignerPubkeys,
          externalSignerRegistrationFutures: externalSignerRegistrationFutures,
        );
      } catch (e, stackTrace) {
        if (requiredPubkeys.contains(account.pubkey)) rethrow;
        _logger.warning(
          'Failed to register optional external signer callback',
          e,
          stackTrace,
        );
      }
    }
  }

  Future<void> _registerExternalSignerIfMissing(
    accounts_api.Account account, {
    required Set<String> registeredExternalSignerPubkeys,
    required Map<String, Future<void>> externalSignerRegistrationFutures,
  }) async {
    if (account.accountType != accounts_api.AccountType.external_) return;
    final pubkey = account.pubkey;
    if (registeredExternalSignerPubkeys.contains(pubkey)) return;

    final inFlightRegistration = externalSignerRegistrationFutures[pubkey];
    if (inFlightRegistration != null) {
      await inFlightRegistration;
      return;
    }

    final registration = _registerSignerCallback(pubkey).then((_) {
      registeredExternalSignerPubkeys.add(pubkey);
      _logger.info('Registered external signer callback');
    });
    externalSignerRegistrationFutures[pubkey] = registration;
    try {
      await registration;
    } finally {
      externalSignerRegistrationFutures.remove(pubkey);
    }
  }
}
