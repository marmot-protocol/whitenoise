import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _userPubkey = testPubkeyB;

Group _makeGroup({
  required String id,
  String name = 'Test Group',
  String description = '',
  List<String>? adminPubkeys,
}) => Group(
  mlsGroupId: id,
  nostrGroupId: 'nostr_$id',
  name: name,
  description: description,
  adminPubkeys: adminPubkeys ?? [_testPubkey],
  epoch: BigInt.zero,
  state: GroupState.active,
);

class _MockApi extends MockWnApi {
  List<Group> groupsList = [];
  bool isDmResult = false;
  Exception? addMembersError;
  final addMembersCalls = <({String pubkey, String groupId, List<String> memberPubkeys})>[];

  @override
  Future<List<Group>> crateApiGroupsActiveGroups({required String pubkey}) async {
    return groupsList;
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) async {
    return isDmResult;
  }

  @override
  Future<void> crateApiGroupsAddMembersToGroup({
    required String pubkey,
    required String groupId,
    required List<String> memberPubkeys,
  }) async {
    addMembersCalls.add((pubkey: pubkey, groupId: groupId, memberPubkeys: memberPubkeys));
    if (addMembersError != null) throw addMembersError!;
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    return FlutterMetadata(displayName: 'User ${pubkey.substring(0, 8)}', custom: const {});
  }

  @override
  void reset() {
    super.reset();
    groupsList = [];
    isDmResult = false;
    addMembersError = null;
    addMembersCalls.clear();
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(_testPubkey);
    return _testPubkey;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpAddToGroupScreen(WidgetTester tester) async {
    setUpTestView(tester);
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToAddToGroup(
      tester.element(find.byType(Scaffold)),
      _userPubkey,
    );
    await tester.pumpAndSettle();
  }

  group('AddToGroupScreen', () {
    testWidgets('displays slate container', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId)];
      await pumpAddToGroupScreen(tester);

      expect(find.byType(WnSlate), findsWidgets);
    });

    testWidgets('displays header with Add to group title', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId)];
      await pumpAddToGroupScreen(tester);

      expect(find.byType(WnSlateNavigationHeader), findsWidgets);
      expect(find.text('Add to group'), findsWidgets);
    });

    testWidgets('displays list of admin groups', (tester) async {
      _api.groupsList = [
        _makeGroup(id: testGroupId, name: 'Alpha Group'),
        _makeGroup(id: otherTestGroupId, name: 'Beta Group'),
      ];
      await pumpAddToGroupScreen(tester);

      expect(find.byKey(const Key('group_$testGroupId')), findsOneWidget);
      expect(find.byKey(const Key('group_$otherTestGroupId')), findsOneWidget);
      expect(find.text('Alpha Group'), findsOneWidget);
      expect(find.text('Beta Group'), findsOneWidget);
    });

    testWidgets('does not display groups where user is not admin', (tester) async {
      _api.groupsList = [
        _makeGroup(id: testGroupId, name: 'Admin Group', adminPubkeys: [_testPubkey]),
        _makeGroup(id: otherTestGroupId, name: 'Non-Admin Group', adminPubkeys: [testPubkeyC]),
      ];
      await pumpAddToGroupScreen(tester);

      expect(find.text('Admin Group'), findsOneWidget);
      expect(find.text('Non-Admin Group'), findsNothing);
    });

    testWidgets('does not show loading indicator after groups are fetched', (tester) async {
      await pumpAddToGroupScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows confirmation dialog when group is tapped', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId, name: 'Alpha Group')];
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('group_$testGroupId')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
    });

    testWidgets('calls addMembersToGroup API when confirmed', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId, name: 'Alpha Group')];
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('group_$testGroupId')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(_api.addMembersCalls.length, 1);
      expect(_api.addMembersCalls[0].groupId, testGroupId);
      expect(_api.addMembersCalls[0].memberPubkeys, [_userPubkey]);
    });

    testWidgets('shows error notice when addMembers fails', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId, name: 'Alpha Group')];
      _api.addMembersError = Exception('Network error');
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('group_$testGroupId')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to add members. Please try again.'), findsOneWidget);
    });

    testWidgets('does not call API when confirmation is cancelled', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId, name: 'Alpha Group')];
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('group_$testGroupId')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(_api.addMembersCalls, isEmpty);
    });

    testWidgets('navigates back when back button is pressed', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId)];
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSlateNavigationHeader), findsNothing);
    });

    testWidgets('shows no-admin-groups dialog when no admin groups available', (tester) async {
      await pumpAddToGroupScreen(tester);

      expect(
        find.text(
          "You're not an admin in any groups yet. Create a group to add people.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('navigates back when no-admin-groups dialog is cancelled', (tester) async {
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSlateNavigationHeader), findsNothing);
    });

    testWidgets('navigates to user selection when no-admin-groups dialog is confirmed', (
      tester,
    ) async {
      await pumpAddToGroupScreen(tester);

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('New group chat'), findsOneWidget);
    });

    testWidgets('displays group name in list item', (tester) async {
      _api.groupsList = [
        _makeGroup(id: testGroupId, name: 'Alpha Group', description: 'A great group'),
      ];
      await pumpAddToGroupScreen(tester);

      expect(find.byKey(const Key('user_item_name')), findsOneWidget);
    });

    testWidgets('displays Unknown group when group name is empty', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId, name: '')];
      await pumpAddToGroupScreen(tester);

      expect(find.text('Unknown group'), findsOneWidget);
    });
  });
}
