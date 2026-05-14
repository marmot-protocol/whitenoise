import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise_frb/src/rust/api/chat_summary.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';

AsyncSnapshot<ChatSummary> useChatSummary(
  BuildContext context,
  String pubkey,
  String groupId,
) {
  final refreshKey = useState(0);
  useRouteRefresh(context, () => refreshKey.value++);
  final future = useMemoized(
    () => getChatSummary(accountPubkey: pubkey, mlsGroupId: groupId),
    [pubkey, groupId, refreshKey.value],
  );
  return useFuture(future);
}
