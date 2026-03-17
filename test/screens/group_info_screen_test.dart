import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/edit_group_screen.dart';
import 'package:whitenoise/screens/group_member_screen.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_group_info_card.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;

class _MockApi extends MockWnApi {
  List<String> membersList = [];
  List<String> adminsList = [];
  Group? groupToReturn;
  String? imagePathToReturn;
  bool archivedAtResult = false;
  final Map<String, FlutterMetadata> metadataMap = {};
  bool shouldThrowOnGroupMembers = false;

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async {
    if (shouldThrowOnGroupMembers) throw Exception('Failed to load members');
    return membersList;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async {
    if (shouldThrowOnGroupMembers) throw Exception('Failed to load admins');
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
  Future<AccountGroup> crateApiAccountGroupsGetAccountGroup({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    return AccountGroup(
      accountPubkey: accountPubkey,
      mlsGroupId: mlsGroupId,
      archivedAt: archivedAtResult ? DateTime.now().millisecondsSinceEpoch : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
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
    archivedAtResult = false;
    metadataMap.clear();
    shouldThrowOnGroupMembers = false;
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
    unawaited(Routes.pushToGroupInfo(tester.element(find.byType(Scaffold)), groupId));
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

    testWidgets('displays archive button above members label', (tester) async {
      _api.membersList = [_testPubkey, testPubkeyB];
      _api.adminsList = [_testPubkey];
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      final archiveButton = find.byKey(const Key('archive_button'));
      final membersLabel = find.byKey(const Key('members_label'));
      final archiveTop = tester.getTopLeft(archiveButton).dy;
      final membersTop = tester.getTopLeft(membersLabel).dy;

      expect(archiveButton, findsOneWidget);
      expect(archiveTop, lessThan(membersTop));
    });

    testWidgets('shows archive button when group is not archived', (tester) async {
      _api.archivedAtResult = false;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(
        find.descendant(
          of: find.byKey(const Key('archive_button')),
          matching: find.text('Archive'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows unarchive button when group is archived', (tester) async {
      _api.archivedAtResult = true;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(
        find.descendant(
          of: find.byKey(const Key('archive_button')),
          matching: find.text('Unarchive'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls archive API when archive button is tapped', (tester) async {
      _api.archivedAtResult = false;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.archiveChatCallCount, 1);
    });

    testWidgets('shows error notice when archive fails', (tester) async {
      _api.archivedAtResult = false;
      _api.shouldFailArchiveChat = true;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.archiveChatCallCount, 1);
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to archive chat. Please try again.'), findsOneWidget);
    });

    testWidgets('calls unarchive API when unarchive button is tapped', (tester) async {
      _api.archivedAtResult = true;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.unarchiveChatCallCount, 1);
    });

    testWidgets('shows error notice when unarchive fails', (tester) async {
      _api.archivedAtResult = true;
      _api.shouldFailUnarchiveChat = true;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.unarchiveChatCallCount, 1);
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to unarchive chat. Please try again.'), findsOneWidget);
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

    testWidgets('navigates back when back button is pressed', (tester) async {
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Group Information'), findsNothing);
    });

    testWidgets('shows error notice when member list fails to load', (tester) async {
      _api.shouldThrowOnGroupMembers = true;
      await pumpGroupInfoScreen(tester, groupId: testGroupId);

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to load group members. Please try again.'), findsOneWidget);
    });

    group('search button', () {
      testWidgets('shows search button by default', (tester) async {
        await pumpGroupInfoScreen(tester, groupId: testGroupId);

        expect(find.byKey(const Key('group_search_button')), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
      });

      testWidgets('search button appears above edit button when user is admin', (tester) async {
        _api.adminsList = [_testPubkey];
        await pumpGroupInfoScreen(tester, groupId: testGroupId);

        expect(find.byKey(const Key('group_search_button')), findsOneWidget);
        expect(find.byKey(const Key('edit_group_button')), findsOneWidget);

        final searchOffset = tester.getTopLeft(find.byKey(const Key('group_search_button')));
        final editOffset = tester.getTopLeft(find.byKey(const Key('edit_group_button')));
        expect(searchOffset.dy, lessThan(editOffset.dy));
      });

      testWidgets('tapping search button pops the screen', (tester) async {
        await pumpGroupInfoScreen(tester, groupId: testGroupId);

        await tester.tap(find.byKey(const Key('group_search_button')));
        await tester.pumpAndSettle();

        expect(find.text('Group Information'), findsNothing);
      });
    });
  });
}
