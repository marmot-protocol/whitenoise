import 'package:logging/logging.dart';
import 'package:whitenoise/services/android_signer_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('ExternalSignerRegistration');

class ExternalSignerRegistrationService {
  ExternalSignerRegistrationService({
    Future<List<accounts_api.Account>> Function()? getAccounts,
    Future<void> Function(String pubkey)? registerExternalSigner,
  }) : _getAccounts = getAccounts ?? accounts_api.getAccounts,
       _registerExternalSigner =
           registerExternalSigner ?? const AndroidSignerService().registerExternalSigner;

  final Future<List<accounts_api.Account>> Function() _getAccounts;
  final Future<void> Function(String pubkey) _registerExternalSigner;
  final Set<String> _registeredExternalSignerPubkeys = {};
  final Map<String, Future<void>> _externalSignerRegistrationFutures = {};

  Future<void> ensureRegistered({
    Iterable<accounts_api.Account> knownAccounts = const [],
    Set<String> requiredPubkeys = const {},
  }) async {
    List<accounts_api.Account> persistedAccounts;
    try {
      persistedAccounts = await _getAccounts();
    } catch (e, stackTrace) {
      if (knownAccounts.isEmpty) {
        _logger.warning('Failed to reconcile external signers', e, stackTrace);
        return;
      }
      _logger.warning('Failed to fetch accounts while reconciling external signers', e, stackTrace);
      await _registerMissingExternalSigners(knownAccounts, requiredPubkeys: requiredPubkeys);
      return;
    }

    await reconcile(
      [...persistedAccounts, ...knownAccounts],
      requiredPubkeys: requiredPubkeys,
    );
  }

  Future<void> reconcile(
    Iterable<accounts_api.Account> accounts, {
    Set<String> requiredPubkeys = const {},
  }) async {
    final externalAccountsByPubkey = <String, accounts_api.Account>{};
    for (final account in accounts) {
      if (account.accountType == accounts_api.AccountType.external_) {
        externalAccountsByPubkey[account.pubkey] = account;
      }
    }

    _registeredExternalSignerPubkeys.removeWhere(
      (pubkey) => !externalAccountsByPubkey.containsKey(pubkey),
    );

    if (externalAccountsByPubkey.isEmpty) return;

    _logger.fine(
      'Ensuring external signer callbacks for ${externalAccountsByPubkey.length} account(s)',
    );
    await _registerMissingExternalSigners(
      externalAccountsByPubkey.values,
      requiredPubkeys: requiredPubkeys,
    );
  }

  Future<void> _registerMissingExternalSigners(
    Iterable<accounts_api.Account> accounts, {
    Set<String> requiredPubkeys = const {},
  }) async {
    for (final account in accounts) {
      try {
        await _registerExternalSignerIfMissing(account);
      } catch (e, stackTrace) {
        if (requiredPubkeys.contains(account.pubkey)) rethrow;
        _logger.warning(
          'Failed to register external signer callback for ${_pubkeyPreview(account.pubkey)}',
          e,
          stackTrace,
        );
      }
    }
  }

  Future<void> _registerExternalSignerIfMissing(accounts_api.Account account) async {
    if (account.accountType != accounts_api.AccountType.external_) return;
    final pubkey = account.pubkey;
    if (_registeredExternalSignerPubkeys.contains(pubkey)) return;

    final inFlightRegistration = _externalSignerRegistrationFutures[pubkey];
    if (inFlightRegistration != null) {
      await inFlightRegistration;
      return;
    }

    final registration = _registerExternalSigner(pubkey).then((_) {
      _registeredExternalSignerPubkeys.add(pubkey);
      _logger.info('Registered external signer callback for ${_pubkeyPreview(pubkey)}');
    });
    _externalSignerRegistrationFutures[pubkey] = registration;
    try {
      await registration;
    } finally {
      _externalSignerRegistrationFutures.remove(pubkey);
    }
  }

  String _pubkeyPreview(String pubkey) {
    if (pubkey.length <= 8) return pubkey;
    return '${pubkey.substring(0, 8)}...';
  }
}
