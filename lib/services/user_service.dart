import 'package:logging/logging.dart';
import 'package:whitenoise/profiling/tracer.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;

final _logger = Logger('UserService');

class UserService {
  final String pubkey;

  const UserService(this.pubkey);

  Future<FlutterMetadata> fetchMetadata() async {
    final fast = await Tracer.traceAsync(
      'user.fetch_metadata_fast',
      () => users_api.userMetadata(pubkey: pubkey, blockingDataSync: false),
    );

    if (_isMetadataEmpty(fast)) {
      final blocking = await Tracer.traceAsync(
        'user.fetch_metadata_blocking_relay_sync',
        () => users_api.userMetadata(pubkey: pubkey, blockingDataSync: true),
      );
      return blocking;
    }

    return fast;
  }

  Future<User?> fetchUser() async {
    try {
      final span = Tracer.begin('user.fetch_user_total');

      final fast = await Tracer.traceAsync(
        'user.fetch_user_fast',
        () => users_api.getUser(pubkey: pubkey, blockingDataSync: false),
      );
      if (!_isMetadataEmpty(fast.metadata)) {
        span.end();
        return fast;
      }

      final blocking = await Tracer.traceAsync(
        'user.fetch_user_blocking_relay_sync',
        () => users_api.getUser(pubkey: pubkey, blockingDataSync: true),
      );
      span.end();
      return blocking;
    } catch (e) {
      _logger.warning('Failed to fetch user', e);
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
