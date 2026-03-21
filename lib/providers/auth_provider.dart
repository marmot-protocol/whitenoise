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
  @override
  Future<String?> build() async {
    final storage = ref.read(secureStorageProvider);
    final pubkey = await storage.read(key: _storageKey);
    if (pubkey == null || pubkey.isEmpty) return null;

    try {
      final account = await accounts_api.getAccount(pubkey: pubkey);
      if (account.accountType == accounts_api.AccountType.external_) {
        await const AndroidSignerService().registerExternalSigner(pubkey);
      }
    } catch (e) {
      if (e is ApiError_Whitenoise && e.message.contains('Account not found')) {
        await storage.delete(key: _storageKey);
        return null;
      }
    }
    return pubkey;
  }

  // ---------------------------------------------------------------------------
  // Multi-step login (nsec / hex private key)
  // ---------------------------------------------------------------------------

  Future<accounts_api.LoginResult> loginStart(String nsec) async {
    _logger.info('Login start attempt');
    final result = await accounts_api.loginStart(nsecOrHexPrivkey: nsec);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account.pubkey);
    }

    return result;
  }

  Future<accounts_api.LoginResult> loginPublishDefaultRelays(String pubkey) async {
    _logger.info('Publishing default relays for $pubkey');
    final result = await accounts_api.loginPublishDefaultRelays(pubkey: pubkey);

    if (result.status == accounts_api.LoginStatus.complete) {
      await _completeLogin(result.account.pubkey);
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
      await _completeLogin(result.account.pubkey);
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
      await _completeLogin(result.account.pubkey);
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
      await _completeLogin(result.account.pubkey);
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
      await _completeLogin(result.account.pubkey);
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
      await accounts_api.getAccount(pubkey: pubkey);
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _completeLogin(String pubkey) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _storageKey, value: pubkey);
    state = AsyncData(pubkey);
    ref.read(isAddingAccountProvider.notifier).set(false);
    _logger.info('Login completed for $pubkey');
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
