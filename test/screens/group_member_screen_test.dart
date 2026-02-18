import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _memberPubkey = testPubkeyB;
const _otherMemberPubkey = testPubkeyC;

class _MockApi extends MockWnApi {
  List<String> membersList = [];
  List<String> adminsList = [];
  Group? groupToReturn;
  final Map<String, FlutterMetadata> metadataMap = {};

  final removeMemberCalls = <({String pubkey, String groupId, List<String> memberPubkeys})>[];
  Exception? removeMemberError;

  final updateGroupDataCalls =
      <({Group group, String accountPubkey, FlutterGroupDataUpdate data})>[];
  Exception? updateGroupDataError;

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async {
    return membersList;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async {
    return adminsList;
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    return groupToReturn ??
        Group(
          mlsGroupId: testGroupId,
          nostrGroupId: testNostrGroupId,
          name: 'Test Group',
          description: 'A test group',
          adminPubkeys: [_testPubkey],
          epoch: BigInt.zero,
          state: GroupState.active,
        );
  }

  @override
  Future<void> crateApiGroupsRemoveMembersFromGroup({
    required String pubkey,
    required String groupId,
    required List<String> memberPubkeys,
  }) async {
    removeMemberCalls.add((
      pubkey: pubkey,
      groupId: groupId,
      memberPubkeys: memberPubkeys,
    ));
    if (removeMemberError != null) throw removeMemberError!;
  }

  @override
  Future<void> crateApiGroupsGroupUpdateGroupData({
    required Group that,
    required String accountPubkey,
    required FlutterGroupDataUpdate groupData,
  }) async {
    updateGroupDataCalls.add((
      group: that,
      accountPubkey: accountPubkey,
      data: groupData,
    ));
    if (updateGroupDataError != null) throw updateGroupDataError!;
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    return metadataMap[pubkey] ??
        FlutterMetadata(displayName: 'User ${pubkey.substring(0, 8)}', custom: const {});
  }

  @override
  void reset() {
    super.reset();
    membersList = [];
    adminsList = [];
    groupToReturn = null;
    metadataMap.clear();
    removeMemberCalls.clear();
    removeMemberError = null;
    updateGroupDataCalls.clear();
    updateGroupDataError = null;
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

  Future<void> pumpGroupMemberScreen(
    WidgetTester tester, {
    required String memberPubkey,
    bool settle = true,
  }) async {
    _api.membersList = [_testPubkey, _memberPubkey, _otherMemberPubkey];

    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToGroupMember(
      tester.element(find.byType(Scaffold)),
      testGroupId,
      memberPubkey,
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('GroupMemberScreen', () {
    testWidgets('displays slate container and header with name and member role', (tester) async {
      _api.adminsList = [_testPubkey];
      _api.metadataMap[_memberPubkey] = const FlutterMetadata(
        displayName: 'Bob',
        custom: {},
      );
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.byType(WnSlate), findsWidgets);
      expect(find.byType(WnSlateNavigationHeader), findsWidgets);
      expect(find.text('Bob - Member'), findsOneWidget);
    });

    testWidgets('displays admin role in header when member is admin', (tester) async {
      _api.adminsList = [_testPubkey, _memberPubkey];
      _api.metadataMap[_memberPubkey] = const FlutterMetadata(
        displayName: 'Bob',
        custom: {},
      );
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.text('Bob - Admin'), findsOneWidget);
    });

    testWidgets('uses light overlay variant', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
      expect(overlay.variant, WnOverlayVariant.light);
    });

    testWidgets('displays member profile card with avatar and name', (tester) async {
      _api.adminsList = [_testPubkey];
      _api.metadataMap[_memberPubkey] = const FlutterMetadata(
        displayName: 'Bob',
        custom: {},
      );
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.byType(WnAvatar), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows make admin button when current user is admin and member is not', (
      tester,
    ) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.byKey(const Key('make_admin_button')), findsOneWidget);
      expect(find.text('Make admin'), findsOneWidget);
      expect(find.byKey(const Key('remove_admin_button')), findsNothing);
    });

    testWidgets('shows remove admin button when current user is admin and member is admin', (
      tester,
    ) async {
      _api.adminsList = [_testPubkey, _memberPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.byKey(const Key('remove_admin_button')), findsOneWidget);
      expect(find.text('Remove admin'), findsOneWidget);
      expect(find.byKey(const Key('make_admin_button')), findsNothing);
    });

    testWidgets('shows remove from group button when current user is admin', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      expect(find.byKey(const Key('remove_from_group_button')), findsOneWidget);
      expect(find.text('Remove from group'), findsOneWidget);
    });

