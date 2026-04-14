import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

typedef LeaveGroupState = ({
  bool isLoading,
  Future<void> Function() leaveGroup,
});

LeaveGroupState useLeaveGroup({
  required String accountPubkey,
  required String groupId,
}) {
  final isLoading = useState(false);
  final isDisposed = useRef(false);

  useEffect(() {
    isDisposed.value = false;
    return () {
      isDisposed.value = true;
    };
  }, []);

  Future<void> leaveGroup() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      await groups_api.leaveGroup(pubkey: accountPubkey, groupId: groupId);
    } finally {
      if (!isDisposed.value) {
        isLoading.value = false;
      }
    }
  }

  return (
    isLoading: isLoading.value,
    leaveGroup: leaveGroup,
  );
}
