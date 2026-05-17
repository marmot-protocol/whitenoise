import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_delete_all_data.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/reset_marker.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockPathProvider();
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    debugMarkResetPending = () async {};
    debugClearResetPending = () async {};
    addTearDown(() async {
      debugMarkResetPending = null;
      debugClearResetPending = null;
    });
  });

  tearDown(() async {
    await clearResetPending();
  });

  group('DeleteAllDataState', () {
    test('copyWith preserves isDeleting when not provided', () {
      const state = DeleteAllDataState(isDeleting: true);
      final newState = state.copyWith();

      expect(newState.isDeleting, true);
    });

    test('copyWith updates isDeleting when provided', () {
      const state = DeleteAllDataState();
      final newState = state.copyWith(isDeleting: true);

      expect(newState.isDeleting, true);
    });
  });

  group('useDeleteAllData', () {
    testWidgets('initial state is not deleting', (tester) async {
      late DeleteAllDataState state;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          state = hook.state;
          return null;
        },
      );

      expect(state.isDeleting, false);
    });

    testWidgets('deleteAllData sets isDeleting to true during operation', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataCompleter = Completer<void>();

      final getState = await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return hook.state;
        },
      );

      expect(getState().isDeleting, false);

      final resultFuture = deleteAllData();
      await tester.pump();

      expect(getState().isDeleting, true);

      mockApi.deleteAllDataCompleter!.complete();
      await tester.pump();
      await resultFuture;
      await tester.pump();
    });

    testWidgets('deleteAllData calls API successfully', (tester) async {
      late Future<bool> Function() deleteAllData;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      await deleteAllData();
      await tester.pump();

      expect(mockApi.deleteAllDataCalled, true);
      expect(mockApi.reinitializeWhitenoiseCalled, true);
    });

    testWidgets('deleteAllData returns false when reinitialization fails', (tester) async {
      late Future<bool> Function() deleteAllData;
      late DeleteAllDataFailure? Function() latestFailure;

      mockApi.reinitializeWhitenoiseShouldFail = true;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          latestFailure = hook.latestFailure;
          return null;
        },
      );

      final result = await deleteAllData();
      await tester.pump();

      expect(result, false);
      expect(mockApi.deleteAllDataCalled, true);
      expect(mockApi.reinitializeWhitenoiseCalled, true);
      expect(latestFailure(), DeleteAllDataFailure.reinitializeFailed);
    });

    testWidgets('deleteAllData sets isDeleting to false after success', (tester) async {
      late Future<bool> Function() deleteAllData;

      final getState = await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return hook.state;
        },
      );

      final result = await deleteAllData();
      await tester.pump();

      expect(result, true);
      expect(getState().isDeleting, false);
    });

    testWidgets('deleteAllData returns false on failure', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataShouldFail = true;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      final result = await deleteAllData();
      await tester.pump();

      expect(result, false);
      expect(mockApi.reinitializeWhitenoiseCalled, false);
    });

    testWidgets('deleteAllData waits for long-running API calls', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataCompleter = Completer<void>();

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      final resultFuture = deleteAllData();
      var completed = false;
      unawaited(resultFuture.then((_) => completed = true));

      await tester.pump(const Duration(seconds: 2));

      expect(completed, isFalse);
      mockApi.deleteAllDataCompleter!.complete();

      final result = await resultFuture;
      await tester.pump();

      expect(result, true);
      expect(mockApi.deleteAllDataCalled, true);
    });

    testWidgets('deleteAllData keeps isDeleting true while API call is pending', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataCompleter = Completer<void>();

      final getState = await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return hook.state;
        },
      );

      final resultFuture = deleteAllData();
      await tester.pump(const Duration(seconds: 2));

      expect(getState().isDeleting, true);
      mockApi.deleteAllDataCompleter!.complete();

      await resultFuture;
      await tester.pump();

      expect(getState().isDeleting, false);
    });

    testWidgets('deleteAllData returns true after clearing previous error', (tester) async {
      late Future<bool> Function() deleteAllData;
      final getState = await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return hook.state;
        },
      );

      mockApi.deleteAllDataShouldFail = true;

      final failResult = await deleteAllData();
      await tester.pump();

      expect(failResult, false);

      mockApi.deleteAllDataShouldFail = false;

      final successResult = await deleteAllData();
      await tester.pump();

      expect(successResult, true);
      expect(getState().isDeleting, false);
    });
  });
}
