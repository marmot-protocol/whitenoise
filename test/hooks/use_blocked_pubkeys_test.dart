import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise_frb/src/rust/api/mute_list.dart';
import 'package:whitenoise_frb/src/rust/frb_generated.dart';
import 'package:whitenoise/hooks/use_blocked_pubkeys.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  Exception? getBlockedUsersError;

  @override
  Future<List<MuteListEntry>> crateApiMuteListGetBlockedUsers({
    required String accountPubkey,
  }) async {
    if (getBlockedUsersError != null) throw getBlockedUsersError!;
    return super.crateApiMuteListGetBlockedUsers(accountPubkey: accountPubkey);
  }

  @override
  void reset() {
    super.reset();
    getBlockedUsersError = null;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(_api.reset);

  group('useBlockedPubkeys', () {
    testWidgets('clears stale blocked users when refresh fails', (tester) async {
      _api.blockedPubkeys.add(testPubkeyB);
      final getState = await mountHook(tester, () => useBlockedPubkeys(testPubkeyA));
      await tester.pumpAndSettle();

      expect(getState().blockedPubkeys, contains(testPubkeyB));

      _api.getBlockedUsersError = Exception('get blocked users failed');
      getState().refresh();
      await tester.pumpAndSettle();

      expect(getState().blockedPubkeys, isEmpty);
      expect(getState().error, 'failedToFetchBlockedUsers');
    });
  });
}
