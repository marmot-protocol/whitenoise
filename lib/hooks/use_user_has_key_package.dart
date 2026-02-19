import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/users.dart' as users_api;

AsyncSnapshot<users_api.KeyPackageStatus> useUserHasKeyPackage(String pubkey) {
  final future = useMemoized(
    () async {
      final status = await users_api.userHasKeyPackage(
        pubkey: pubkey,
        blockingDataSync: false,
      );
      if (status != users_api.KeyPackageStatus.notFound) return status;
      return users_api.userHasKeyPackage(pubkey: pubkey, blockingDataSync: true);
    },
    [pubkey],
  );
  return useFuture(future);
}
