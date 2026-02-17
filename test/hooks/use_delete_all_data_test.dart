import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_delete_all_data.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
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
      late DeleteAllDataState initialState;
      late DeleteAllDataState duringState;
      late Future<void> Function() deleteAllData;

      mockApi.deleteAllDataDelay = const Duration(milliseconds: 100);

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          initialState = hook.state;
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      expect(initialState.isDeleting, false);

      deleteAllData();
      await tester.pump();

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          duringState = hook.state;
          return null;
        },
      );

      expect(duringState.isDeleting, true);

      await tester.pumpAndSettle();
    });

    testWidgets('deleteAllData calls API successfully', (tester) async {
      late Future<void> Function() deleteAllData;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      await deleteAllData();
      await tester.pumpAndSettle();

      expect(mockApi.deleteAllDataCalled, true);
    });

    testWidgets('deleteAllData sets isDeleting to false after success', (tester) async {
      late DeleteAllDataState state;
      late Future<bool> Function() deleteAllData;

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          state = hook.state;
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      final result = await deleteAllData();
      await tester.pumpAndSettle();

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData();
          state = hook.state;
          return null;
        },
      );

      expect(result, true);
      expect(state.isDeleting, false);
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
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('deleteAllData returns false on timeout', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataCompleter = Completer<void>();

      await mountHook(
        tester,
        () {
          final hook = useDeleteAllData(timeout: const Duration(seconds: 1));
          deleteAllData = hook.deleteAllData;
          return null;
        },
      );

      final resultFuture = deleteAllData();
      await tester.pump(const Duration(seconds: 2));

      final result = await resultFuture;
      await tester.pumpAndSettle();

      expect(result, false);
      expect(mockApi.deleteAllDataCalled, true);
    });

    testWidgets('deleteAllData sets isDeleting to false after timeout', (tester) async {
      late Future<bool> Function() deleteAllData;

      mockApi.deleteAllDataCompleter = Completer<void>();

      final getState = await mountHook(
        tester,
        () {
          final hook = useDeleteAllData(timeout: const Duration(seconds: 1));
          deleteAllData = hook.deleteAllData;
          return hook.state;
        },
      );

      final resultFuture = deleteAllData();
      await tester.pump(const Duration(seconds: 2));

      await resultFuture;
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(failResult, false);

      mockApi.deleteAllDataShouldFail = false;

      final successResult = await deleteAllData();
      await tester.pumpAndSettle();

      expect(successResult, true);
      expect(getState().isDeleting, false);
    });
  });
}
