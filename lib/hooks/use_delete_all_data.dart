import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api.dart' as api;
import 'package:whitenoise/utils/reset_marker.dart';

final _logger = Logger('useDeleteAllData');

enum DeleteAllDataFailure {
  deleteFailed,
  reinitializeFailed,
}

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
  DeleteAllDataFailure? Function() latestFailure,
  Object? Function() latestError,
  StackTrace? Function() latestStackTrace,
})
useDeleteAllData() {
  final state = useState(const DeleteAllDataState());
  final isMountedRef = useRef(true);
  final latestFailureRef = useRef<DeleteAllDataFailure?>(null);
  final latestErrorRef = useRef<Object?>(null);
  final latestStackTraceRef = useRef<StackTrace?>(null);

  useEffect(() {
    return () {
      isMountedRef.value = false;
    };
  }, const []);

  Future<bool> deleteAllData() async {
    state.value = state.value.copyWith(isDeleting: true);
    latestFailureRef.value = null;
    latestErrorRef.value = null;
    latestStackTraceRef.value = null;
    try {
      _logger.info('Deleting all application data');
      await markResetPending();
      await api.deleteAllData();
    } catch (e, stackTrace) {
      latestFailureRef.value = DeleteAllDataFailure.deleteFailed;
      latestErrorRef.value = e;
      latestStackTraceRef.value = stackTrace;
      _logger.severe('Failed to delete all data', e, stackTrace);
      if (isMountedRef.value) {
        state.value = state.value.copyWith(isDeleting: false);
      }
      return false;
    }

    try {
      await api.reinitializeWhitenoise();
      await clearResetPending();
      _logger.info('All data deleted successfully');
      if (isMountedRef.value) {
        state.value = state.value.copyWith(isDeleting: false);
      }
      return true;
    } catch (e, stackTrace) {
      latestFailureRef.value = DeleteAllDataFailure.reinitializeFailed;
      latestErrorRef.value = e;
      latestStackTraceRef.value = stackTrace;
      _logger.severe('Data deleted, but failed to reinitialize Whitenoise', e, stackTrace);
      if (isMountedRef.value) {
        state.value = state.value.copyWith(isDeleting: false);
      }
      return false;
    }
  }

  return (
    state: state.value,
    deleteAllData: deleteAllData,
    latestFailure: () => latestFailureRef.value,
    latestError: () => latestErrorRef.value,
    latestStackTrace: () => latestStackTraceRef.value,
  );
}
