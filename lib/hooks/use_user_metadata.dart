import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';

AsyncSnapshot<FlutterMetadata> useUserMetadata(
  BuildContext context,
  String? pubkey,
) {
  final refreshKey = useState(0);

  useRouteRefresh(context, () => refreshKey.value++);

  final stream = useMemoized(
    () => pubkey != null ? UserService(pubkey).watchMetadata() : null,
    [pubkey, refreshKey.value],
  );
  return useStream(stream);
}
