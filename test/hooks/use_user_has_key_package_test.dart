import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_user_has_key_package.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  Completer<KeyPackageStatus>? userHasKeyPackageCompleter;
  KeyPackageStatus nonBlockingResult = KeyPackageStatus.valid;
  KeyPackageStatus blockingResult = KeyPackageStatus.valid;
  final userHasKeyPackageCalls = <({String pubkey, bool blocking})>[];

  @override
  Future<KeyPackageStatus> crateApiUsersUserHasKeyPackage({
    required String pubkey,
    required bool blockingDataSync,
  }) {
    userHasKeyPackageCalls.add((pubkey: pubkey, blocking: blockingDataSync));
    if (userHasKeyPackageCompleter != null) {
      return userHasKeyPackageCompleter!.future;
    }
    return Future.value(blockingDataSync ? blockingResult : nonBlockingResult);
  }

  @override
  void reset() {
    super.reset();
    userHasKeyPackageCompleter = null;
    userHasKeyPackageCalls.clear();
    nonBlockingResult = KeyPackageStatus.valid;
    blockingResult = KeyPackageStatus.valid;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  group('useUserHasKeyPackage', () {
    testWidgets('is loading while waiting', (tester) async {
      _api.userHasKeyPackageCompleter = Completer();
      final getSnapshot = await mountHook(tester, () => useUserHasKeyPackage('pk1'));

      expect(getSnapshot().connectionState, equals(ConnectionState.waiting));
    });

    testWidgets('returns valid when non-blocking returns valid', (tester) async {
      _api.nonBlockingResult = KeyPackageStatus.valid;
      final getSnapshot = await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await tester.pump();

      expect(getSnapshot().data, equals(KeyPackageStatus.valid));
      expect(_api.userHasKeyPackageCalls.length, 1);
      expect(_api.userHasKeyPackageCalls[0].blocking, isFalse);
    });

    testWidgets('returns incompatible without retry', (tester) async {
      _api.nonBlockingResult = KeyPackageStatus.incompatible;
      final getSnapshot = await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await tester.pump();

      expect(getSnapshot().data, equals(KeyPackageStatus.incompatible));
      expect(_api.userHasKeyPackageCalls.length, 1);
    });

    testWidgets('retries with blocking when non-blocking returns notFound', (tester) async {
      _api.nonBlockingResult = KeyPackageStatus.notFound;
      _api.blockingResult = KeyPackageStatus.valid;
      final getSnapshot = await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await tester.pump();

      expect(getSnapshot().data, equals(KeyPackageStatus.valid));
      expect(_api.userHasKeyPackageCalls.length, 2);
      expect(_api.userHasKeyPackageCalls[0].blocking, isFalse);
      expect(_api.userHasKeyPackageCalls[1].blocking, isTrue);
    });

    testWidgets('returns notFound when both checks return notFound', (tester) async {
      _api.nonBlockingResult = KeyPackageStatus.notFound;
      _api.blockingResult = KeyPackageStatus.notFound;
      final getSnapshot = await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await tester.pump();

      expect(getSnapshot().data, equals(KeyPackageStatus.notFound));
      expect(_api.userHasKeyPackageCalls.length, 2);
    });

    testWidgets('calls with non-blocking first', (tester) async {
      await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await tester.pump();

      expect(_api.userHasKeyPackageCalls.first.blocking, isFalse);
    });

    testWidgets('does not refetch when rebuilt with same pubkey', (tester) async {
      await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await mountHook(tester, () => useUserHasKeyPackage('pk1'));

      expect(_api.userHasKeyPackageCalls.length, 1);
    });

    testWidgets('refetches when pubkey changes', (tester) async {
      await mountHook(tester, () => useUserHasKeyPackage('pk1'));
      await mountHook(tester, () => useUserHasKeyPackage('pk2'));

      expect(_api.userHasKeyPackageCalls.length, 2);
    });
  });
}
