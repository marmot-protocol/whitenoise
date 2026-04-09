import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

final _logger = Logger('useDisappearingMessages');

const disappearingMessageOptions = [
  null, // Off
  30, // 30 seconds
  300, // 5 minutes
  3600, // 1 hour
  86400, // 1 day
  604800, // 1 week
];

({
  int? currentDurationSecs,
  bool isLoading,
  bool isSaving,
  String? error,
  Future<void> Function() load,
  Future<bool> Function(int? durationSecs) setDuration,
})
useDisappearingMessages({
  required String accountPubkey,
  required String groupId,
}) {
  final currentDurationSecs = useState<int?>(null);
  final isLoading = useState(false);
  final isSaving = useState(false);
  final error = useState<String?>(null);

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final duration = await groups_api.getDisappearingMessageDuration(
        accountPubkey: accountPubkey,
        groupId: groupId,
      );
      currentDurationSecs.value = duration?.toInt();
    } catch (e) {
      _logger.severe('Failed to load disappearing message duration: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> setDuration(int? durationSecs) async {
    isSaving.value = true;
    error.value = null;
    try {
      await groups_api.setDisappearingMessages(
        accountPubkey: accountPubkey,
        groupId: groupId,
        durationSecs: durationSecs != null ? BigInt.from(durationSecs) : null,
      );
      currentDurationSecs.value = durationSecs;
      return true;
    } catch (e) {
      _logger.severe('Failed to set disappearing message duration: $e');
      error.value = e.toString();
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  useEffect(() {
    load();
    return null;
  }, [accountPubkey, groupId]);

  return (
    currentDurationSecs: currentDurationSecs.value,
    isLoading: isLoading.value,
    isSaving: isSaving.value,
    error: error.value,
    load: load,
    setDuration: setDuration,
  );
}
