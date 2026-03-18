import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/utils/logging.dart';

final _logger = Logger('UserService');

class UserService {
  final String pubkey;

  const UserService(this.pubkey);

  Future<FlutterMetadata> fetchMetadata() async {
    final sw = Stopwatch()..start();
    try {
      final userMetadata = await users_api.userMetadata(
        pubkey: pubkey,
        blockingDataSync: false,
      );
      logDuration(
        _logger,
        'userMetadata with blockingDataSync: false for $pubkey took',
        sw.elapsedMilliseconds,
      );

      if (_isMetadataEmpty(userMetadata)) {
        sw.reset();
        final remoteMetadata = await users_api.userMetadata(
          pubkey: pubkey,
          blockingDataSync: true,
        );
        logDuration(
          _logger,
          'userMetadata with blockingDataSync: true for $pubkey took',
          sw.elapsedMilliseconds,
        );
        return remoteMetadata;
      }

      return userMetadata;
    } catch (e, stackTrace) {
      logDuration(
        _logger,
        'userMetadata failed for $pubkey after',
        sw.elapsedMilliseconds,
      );
      _logger.severe('Failed to fetch metadata for $pubkey', e, stackTrace);
      rethrow;
    }
  }

  Future<User?> fetchUser() async {
    final sw = Stopwatch()..start();
    try {
      final user = await users_api.getUser(pubkey: pubkey, blockingDataSync: false);
      logDuration(
        _logger,
        'getUser with blockingDataSync: false for $pubkey took',
        sw.elapsedMilliseconds,
      );

      if (!_isMetadataEmpty(user.metadata)) return user;

      sw.reset();
      final remoteUser = await users_api.getUser(pubkey: pubkey, blockingDataSync: true);
      logDuration(
        _logger,
        'getUser with blockingDataSync: true for $pubkey took',
        sw.elapsedMilliseconds,
      );
      return remoteUser;
    } catch (e) {
      _logger.severe('Failed to fetch user for $pubkey after ${sw.elapsedMilliseconds}ms', e);
      return null;
    }
  }

  bool _isMetadataEmpty(FlutterMetadata userMetadata) {
    return _isFieldEmpty(userMetadata.name) &&
        _isFieldEmpty(userMetadata.displayName) &&
        _isFieldEmpty(userMetadata.picture);
  }

  bool _isFieldEmpty(String? value) {
    return value == null || value.isEmpty;
  }
}
