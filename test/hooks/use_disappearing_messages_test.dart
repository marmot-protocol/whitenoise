import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_disappearing_messages.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool shouldFailGetDuration = false;
  bool shouldFailSetDuration = false;
  Completer<BigInt?>? getDurationCompleter;
  Completer<void>? setDurationCompleter;
  int getDurationCallCount = 0;
  int setDurationCallCount = 0;
  BigInt? lastSetDuration;
  String? lastGetAccountPubkey;
  String? lastGetGroupId;
  String? lastSetAccountPubkey;
  String? lastSetGroupId;

  @override
  Future<BigInt?> crateApiGroupsGetDisappearingMessageDuration({
    required String accountPubkey,
    required String groupId,
  }) async {
    getDurationCallCount++;
    lastGetAccountPubkey = accountPubkey;
    lastGetGroupId = groupId;
    if (shouldFailGetDuration) throw Exception('Failed to get duration');
    if (getDurationCompleter != null) return getDurationCompleter!.future;
    return disappearingMessageDuration;
  }

  @override
  Future<void> crateApiGroupsSetDisappearingMessages({
    required String accountPubkey,
    required String groupId,
    BigInt? durationSecs,
  }) async {
    setDurationCallCount++;
    lastSetAccountPubkey = accountPubkey;
    lastSetGroupId = groupId;
    lastSetDuration = durationSecs;
    if (setDurationCompleter != null) await setDurationCompleter!.future;
    if (shouldFailSetDuration) throw Exception('Failed to set duration');
    disappearingMessageDuration = durationSecs;
  }

  @override
  void reset() {
    super.reset();
    shouldFailGetDuration = false;
    shouldFailSetDuration = false;
    getDurationCompleter = null;
    setDurationCompleter = null;
    getDurationCallCount = 0;
    setDurationCallCount = 0;
    lastSetDuration = null;
    lastGetAccountPubkey = null;
    lastGetGroupId = null;
    lastSetAccountPubkey = null;
    lastSetGroupId = null;
  }
}

final _api = _MockApi();

typedef _HookResult = ({
  int? currentDurationSecs,
  bool isLoading,
  bool isSaving,
  String? error,
  Future<void> Function() load,
  Future<bool> Function(int? durationSecs) setDuration,
});

