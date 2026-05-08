import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/is_adding_account_provider.dart';
import 'package:whitenoise/services/android_signer_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/error.dart';

const _storageKey = 'active_account_pubkey';
final _logger = Logger('AuthNotifier');

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

class AuthNotifier extends AsyncNotifier<String?> {
  final Set<String> _registeredExternalSignerPubkeys = {};
  final Map<String, Future<void>> _externalSignerRegistrationFutures = {};

  @override
  Future<String?> build() async {
    final storage = ref.read(secureStorageProvider);
    final pubkey = await storage.read(key: _storageKey);
    accounts_api.Account? activeAccount;
    var activePubkey = pubkey;

    if (pubkey != null && pubkey.isNotEmpty) {
      try {
        activeAccount = await accounts_api.getAccount(pubkey: pubkey);
      } catch (e) {
        if (e is ApiError_Whitenoise && e.message.contains('Account not found')) {
          await storage.delete(key: _storageKey);
          activePubkey = null;
        }
      }
    }

    await _ensureExternalSignersRegistered(
      knownAccounts: activeAccount == null ? const [] : [activeAccount],
    );

    if (activePubkey == null || activePubkey.isEmpty) return null;
    return activePubkey;
  }

  // ---------------------------------------------------------------------------
  // Multi-step login (nsec / hex private key)
  // ---------------------------------------------------------------------------

