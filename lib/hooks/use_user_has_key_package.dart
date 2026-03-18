import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/utils/logging.dart';

final _logger = Logger('useUserHasKeyPackage');

AsyncSnapshot<users_api.KeyPackageStatus> useUserHasKeyPackage(String pubkey) {
  final future = useMemoized(
    () async {
      final stopWatch = Stopwatch()..start();
      final status = await users_api.userHasKeyPackage(
        pubkey: pubkey,
        blockingDataSync: false,
      );
      logDuration(
        _logger,
        'userHasKeyPackage with blockingDataSync: false responded with status: $status and took',
        stopWatch.elapsedMilliseconds,
      );

      if (status != users_api.KeyPackageStatus.notFound) return status;

      stopWatch.reset();
      final remoteStatus = await users_api.userHasKeyPackage(
        pubkey: pubkey,
        blockingDataSync: true,
      );
      logDuration(
        _logger,
        'userHasKeyPackage with blockingDataSync: true responded with status: $remoteStatus and took',
        stopWatch.elapsedMilliseconds,
      );
      return remoteStatus;
    },
    [pubkey],
  );
  return useFuture(future);
}
