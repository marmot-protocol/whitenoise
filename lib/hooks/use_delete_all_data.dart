import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api.dart' as api;

final _logger = Logger('useDeleteAllData');

class DeleteAllDataState {
  final bool isDeleting;

  const DeleteAllDataState({
    this.isDeleting = false,
  });

  DeleteAllDataState copyWith({
    bool? isDeleting,
  }) {
    return DeleteAllDataState(
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

({
  DeleteAllDataState state,
  Future<bool> Function() deleteAllData,
})
useDeleteAllData() {
  final state = useState(const DeleteAllDataState());
  final isMountedRef = useRef(true);

  useEffect(() {
    return () {
      isMountedRef.value = false;
    };
  }, const []);

  Future<bool> deleteAllData() async {
    state.value = state.value.copyWith(isDeleting: true);
    try {
      _logger.info('Deleting all application data');
      await api.deleteAllData();
      _logger.info('All data deleted successfully');
      if (isMountedRef.value) {
        state.value = state.value.copyWith(isDeleting: false);
      }
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete all data', e, stackTrace);
      if (isMountedRef.value) {
        state.value = state.value.copyWith(isDeleting: false);
      }
      return false;
    }
  }

  return (
    state: state.value,
    deleteAllData: deleteAllData,
  );
}