  Future<accounts_api.LoginResult> loginStart(String nsec) async {
    _logger.info('Login start attempt');
    final result = await accounts_api.loginStart(nsecOrHexPrivkey: nsec);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  Future<accounts_api.LoginResult> loginPublishDefaultRelays(String pubkey) async {
    _logger.info('Publishing default relays for $pubkey');
    final result = await accounts_api.loginPublishDefaultRelays(pubkey: pubkey);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  Future<accounts_api.LoginResult> loginWithCustomRelay(
    String pubkey,
    String relayUrl,
  ) async {
    _logger.info('Trying custom relay $relayUrl for $pubkey');
    final result = await accounts_api.loginWithCustomRelay(
      pubkey: pubkey,
      relayUrl: relayUrl,
    );

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  Future<void> loginCancel(String pubkey) async {
    _logger.info('Cancelling login for $pubkey');
    await accounts_api.loginCancel(pubkey: pubkey);
  }

  // ---------------------------------------------------------------------------
  // Multi-step login (external signer / NIP-55)
  // ---------------------------------------------------------------------------

  Future<accounts_api.LoginResult> loginExternalSignerStart({
    required String pubkey,
  }) async {
    _logger.info('External signer login start attempt');
    final signerService = const AndroidSignerService();
    final result = await signerService.loginExternalSignerStart(pubkey);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  Future<accounts_api.LoginResult> loginExternalSignerPublishDefaultRelays(
    String pubkey,
  ) async {
    _logger.info('External signer: publishing default relays for $pubkey');
    final signerService = const AndroidSignerService();
    final result = await signerService.loginExternalSignerPublishDefaultRelays(pubkey);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  Future<accounts_api.LoginResult> loginExternalSignerWithCustomRelay(
    String pubkey,
    String relayUrl,
  ) async {
    _logger.info('External signer: trying custom relay $relayUrl for $pubkey');
    final signerService = const AndroidSignerService();
    final result = await signerService.loginExternalSignerWithCustomRelay(pubkey, relayUrl);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Signup / Logout / Profile switching
  // ---------------------------------------------------------------------------

  Future<String> signup() async {
    _logger.info('Signup started');
    final storage = ref.read(secureStorageProvider);
    final account = await accounts_api.createIdentity();
    await storage.write(key: _storageKey, value: account.pubkey);
    state = AsyncData(account.pubkey);
    ref.read(isAddingAccountProvider.notifier).set(false);
    _logger.info('Signup successful - identity created');
    return account.pubkey;
  }

  Future<String?> logout() async {
    final pubkey = state.value;
    if (pubkey == null) return null;

    _logger.info('Logout started');
    final storage = ref.read(secureStorageProvider);

    await accounts_api.logout(pubkey: pubkey);
    _registeredExternalSignerPubkeys.remove(pubkey);
    await storage.delete(key: _storageKey);

    try {
      final remainingAccounts = await accounts_api.getAccounts();
      await _reconcileExternalSigners(remainingAccounts);
      final otherAccounts = remainingAccounts.where((a) => a.pubkey != pubkey).toList();
      if (otherAccounts.isNotEmpty) {
        final nextAccount = otherAccounts.first;
        await storage.write(key: _storageKey, value: nextAccount.pubkey);
        state = AsyncData(nextAccount.pubkey);
        _logger.info('Logout successful - switched to another account');
        return nextAccount.pubkey;
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to switch to next account after logout', e, stackTrace);
    }

    state = const AsyncData(null);
    _logger.info('Logout successful - no remaining accounts');
    return null;
  }

  Future<void> resetAuth() async {
    _logger.info('Resetting auth state');
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _storageKey);
    state = const AsyncData(null);
    _logger.info('Auth state reset complete');
  }

  Future<void> switchProfile(String pubkey) async {
    _logger.info('Switching profile');
    final storage = ref.read(secureStorageProvider);
    try {
      final account = await accounts_api.getAccount(pubkey: pubkey);
      await _ensureExternalSignersRegistered(knownAccounts: [account]);
      await storage.write(key: _storageKey, value: pubkey);
      state = AsyncData(pubkey);
      _logger.info('Profile switched successfully');
    } catch (e) {
      if (e is ApiError_Whitenoise && e.message.contains('Account not found')) {
        _logger.warning('Account not found during switch');
        await storage.delete(key: _storageKey);
        state = const AsyncData(null);
      } else {
        rethrow;
      }
    }
  }

  Future<void> ensureExternalSignersRegistered() async {
    await _ensureExternalSignersRegistered();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _completeLogin(accounts_api.Account account) async {
    if (account.accountType == accounts_api.AccountType.external_) {
      await _ensureExternalSignersRegistered(knownAccounts: [account]);
    }
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _storageKey, value: account.pubkey);
    state = AsyncData(account.pubkey);
    ref.read(isAddingAccountProvider.notifier).set(false);
    _logger.info('Login completed for ${account.pubkey}');
  }

  Future<void> _ensureExternalSignersRegistered({
    Iterable<accounts_api.Account> knownAccounts = const [],
  }) async {
    try {
      final persistedAccounts = await accounts_api.getAccounts();
      await _reconcileExternalSigners([...persistedAccounts, ...knownAccounts]);
    } catch (e, stackTrace) {
      if (knownAccounts.isEmpty) {
        _logger.warning('Failed to reconcile external signers', e, stackTrace);
        return;
      }
      _logger.warning('Failed to fetch accounts while reconciling external signers', e, stackTrace);
      await _registerMissingExternalSigners(knownAccounts);
    }
  }

  Future<void> _reconcileExternalSigners(Iterable<accounts_api.Account> accounts) async {
    final externalAccountsByPubkey = <String, accounts_api.Account>{};
    for (final account in accounts) {
      if (account.accountType == accounts_api.AccountType.external_) {
        externalAccountsByPubkey[account.pubkey] = account;
      }
    }

    _registeredExternalSignerPubkeys.removeWhere(
      (pubkey) => !externalAccountsByPubkey.containsKey(pubkey),
    );

    await _registerMissingExternalSigners(externalAccountsByPubkey.values);
  }

  Future<void> _registerMissingExternalSigners(Iterable<accounts_api.Account> accounts) async {
    for (final account in accounts) {
      await _registerExternalSignerIfMissing(account);
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

    final registration = const AndroidSignerService().registerExternalSigner(pubkey).then((_) {
      _registeredExternalSignerPubkeys.add(pubkey);
    });
    _externalSignerRegistrationFutures[pubkey] = registration;
    try {
      await registration;
    } finally {
      _externalSignerRegistrationFutures.remove(pubkey);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
