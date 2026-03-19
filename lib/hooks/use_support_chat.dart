import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;

const supportPubkey = '1136006d965b8ffb0e8d0e842750d68a6cd06093957f14bcefb47bb228f0cc35';

typedef SupportChatState = ({
  bool isLoading,
  String? existingGroupId,
});

SupportChatState useSupportChat({required String? accountPubkey}) {
  final future = useMemoized(() {
    if (accountPubkey == null) return Future<String?>.value();

    return account_groups_api.getDmGroupWithPeer(
      accountPubkey: accountPubkey,
      peerPubkey: supportPubkey,
    );
  }, [accountPubkey]);
  final snapshot = useFuture(future);

  return (
    isLoading: snapshot.connectionState == ConnectionState.waiting,
    existingGroupId: snapshot.hasError ? null : snapshot.data,
  );
}