    testWidgets('hides admin actions when current user is not admin', (tester) async {
      _api.adminsList = [_memberPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _otherMemberPubkey);

      expect(find.byKey(const Key('make_admin_button')), findsNothing);
      expect(find.byKey(const Key('remove_admin_button')), findsNothing);
      expect(find.byKey(const Key('remove_from_group_button')), findsNothing);
    });

    testWidgets('hides admin actions when viewing own profile', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _testPubkey);

      expect(find.byKey(const Key('make_admin_button')), findsNothing);
      expect(find.byKey(const Key('remove_admin_button')), findsNothing);
      expect(find.byKey(const Key('remove_from_group_button')), findsNothing);
    });

    testWidgets('shows confirmation dialog when make admin is tapped', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('make_admin_button')));
      await tester.pumpAndSettle();

      expect(find.text('Make admin?'), findsOneWidget);
      expect(
        find.text(
          'This member will be able to manage the group, add or remove members, and change group settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls make admin API when confirmed', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('make_admin_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(_api.updateGroupDataCalls.length, 1);
      expect(_api.updateGroupDataCalls[0].data.admins, contains(_memberPubkey));
    });

    testWidgets('shows confirmation dialog when remove admin is tapped', (tester) async {
      _api.adminsList = [_testPubkey, _memberPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_admin_button')));
      await tester.pumpAndSettle();

      expect(find.text('Remove admin?'), findsOneWidget);
      expect(
        find.text(
          'This member will no longer be able to manage the group, add or remove members, or change group settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls remove admin API when confirmed', (tester) async {
      _api.adminsList = [_testPubkey, _memberPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_admin_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(_api.updateGroupDataCalls.length, 1);
      expect(_api.updateGroupDataCalls[0].data.admins, isNot(contains(_memberPubkey)));
    });

    testWidgets('shows destructive confirmation dialog when remove from group is tapped', (
      tester,
    ) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_from_group_button')));
      await tester.pumpAndSettle();

      expect(find.text('Remove from group?'), findsOneWidget);
      expect(
        find.text(
          'This member will be removed from the group and will no longer be able to see new messages.',
        ),
        findsOneWidget,
      );

      final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
      expect(confirmButton.type, WnButtonType.destructive);
    });

    testWidgets('calls remove member API when confirmed', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_from_group_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(_api.removeMemberCalls.length, 1);
      expect(_api.removeMemberCalls[0].memberPubkeys, [_memberPubkey]);
    });

    testWidgets('shows error notice when make admin fails', (tester) async {
      _api.adminsList = [_testPubkey];
      _api.updateGroupDataError = Exception('API error');
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('make_admin_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to make admin. Please try again.'), findsOneWidget);
    });

    testWidgets('shows error notice when remove admin fails', (tester) async {
      _api.adminsList = [_testPubkey, _memberPubkey];
      _api.updateGroupDataError = Exception('API error');
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_admin_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to remove admin. Please try again.'), findsOneWidget);
    });

    testWidgets('shows error notice when remove from group fails', (tester) async {
      _api.adminsList = [_testPubkey];
      _api.removeMemberError = Exception('API error');
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_from_group_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to remove member. Please try again.'), findsOneWidget);
    });

    testWidgets('shows success notice when npub is copied', (tester) async {
      mockClipboard();
      addTearDown(clearClipboardMock);
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Public key copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows error notice when npub copy fails', (tester) async {
      mockClipboardFailing();
      addTearDown(clearClipboardMock);
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
    });

    testWidgets('navigates back when close button is pressed', (tester) async {
      _api.adminsList = [_testPubkey];
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSlateNavigationHeader), findsNothing);
    });

    testWidgets('does not navigate when cancel is pressed on confirmation', (tester) async {
      _api.adminsList = [_testPubkey];
      _api.metadataMap[_memberPubkey] = const FlutterMetadata(
        displayName: 'Bob',
        custom: {},
      );
      await pumpGroupMemberScreen(tester, memberPubkey: _memberPubkey);

      await tester.tap(find.byKey(const Key('remove_from_group_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Bob - Member'), findsOneWidget);
      expect(_api.removeMemberCalls, isEmpty);
    });
  });
}
