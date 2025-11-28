import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/src/rust/api.dart' show createWhitenoiseConfig, initializeWhitenoise;
import 'package:whitenoise/src/rust/api/accounts.dart';

class AuthService {
  final _logger = Logger('AuthService');

  /// Initialize Whitenoise and Rust backend
  Future<void> initialize() async {
    try {
      /// 1. Create data and logs directories
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      /// 2. Create config and initialize Whitenoise instance
      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );
      await initializeWhitenoise(config: config);
    } catch (e, st) {
      _logger.severe('initialize', e, st);
      rethrow;
    }
  }

  /// Get all accounts
  Future<List<Account>> getAccountsList() async {
    try {
      return await getAccounts();
    } catch (e, st) {
      _logger.severe('getAccounts', e, st);
      rethrow;
    }
  }

  /// Create a new identity
  Future<Account> createIdentityAccount() async {
    try {
      return await createIdentity();
    } catch (e, st) {
      _logger.severe('createIdentity', e, st);
      rethrow;
    }
  }

  /// Login with private key
  Future<Account> loginWithKey(String nsecOrHexPrivkey) async {
    try {
      return await login(nsecOrHexPrivkey: nsecOrHexPrivkey);
    } catch (e, st) {
      _logger.severe('loginWithKey', e, st);
      rethrow;
    }
  }

  /// Logout account
  Future<void> logoutAccount(String pubkey) async {
    try {
      await logout(pubkey: pubkey);
    } catch (e, st) {
      _logger.severe('logoutAccount', e, st);
      rethrow;
    }
  }
}
