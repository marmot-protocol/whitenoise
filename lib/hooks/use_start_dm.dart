import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

final _logger = Logger('useStartDm');

typedef StartDmState = ({
  bool isLoading,
  Future<String> Function() startDm,
});

StartDmState useStartDm({
  required String accountPubkey,
  required String peerPubkey,
}) {
  final isLoading = useState(false);

  Future<String> startDm() async {
    isLoading.value = true;
    try {
      final existingGroupId = await account_groups_api.getDmGroupWithPeer(
        accountPubkey: accountPubkey,
        peerPubkey: peerPubkey,
      );

      if (existingGroupId != null) {
        return existingGroupId;
      }

      final group = await groups_api.createGroup(
        creatorPubkey: accountPubkey,
        memberPubkeys: [peerPubkey],
        adminPubkeys: [accountPubkey],
        groupName: '',
        groupDescription: '',
        groupType: groups_api.GroupType.directMessage,
      );
      return group.mlsGroupId;
    } catch (e) {
      _logger.severe('Failed to start DM: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  return (
    isLoading: isLoading.value,
    startDm: startDm,
  );
}
