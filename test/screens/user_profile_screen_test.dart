import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/user_profile_screen.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_share_plus.dart' show clearSharePlusMock, mockSharePlus, mockSharePlusFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _otherPubkey = testPubkeyB;

class _MockApi extends MockWnApi {
  FlutterMetadata metadata = const FlutterMetadata(custom: {});
  Completer<Group>? createGroupCompleter;
  Group? createdGroup;
  Exception? createGroupError;
  List<Group> groupsList = [];
  final createGroupCalls =
      <
        ({
          String creatorPubkey,
          List<String> memberPubkeys,
          GroupType groupType,
        })
      >[];
  final followCalls = <({String account, String target})>[];
  final unfollowCalls = <({String account, String target})>[];
  Completer<void>? followCompleter;
  Exception? followError;
  final Set<String> followingPubkeys = {};
  final blockCalls = <({String account, String target})>[];
  final unblockCalls = <({String account, String target})>[];
  Exception? blockError;
  Exception? unblockError;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    return metadata;
  }

  @override
  Future<Group> crateApiGroupsCreateGroup({
    required String creatorPubkey,
    required List<String> memberPubkeys,
    required List<String> adminPubkeys,
    required String groupName,
    required String groupDescription,
    required GroupType groupType,
  }) async {
    createGroupCalls.add((
      creatorPubkey: creatorPubkey,
      memberPubkeys: memberPubkeys,
      groupType: groupType,
    ));

    if (createGroupCompleter != null) return createGroupCompleter!.future;
    if (createGroupError != null) throw createGroupError!;

    return createdGroup ??
        Group(
          mlsGroupId: testGroupId,
          nostrGroupId: testNostrGroupId,
          name: '',
          description: '',
          adminPubkeys: const [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );
  }

  @override
  Future<void> crateApiAccountsFollowUser({
    required String accountPubkey,
    required String userToFollowPubkey,
  }) async {
    followCalls.add((account: accountPubkey, target: userToFollowPubkey));
    if (followCompleter != null) await followCompleter!.future;
    if (followError != null) throw followError!;
  }

  @override
  Future<void> crateApiAccountsUnfollowUser({
    required String accountPubkey,
    required String userToUnfollowPubkey,
  }) async {
    unfollowCalls.add((account: accountPubkey, target: userToUnfollowPubkey));
  }

  @override
  Future<bool> crateApiAccountsIsFollowingUser({
    required String accountPubkey,
    required String userPubkey,
  }) async {
    return followingPubkeys.contains(userPubkey);
  }

  @override
  Future<List<Group>> crateApiGroupsActiveGroups({required String pubkey}) async {
    return groupsList;
  }

  @override
  Future<void> crateApiMuteListBlockUser({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    blockCalls.add((account: accountPubkey, target: targetPubkey));
    if (blockError != null) throw blockError!;
    await super.crateApiMuteListBlockUser(
      accountPubkey: accountPubkey,
      targetPubkey: targetPubkey,
    );
  }

  @override
  Future<void> crateApiMuteListUnblockUser({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    unblockCalls.add((account: accountPubkey, target: targetPubkey));
    if (unblockError != null) throw unblockError!;
    await super.crateApiMuteListUnblockUser(
      accountPubkey: accountPubkey,
      targetPubkey: targetPubkey,
    );
  }

  @override
  void reset() {
    super.reset();
    metadata = const FlutterMetadata(custom: {});
    createGroupCompleter = null;
    createdGroup = null;
    createGroupError = null;
    createGroupCalls.clear();
    followCalls.clear();
    unfollowCalls.clear();
    followCompleter = null;
    followError = null;
    followingPubkeys.clear();
    groupsList = [];
    blockCalls.clear();
    unblockCalls.clear();
    blockError = null;
    unblockError = null;
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

  Future<void> pumpUserProfileScreen(
    WidgetTester tester, {
    required String userPubkey,
    bool settle = true,
    bool topAligned = false,
  }) async {
    setUpTestView(tester);
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToUserProfile(
      tester.element(find.byType(Scaffold)),
      userPubkey,
      topAligned: topAligned,
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  group('UserProfileScreen', () {
    testWidgets('displays slate container', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byType(WnSlate), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
    });

    testWidgets('displays avatar', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byType(WnAvatar), findsOneWidget);
    });

    testWidgets('shows pubkey copy card', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: testPubkeyA);
      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.textToDisplay, testNpubAFormatted);
      expect(copyCard.textToCopy, testNpubA);
    });

    testWidgets('displays follow button', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byKey(const Key('follow_button')), findsOneWidget);
    });

    testWidgets('displays start chat button', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byKey(const Key('start_chat_button')), findsOneWidget);
      expect(find.text('Send message'), findsOneWidget);
    });

    testWidgets('keeps button layout stable while key package loads', (tester) async {
      _api.userHasKeyPackageCompleter = Completer<KeyPackageStatus>();

      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('follow_button')), findsOneWidget);
      expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
      expect(find.byKey(const Key('start_chat_button')), findsOneWidget);

      _api.userHasKeyPackageCompleter!.complete(KeyPackageStatus.valid);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('follow_button')), findsOneWidget);
      expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
      expect(find.byKey(const Key('start_chat_button')), findsOneWidget);
    });

    testWidgets('does not show self action buttons for own profile', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _testPubkey);
      expect(find.byKey(const Key('follow_button')), findsNothing);
      expect(find.byKey(const Key('add_to_group_button')), findsNothing);
      expect(find.byKey(const Key('start_chat_button')), findsNothing);
    });

    testWidgets('does not show invite button when user has valid key package', (tester) async {
      await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
      expect(find.byKey(const Key('invite_button')), findsNothing);
    });

    group('with metadata', () {
      setUp(() {
        _api.metadata = const FlutterMetadata(
          displayName: 'Alice',
          nip05: 'alice@example.com',
          about: 'I love Nostr!',
          custom: {},
        );
      });

      testWidgets('displays user name', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('Alice'), findsOneWidget);
      });

      testWidgets('displays nip05', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('alice@example.com'), findsOneWidget);
      });

      testWidgets('displays about', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('I love Nostr!'), findsOneWidget);
      });
    });

    group('with fetched metadata but no name', () {
      const missingNameMetadata = FlutterMetadata(
        about: 'I love Nostr!',
        nip05: 'alice@example.com',
        picture: '/tmp/does-not-exist.png',
        custom: {},
      );

      setUp(() {
        _api.metadata = missingNameMetadata;
      });

      testWidgets('still displays about', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('I love Nostr!'), findsOneWidget);
      });

      testWidgets('still displays nip05', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('alice@example.com'), findsOneWidget);
      });

      testWidgets('passes picture url to avatar', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byType(WnAvatar), findsOneWidget);

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.pictureUrl, '/tmp/does-not-exist.png');
      });
    });

    group('follow button', () {
      testWidgets('shows Follow for non-followed user', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('Follow'), findsOneWidget);
      });

      testWidgets('shows Unfollow for followed user', (tester) async {
        _api.followingPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('Unfollow'), findsOneWidget);
      });

      testWidgets('calls follow API when tapped', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('follow_button')));
        await tester.pumpAndSettle();

        expect(_api.followCalls.length, 1);
        expect(_api.followCalls[0].account, _testPubkey);
        expect(_api.followCalls[0].target, _otherPubkey);
      });

      testWidgets('calls unfollow API when tapped', (tester) async {
        _api.followingPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('follow_button')));
        await tester.pumpAndSettle();

        expect(_api.unfollowCalls.length, 1);
        expect(_api.unfollowCalls[0].account, _testPubkey);
        expect(_api.unfollowCalls[0].target, _otherPubkey);
      });

      testWidgets('shows loading state during follow', (tester) async {
        _api.followCompleter = Completer();
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('follow_button')));
        await tester.pump();

        final buttons = tester.widgetList<WnButton>(find.byType(WnButton)).toList();
        final followButton = buttons.firstWhere((b) => b.key == const Key('follow_button'));
        expect(followButton.loading, isTrue);
      });

      testWidgets('shows system notice on follow error', (tester) async {
        _api.followError = Exception('Network error');
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('follow_button')));
        await tester.pump();
        await tester.pump();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to update follow status. Please try again.'), findsOneWidget);
      });
    });

    group('add to group button', () {
      testWidgets('displays add to group button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
        expect(find.text('Add to group'), findsOneWidget);
      });

      testWidgets('does not show add to group button when user has no key package', (
        tester,
      ) async {
        _api.userHasKeyPackageStatus = KeyPackageStatus.notFound;
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('add_to_group_button')), findsNothing);
      });

      testWidgets('tapping add to group button navigates to add to group screen', (
        tester,
      ) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('add_to_group_button')));
        await tester.pumpAndSettle();

        expect(find.text('Add to group'), findsWidgets);
      });
    });

    group('start chat action', () {
      testWidgets('calls createGroup API with correct params', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('start_chat_button')));
        await tester.pumpAndSettle();

        expect(_api.createGroupCalls.length, 1);
        expect(_api.createGroupCalls[0].creatorPubkey, _testPubkey);
        expect(_api.createGroupCalls[0].memberPubkeys, [_otherPubkey]);
        expect(_api.createGroupCalls[0].groupType, GroupType.directMessage);
      });

      testWidgets('shows loading state during creation', (tester) async {
        _api.createGroupCompleter = Completer();
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('start_chat_button')));
        await tester.pump();

        final buttons = tester.widgetList<WnButton>(find.byType(WnButton)).toList();
        final startButton = buttons.firstWhere((b) => b.key == const Key('start_chat_button'));
        expect(startButton.loading, isTrue);
      });

      testWidgets('shows system notice on failure', (tester) async {
        _api.createGroupError = Exception('Network error');
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('start_chat_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to start chat. Please try again.'), findsOneWidget);
      });

      testWidgets('does not navigate when widget unmounted before DM creation completes', (
        tester,
      ) async {
        _api.createGroupCompleter = Completer<Group>();
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('start_chat_button')));
        await tester.pump();

        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsNothing);

        _api.createGroupCompleter!.complete(
          Group(
            mlsGroupId: testGroupId,
            nostrGroupId: testNostrGroupId,
            name: '',
            description: '',
            adminPubkeys: const [],
            epoch: BigInt.zero,
            state: GroupState.active,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('back button', () {
      testWidgets('navigates back when tapped', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsNothing);
      });
    });

    group('background tap', () {
      testWidgets('navigates back when background tapped', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsNothing);
      });
    });

    group('user without key packages', () {
      setUp(() {
        _api.userHasKeyPackageStatus = KeyPackageStatus.notFound;
      });

      testWidgets('shows invite callout', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('Invite to White Noise'), findsOneWidget);
      });

      testWidgets('does not show follow button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('follow_button')), findsNothing);
      });

      testWidgets('does not show start chat button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('start_chat_button')), findsNothing);
      });

      testWidgets('shows invite button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('invite_button')), findsOneWidget);
      });

      testWidgets('invite button shows correct label', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        final button = tester.widget<WnButton>(find.byKey(const Key('invite_button')));
        expect(button.text, 'Share');
      });

      testWidgets('handles share failure gracefully', (tester) async {
        mockSharePlusFailing();
        addTearDown(clearSharePlusMock);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('invite_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSlate), findsOneWidget);
      });

      testWidgets('tapping invite button calls SharePlus.instance.share with invite message', (
        tester,
      ) async {
        final shareCalls = mockSharePlus();
        addTearDown(clearSharePlusMock);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('invite_button')));
        await tester.pumpAndSettle();

        expect(shareCalls.length, 1);
        expect(shareCalls[0].text, contains('whitenoise.chat'));
      });

      group('invite callout description', () {
        testWidgets('uses displayName when available', (tester) async {
          _api.metadata = const FlutterMetadata(
            displayName: 'Alice',
            name: 'alice_nostr',
            custom: {},
          );
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text("Alice isn't on White Noise yet. Share the app to start a secure chat."),
            findsOneWidget,
          );
        });

        testWidgets('uses name when displayName is absent', (tester) async {
          _api.metadata = const FlutterMetadata(name: 'bob_nostr', custom: {});
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text(
              "bob_nostr isn't on White Noise yet. Share the app to start a secure chat.",
            ),
            findsOneWidget,
          );
        });

        testWidgets('uses generic message when no metadata names', (tester) async {
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text(
              "This user isn't on White Noise yet. Share the app to start a secure chat.",
            ),
            findsOneWidget,
          );
        });
      });
    });

    group('user with incompatible key packages', () {
      setUp(() {
        _api.userHasKeyPackageStatus = KeyPackageStatus.incompatible;
      });

      testWidgets('shows user needs update callout', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.text('Update required'), findsOneWidget);
      });

      testWidgets('does not show follow button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('follow_button')), findsNothing);
      });

      testWidgets('does not show start chat button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('start_chat_button')), findsNothing);
      });

      testWidgets('does not show invite button', (tester) async {
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
        expect(find.byKey(const Key('invite_button')), findsNothing);
      });

      group('invite callout description', () {
        testWidgets('uses displayName when available', (tester) async {
          _api.metadata = const FlutterMetadata(
            displayName: 'Alice',
            name: 'alice_nostr',
            custom: {},
          );
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text(
              "You can't start a secure chat with Alice yet. They need to update White Noise before secure messaging works.",
            ),
            findsOneWidget,
          );
        });

        testWidgets('uses name when displayName is absent', (tester) async {
          _api.metadata = const FlutterMetadata(name: 'bob_nostr', custom: {});
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text(
              "You can't start a secure chat with bob_nostr yet. They need to update White Noise before secure messaging works.",
            ),
            findsOneWidget,
          );
        });

        testWidgets('uses generic message when no metadata names', (tester) async {
          await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);
          expect(
            find.text(
              "You can't start a secure chat with this user yet. They need to update White Noise before secure messaging works.",
            ),
            findsOneWidget,
          );
        });
      });
    });

    group('system notice', () {
      testWidgets('shows notice when public key is copied', (tester) async {
        mockClipboard();
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pump();

        expect(find.text('Public key copied to clipboard'), findsOneWidget);
      });

      testWidgets('shows error notice when public key copy fails', (tester) async {
        mockClipboardFailing();
        addTearDown(clearClipboardMock);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();

        expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
      });

      testWidgets('dismisses notice after auto-hide duration', (tester) async {
        mockClipboard();
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Public key copied to clipboard'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.text('Public key copied to clipboard'), findsNothing);
      });
    });

    group('topAligned mode (from blocked-users list)', () {
      testWidgets('renders the blocked notice when the target is already blocked', (
        tester,
      ) async {
        _api.blockedPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        expect(find.byKey(const Key('blocked_user_detail_notice')), findsOneWidget);
        expect(find.byKey(const Key('unblock_button')), findsOneWidget);
      });

      testWidgets('renders the action panel when the target is not blocked', (
        tester,
      ) async {
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        expect(find.byKey(const Key('blocked_user_detail_notice')), findsNothing);
        expect(find.byKey(const Key('block_button')), findsOneWidget);
        expect(find.byKey(const Key('start_chat_button')), findsOneWidget);
      });

      testWidgets('tapping Unblock calls the unblock API', (tester) async {
        _api.blockedPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('unblock_button')));
        await tester.pumpAndSettle();

        expect(_api.unblockCalls.length, 1);
        expect(_api.unblockCalls[0].target, _otherPubkey);
      });

      testWidgets('Unblock failure surfaces an error notice', (tester) async {
        _api.blockedPubkeys.add(_otherPubkey);
        _api.unblockError = Exception('boom');
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('unblock_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to unblock user. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('tapping Block transitions to the blocked notice', (tester) async {
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('block_button')));
        await tester.pumpAndSettle();

        expect(_api.blockCalls.length, 1);
        expect(find.byKey(const Key('blocked_user_detail_notice')), findsOneWidget);
        expect(find.byKey(const Key('unblock_button')), findsOneWidget);
      });

      testWidgets('Block failure surfaces an error notice', (tester) async {
        _api.blockError = Exception('boom');
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('block_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to block user. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('tapping outside the slate dismisses the popup', (tester) async {
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tapAt(const Offset(50, 750));
        await tester.pumpAndSettle();

        expect(find.byType(UserProfileScreen), findsNothing);
      });

      testWidgets('toggles the blocked notice between collapsed and expanded', (
        tester,
      ) async {
        _api.blockedPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        final initial = tester.widget<WnSystemNotice>(
          find.byKey(const Key('blocked_user_detail_notice')),
        );
        expect(initial.variant, WnSystemNoticeVariant.expanded);

        await tester.tap(find.byKey(const Key('systemNotice_actionIcon')));
        await tester.pumpAndSettle();

        final collapsed = tester.widget<WnSystemNotice>(
          find.byKey(const Key('blocked_user_detail_notice')),
        );
        expect(collapsed.variant, WnSystemNoticeVariant.collapsed);
      });

      testWidgets('renders the invite share button when peer has no key package', (
        tester,
      ) async {
        _api.userHasKeyPackageStatus = KeyPackageStatus.notFound;
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        expect(find.byKey(const Key('invite_button')), findsOneWidget);
      });

      testWidgets('tapping invite button calls SharePlus with invite message', (
        tester,
      ) async {
        final shareCalls = mockSharePlus();
        addTearDown(clearSharePlusMock);
        _api.userHasKeyPackageStatus = KeyPackageStatus.notFound;
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('invite_button')));
        await tester.pumpAndSettle();

        expect(shareCalls, hasLength(1));
      });

      testWidgets('invite share failure is swallowed without rethrowing', (tester) async {
        mockSharePlusFailing();
        addTearDown(clearSharePlusMock);
        _api.userHasKeyPackageStatus = KeyPackageStatus.notFound;
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('invite_button')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('shows success notice on public key copy', (tester) async {
        mockClipboard();
        addTearDown(clearClipboardMock);
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();

        expect(find.text('Public key copied to clipboard'), findsOneWidget);
      });

      testWidgets('shows error notice on public key copy failure', (tester) async {
        mockClipboardFailing();
        addTearDown(clearClipboardMock);
        await pumpUserProfileScreen(
          tester,
          userPubkey: _otherPubkey,
          topAligned: true,
        );

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();

        expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
      });
    });

    group('bottom-aligned mode (default chat/search entry)', () {
      testWidgets('renders the blocked notice when the target is already blocked', (
        tester,
      ) async {
        _api.blockedPubkeys.add(_otherPubkey);
        await pumpUserProfileScreen(tester, userPubkey: _otherPubkey);

        expect(find.byKey(const Key('blocked_user_detail_notice')), findsOneWidget);
        expect(find.byKey(const Key('unblock_button')), findsOneWidget);
      });
    });

    group('UserProfileScreen.show', () {
      testWidgets('opens the screen as a modal with asShade enabled', (tester) async {
        await mountTestApp(
          tester,
          overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
        );
        await tester.pumpAndSettle();

        unawaited(
          UserProfileScreen.show(
            tester.element(find.byType(Scaffold)),
            userPubkey: _otherPubkey,
          ),
        );
        await tester.pumpAndSettle();

        final screen = tester.widget<UserProfileScreen>(find.byType(UserProfileScreen));
        expect(screen.asShade, isTrue);
        expect(screen.topAligned, isTrue);
        expect(screen.userPubkey, _otherPubkey);
      });
    });
  });
}
