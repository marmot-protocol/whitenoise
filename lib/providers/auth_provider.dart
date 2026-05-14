import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/is_adding_account_provider.dart';
import 'package:whitenoise/services/android_signer_service.dart';
import 'package:whitenoise/services/external_signer_callback_registry.dart';
import 'package:whitenoise_frb/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise_frb/src/rust/api/error.dart';

const _storageKey = 'active_account_pubkey';
final _logger = Logger('AuthNotifier');

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

class AuthNotifier extends AsyncNotifier<String?> {
  final _externalSignerCallbackRegistry = ExternalSignerCallbackRegistry();
  final _registeredExternalSignerPubkeys = <String>{};
  final _externalSignerRegistrationFutures = <String, Future<void>>{};

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
      requiredPubkeys: activeAccount == null ? const {} : {activeAccount.pubkey},
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
    await storage.delete(key: _storageKey);

    try {
      final remainingAccounts = await accounts_api.getAccounts();
      final otherAccounts = remainingAccounts.where((a) => a.pubkey != pubkey).toList();
      final nextAccount = otherAccounts.isEmpty ? null : otherAccounts.first;
      await _externalSignerCallbackRegistry.reconcile(
        remainingAccounts,
        registeredExternalSignerPubkeys: _registeredExternalSignerPubkeys,
        externalSignerRegistrationFutures: _externalSignerRegistrationFutures,
        requiredPubkeys: nextAccount == null ? const {} : {nextAccount.pubkey},
      );
      if (nextAccount != null) {
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
      await _ensureExternalSignersRegistered(
        knownAccounts: [account],
        requiredPubkeys: {account.pubkey},
      );
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
      await _ensureExternalSignersRegistered(
        knownAccounts: [account],
        requiredPubkeys: {account.pubkey},
      );
    }
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _storageKey, value: account.pubkey);
    state = AsyncData(account.pubkey);
    ref.read(isAddingAccountProvider.notifier).set(false);
    _logger.info('Login completed for ${account.accountType.name} account');
  }

  Future<void> _ensureExternalSignersRegistered({
    Iterable<accounts_api.Account> knownAccounts = const [],
    Set<String> requiredPubkeys = const {},
  }) async {
    await _externalSignerCallbackRegistry.ensureRegistered(
      registeredExternalSignerPubkeys: _registeredExternalSignerPubkeys,
      externalSignerRegistrationFutures: _externalSignerRegistrationFutures,
      knownAccounts: knownAccounts,
      requiredPubkeys: requiredPubkeys,
    );
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
