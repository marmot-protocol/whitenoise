import 'dart:async';

import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User, UserStreamItem;
import 'package:whitenoise/utils/logging.dart';

final _logger = Logger('UserService');

class UserService {
  final String pubkey;

  const UserService(this.pubkey);

  Stream<User> watchUser() {
    final stopwatch = Stopwatch()..start();
    var loggedInitial = false;

    return users_api
        .subscribeToUser(pubkey: pubkey)
        .transform(
          StreamTransformer<UserStreamItem, User>.fromHandlers(
            handleData: (item, sink) {
              final user = _userFromStreamItem(item);
              if (!loggedInitial) {
                loggedInitial = true;
                logDuration(
                  _logger,
                  'subscribeToUser initial snapshot for $pubkey took',
                  stopwatch.elapsedMilliseconds,
                );
              }
              sink.add(user);
            },
            handleError: (error, stackTrace, sink) {
              _logger.severe('Failed to watch user for $pubkey', error, stackTrace);
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  Stream<FlutterMetadata> watchMetadata() => watchUser().map((user) => user.metadata);

  Future<User> getInitialUser() => watchUser().first;

  Future<FlutterMetadata> getInitialMetadata() => watchMetadata().first;

  User _userFromStreamItem(UserStreamItem item) {
    return item.when(
      initialSnapshot: (user) => user,
      update: (update) => update.user,
    );
  }
}
