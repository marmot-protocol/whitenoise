import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

User _userFactory(String pubkey, {String? displayName}) => User(
  pubkey: pubkey,
  metadata: FlutterMetadata(displayName: displayName, custom: const {}),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _MockApi extends MockWnApi {
  List<User> followsList = [];
  List<String> membersList = [];
  List<String> adminsList = [];
  bool shouldFailLoadMembers = false;
  Exception? addMembersError;
  final addMembersCalls = <({String pubkey, String groupId, List<String> memberPubkeys})>[];

  @override
  Future<List<User>> crateApiAccountsAccountFollows({required String pubkey}) async {
    return followsList;
  }

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async {
    if (shouldFailLoadMembers) throw Exception('Failed to load members');
    return membersList;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async {
    if (shouldFailLoadMembers) throw Exception('Failed to load admins');
    return adminsList;
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    return Group(
      mlsGroupId: groupId,
      nostrGroupId: 'nostr_$groupId',
      name: 'Test Group',
      description: '',
      adminPubkeys: adminsList,
      epoch: BigInt.zero,
      state: GroupState.active,
    );
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
  void reset() {
    super.reset();
    followsList = [];
    membersList = [];
    adminsList = [];
    shouldFailLoadMembers = false;
    addMembersError = null;
    addMembersCalls.clear();
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpAddGroupMembersScreen(
    WidgetTester tester, {
    List<String> existingMembers = const [testPubkeyA],
  }) async {
    setUpTestView(tester);
    _api.membersList = existingMembers;
    _api.adminsList = [testPubkeyA];
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToAddGroupMembers(
      tester.element(find.byType(Scaffold)),
      testGroupId,
    );
    await tester.pumpAndSettle();
  }

  group('AddGroupMembersScreen', () {
    testWidgets('displays header with Add members title', (tester) async {
      await pumpAddGroupMembersScreen(tester);

      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('Add members'), findsWidgets);
    });

    testWidgets('shows followed users that are not already members', (tester) async {
      _api.followsList = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];
      await pumpAddGroupMembersScreen(tester);

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('filters out users who are already members', (tester) async {
      _api.followsList = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];
      await pumpAddGroupMembersScreen(
        tester,
        existingMembers: const [testPubkeyA, testPubkeyB],
      );

      expect(find.text('Bob'), findsNothing);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('submit button is disabled when no users selected', (tester) async {
      _api.followsList = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpAddGroupMembersScreen(tester);

      final button = tester.widget<WnButton>(
        find.byKey(const Key('add_members_submit_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button is enabled after selecting a user', (tester) async {
      _api.followsList = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpAddGroupMembersScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final button = tester.widget<WnButton>(
        find.byKey(const Key('add_members_submit_button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls addMembersToGroup with selected users and pops on success', (
      tester,
    ) async {
      _api.followsList = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];
      await pumpAddGroupMembersScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charlie'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_members_submit_button')));
      await tester.pumpAndSettle();

      expect(_api.addMembersCalls.length, 1);
      expect(_api.addMembersCalls[0].groupId, testGroupId);
      expect(_api.addMembersCalls[0].pubkey, testPubkeyA);
      expect(
        _api.addMembersCalls[0].memberPubkeys,
        unorderedEquals([testPubkeyB, testPubkeyC]),
      );
      expect(find.text('Add members'), findsNothing);
    });

    testWidgets('shows error notice and stays on screen when add fails', (tester) async {
      _api.followsList = [_userFactory(testPubkeyB, displayName: 'Bob')];
      _api.addMembersError = Exception('boom');
      await pumpAddGroupMembersScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_members_submit_button')));
      await tester.pumpAndSettle();

      expect(_api.addMembersCalls.length, 1);
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to add members. Please try again.'), findsOneWidget);
    });

    testWidgets('tapping back button navigates back', (tester) async {
      await pumpAddGroupMembersScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_members_submit_button')), findsNothing);
    });

    testWidgets('shows error notice when fetching group members fails', (tester) async {
      _api.shouldFailLoadMembers = true;
      await pumpAddGroupMembersScreen(tester);

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to load group members. Please try again.'), findsOneWidget);
    });
  });
}
