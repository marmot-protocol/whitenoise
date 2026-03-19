import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_support_chat.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  String? dmGroupResult;
  Exception? dmGroupError;
  String? lastAccountPubkey;
  String? lastPeerPubkey;

  @override
  Future<String?> crateApiAccountGroupsGetDmGroupWithPeer({
    required String accountPubkey,
    required String peerPubkey,
  }) async {
    lastAccountPubkey = accountPubkey;
    lastPeerPubkey = peerPubkey;
    if (dmGroupError != null) {
      throw dmGroupError!;
    }
    return dmGroupResult;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() {
    _api.dmGroupResult = null;
    _api.dmGroupError = null;
    _api.lastAccountPubkey = null;
    _api.lastPeerPubkey = null;
  });

  group('useSupportChat', () {
    testWidgets('returns existingGroupId when DM exists', (tester) async {
      _api.dmGroupResult = testGroupId;

      final getResult = await mountHook(
        tester,
        () => useSupportChat(accountPubkey: testPubkeyA),
      );
      await tester.pumpAndSettle();

      final state = getResult();
      expect(state.isLoading, isFalse);
      expect(state.existingGroupId, testGroupId);
      expect(_api.lastAccountPubkey, testPubkeyA);
      expect(
        _api.lastPeerPubkey,
        '1136006d965b8ffb0e8d0e842750d68a6cd06093957f14bcefb47bb228f0cc35',
      );
    });

    testWidgets('returns null existingGroupId when no DM exists', (tester) async {
      _api.dmGroupResult = null;

      final getResult = await mountHook(
        tester,
        () => useSupportChat(accountPubkey: testPubkeyA),
      );
      await tester.pumpAndSettle();

      final state = getResult();
      expect(state.isLoading, isFalse);
      expect(state.existingGroupId, isNull);
    });

    testWidgets('returns null existingGroupId when accountPubkey is null', (
      tester,
    ) async {
      final getResult = await mountHook(
        tester,
        () => useSupportChat(accountPubkey: null),
      );
      await tester.pumpAndSettle();

      final state = getResult();
      expect(state.isLoading, isFalse);
      expect(state.existingGroupId, isNull);
      expect(_api.lastAccountPubkey, isNull);
    });

    testWidgets('when API throws returns is loading false and existingGroupId is null', (
      tester,
    ) async {
      _api.dmGroupError = Exception('Network error');

      final getResult = await mountHook(
        tester,
        () => useSupportChat(accountPubkey: testPubkeyA),
      );
      await tester.pumpAndSettle();

      final state = getResult();
      expect(state.isLoading, isFalse);
      expect(state.existingGroupId, isNull);
    });
  });
}
