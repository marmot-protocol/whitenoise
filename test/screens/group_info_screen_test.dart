import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/edit_group_screen.dart';
import 'package:whitenoise/screens/group_member_screen.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_group_info_card.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;

class _MockApi extends MockWnApi {
  List<String> membersList = [];
  List<String> adminsList = [];
  Group? groupToReturn;
  String? imagePathToReturn;
  final Map<String, FlutterMetadata> metadataMap = {};

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
  Future<String?> crateApiGroupsGetGroupImagePath({
    required String accountPubkey,
    required String groupId,
  }) async {
    return imagePathToReturn;
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
    imagePathToReturn = null;
    metadataMap.clear();
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

  Future<void> pumpGroupInfoScreen(
    WidgetTester tester, {
    required String groupId,
    bool settle = true,
  }) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToGroupInfo(tester.element(find.byType(Scaffold)), groupId);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('GroupInfoScreen', () {
    Finder groupInfoSlateFinder() {
      return find.ancestor(
        of: find.text('Group Information'),
        matching: find.byType(WnSlate),
      );
    }

    testWidgets('displays slate container and group info header', (tester) async {
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(groupInfoSlateFinder(), findsOneWidget);
      expect(find.byType(WnSlateNavigationHeader), findsWidgets);
      expect(find.text('Group Information'), findsOneWidget);
    });

    testWidgets('uses light overlay variant', (tester) async {
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
      expect(overlay.variant, WnOverlayVariant.light);
    });

    testWidgets('displays group info card', (tester) async {
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byType(WnGroupInfoCard), findsOneWidget);
      expect(find.byKey(const Key('group_info_avatar')), findsOneWidget);
    });

    testWidgets('displays group name', (tester) async {
      _api.groupToReturn = Group(
        mlsGroupId: testGroupId,
        nostrGroupId: testNostrGroupId,
        name: 'My Cool Group',
        description: '',
        adminPubkeys: [_testPubkey],
        epoch: BigInt.zero,
        state: GroupState.active,
      );
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('group_info_name')), findsOneWidget);
      expect(find.text('My Cool Group'), findsOneWidget);
    });

    testWidgets('displays group description', (tester) async {
      _api.groupToReturn = Group(
        mlsGroupId: testGroupId,
        nostrGroupId: testNostrGroupId,
        name: 'My Group',
        description: 'This is a great group',
        adminPubkeys: [_testPubkey],
        epoch: BigInt.zero,
        state: GroupState.active,
      );
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('group_info_description')), findsOneWidget);
      expect(find.text('This is a great group'), findsOneWidget);
    });

    testWidgets('hides description when empty', (tester) async {
      _api.groupToReturn = Group(
        mlsGroupId: testGroupId,
        nostrGroupId: testNostrGroupId,
        name: 'My Group',
        description: '',
        adminPubkeys: [_testPubkey],
        epoch: BigInt.zero,
        state: GroupState.active,
      );
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('group_info_description')), findsNothing);
    });

    testWidgets('displays members label', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB, testPubkeyC];
      _api.adminsList = [_testPubkey];
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('members_label')), findsOneWidget);
      expect(find.text('Members:'), findsOneWidget);
    });

    testWidgets('displays member items', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      _api.metadataMap[_testPubkey] = const FlutterMetadata(displayName: 'Alice', custom: {});
      _api.metadataMap[testPubkeyB] = const FlutterMetadata(displayName: 'Bob', custom: {});
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byType(WnUserItem), findsNWidgets(2));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows admin badge for admin members', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      _api.metadataMap[_testPubkey] = const FlutterMetadata(displayName: 'Alice', custom: {});
      _api.metadataMap[testPubkeyB] = const FlutterMetadata(displayName: 'Bob', custom: {});
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('shows edit group button when user is admin', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('edit_group_button')), findsOneWidget);
      expect(find.text('Edit group'), findsOneWidget);
    });

    testWidgets('hides edit group button when user is not admin', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [testPubkeyB];
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byKey(const Key('edit_group_button')), findsNothing);
    });

    testWidgets('navigates to edit group screen when edit button pressed', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('edit_group_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EditGroupScreen), findsOneWidget);
    });

    testWidgets('navigates to group member screen when member is tapped', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      _api.metadataMap[testPubkeyB] = const FlutterMetadata(displayName: 'Bob', custom: {});
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('member_$testPubkeyB')));
      await tester.pumpAndSettle();

      expect(find.byType(GroupMemberScreen), findsOneWidget);
    });

    testWidgets('navigates back when close button is pressed', (tester) async {
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('slate_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Group Information'), findsNothing);
    });
  });
}