void main() {
  late _HookResult Function() getResult;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(WidgetTester tester) async {
    getResult = await mountHook(
      tester,
      () => useDisappearingMessages(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('useDisappearingMessages', () {
    group('disappearingMessageOptions constant', () {
      test('contains expected options', () {
        expect(disappearingMessageOptions, [null, 30, 300, 3600, 86400, 604800]);
      });
    });

    group('initial state', () {
      testWidgets('currentDurationSecs is null before load completes', (tester) async {
        _api.getDurationCompleter = Completer();
        getResult = await mountHook(
          tester,
          () => useDisappearingMessages(
            accountPubkey: testPubkeyA,
            groupId: testGroupId,
          ),
        );
        await tester.pump();

        expect(getResult().currentDurationSecs, isNull);

        _api.getDurationCompleter!.complete(null);
        await tester.pumpAndSettle();
      });

      testWidgets('isSaving is false initially', (tester) async {
        await pump(tester);

        expect(getResult().isSaving, isFalse);
      });

      testWidgets('error is null initially', (tester) async {
        await pump(tester);

        expect(getResult().error, isNull);
      });
    });

    group('load', () {
      testWidgets('calls API with correct parameters', (tester) async {
        await pump(tester);

        expect(_api.getDurationCallCount, 1);
        expect(_api.lastGetAccountPubkey, testPubkeyA);
        expect(_api.lastGetGroupId, testGroupId);
      });

      testWidgets('updates currentDurationSecs when API returns value', (tester) async {
        _api.disappearingMessageDuration = BigInt.from(3600);
        await pump(tester);

        expect(getResult().currentDurationSecs, 3600);
      });

      testWidgets('sets currentDurationSecs to null when API returns null', (tester) async {
        _api.disappearingMessageDuration = null;
        await pump(tester);

        expect(getResult().currentDurationSecs, isNull);
      });

      testWidgets('isLoading is true while loading', (tester) async {
        _api.getDurationCompleter = Completer();
        getResult = await mountHook(
          tester,
          () => useDisappearingMessages(
            accountPubkey: testPubkeyA,
            groupId: testGroupId,
          ),
        );
        await tester.pump();

        expect(getResult().isLoading, isTrue);

        _api.getDurationCompleter!.complete(BigInt.from(300));
        await tester.pumpAndSettle();

        expect(getResult().isLoading, isFalse);
      });

      testWidgets('sets error when load fails', (tester) async {
        _api.shouldFailGetDuration = true;
        await pump(tester);

        expect(getResult().error, isNotNull);
        expect(getResult().isLoading, isFalse);
      });

      testWidgets('load is triggered automatically via useEffect', (tester) async {
        _api.disappearingMessageDuration = BigInt.from(86400);
        await pump(tester);

        expect(_api.getDurationCallCount, 1);
        expect(getResult().currentDurationSecs, 86400);
      });
    });

    group('setDuration', () {
      testWidgets('calls API with correct parameters for non-null duration', (tester) async {
        await pump(tester);

        await getResult().setDuration(3600);
        await tester.pumpAndSettle();

        expect(_api.setDurationCallCount, 1);
        expect(_api.lastSetAccountPubkey, testPubkeyA);
        expect(_api.lastSetGroupId, testGroupId);
        expect(_api.lastSetDuration, BigInt.from(3600));
      });

      testWidgets('calls API with null for disabling', (tester) async {
        _api.disappearingMessageDuration = BigInt.from(3600);
        await pump(tester);

        await getResult().setDuration(null);
        await tester.pumpAndSettle();

        expect(_api.lastSetDuration, isNull);
      });

      testWidgets('returns true on success', (tester) async {
        await pump(tester);

        final result = await getResult().setDuration(300);
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('updates currentDurationSecs on success', (tester) async {
        await pump(tester);

        await getResult().setDuration(604800);
        await tester.pumpAndSettle();

        expect(getResult().currentDurationSecs, 604800);
      });

      testWidgets('isSaving is true while saving', (tester) async {
        _api.setDurationCompleter = Completer();
        await pump(tester);

        final future = getResult().setDuration(3600);
        await tester.pump();

        expect(getResult().isSaving, isTrue);

        _api.setDurationCompleter!.complete();
        await future;
        await tester.pumpAndSettle();

        expect(getResult().isSaving, isFalse);
      });

      testWidgets('returns false on failure', (tester) async {
        _api.shouldFailSetDuration = true;
        await pump(tester);

        final result = await getResult().setDuration(300);
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });

      testWidgets('sets error on failure', (tester) async {
        _api.shouldFailSetDuration = true;
        await pump(tester);

        await getResult().setDuration(300);
        await tester.pumpAndSettle();

        expect(getResult().error, isNotNull);
      });

      testWidgets('does not update currentDurationSecs on failure', (tester) async {
        _api.disappearingMessageDuration = BigInt.from(3600);
        await pump(tester);
        expect(getResult().currentDurationSecs, 3600);

        _api.shouldFailSetDuration = true;
        await getResult().setDuration(300);
        await tester.pumpAndSettle();

        expect(getResult().currentDurationSecs, 3600);
      });

      testWidgets('clears error before saving', (tester) async {
        _api.shouldFailSetDuration = true;
        await pump(tester);

        await getResult().setDuration(300);
        await tester.pumpAndSettle();
        expect(getResult().error, isNotNull);

        _api.shouldFailSetDuration = false;
        _api.setDurationCompleter = Completer();
        final future = getResult().setDuration(3600);
        await tester.pump();

        expect(getResult().error, isNull);

        _api.setDurationCompleter!.complete();
        await future;
        await tester.pumpAndSettle();
      });
    });
  });
}
