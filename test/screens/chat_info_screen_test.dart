import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _otherPubkey = testPubkeyB;

class _MockApi extends MockWnApi {
  List<String> dmMembers = [_testPubkey, _otherPubkey];
  FlutterMetadata metadata = const FlutterMetadata(custom: {});
  bool archivedAtResult = false;
  Completer<FlutterMetadata>? metadataCompleter;
  Completer<void>? followCompleter;
  Completer<void>? unfollowCompleter;
  Exception? followError;
  Exception? unfollowError;
  Exception? groupError;
  final followCalls = <({String account, String target})>[];
  final unfollowCalls = <({String account, String target})>[];
  final Set<String> followingPubkeys = {};

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    if (groupError != null) throw groupError!;
    return Group(
      mlsGroupId: groupId,
      nostrGroupId: testNostrGroupId,
      name: '',
      description: '',
      adminPubkeys: const [],
      epoch: BigInt.zero,
      state: GroupState.active,
    );
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) async => true;

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async => dmMembers;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    if (metadataCompleter != null) return metadataCompleter!.future;
    return metadata;
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
    if (unfollowCompleter != null) await unfollowCompleter!.future;
    if (unfollowError != null) throw unfollowError!;
  }

  @override
  Future<bool> crateApiAccountsIsFollowingUser({
    required String accountPubkey,
    required String userPubkey,
  }) async {
    return followingPubkeys.contains(userPubkey);
  }

  @override
  void reset() {
    super.reset();
    metadata = const FlutterMetadata(custom: {});
    metadataCompleter = null;
    followCompleter = null;
    unfollowCompleter = null;
    followError = null;
    unfollowError = null;
    groupError = null;
    followCalls.clear();
    unfollowCalls.clear();
    followingPubkeys.clear();
    archivedAtResult = false;
    dmMembers = [_testPubkey, _otherPubkey];
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

  Future<void> pumpChatInfoScreen(
    WidgetTester tester, {
    String mlsGroupId = testGroupId,
    bool settle = true,
    bool showSearch = true,
  }) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    if (showSearch) {
      unawaited(Routes.pushToChatInfo(context, mlsGroupId));
    } else {
      unawaited(Routes.pushToInviteInfo(context, mlsGroupId));
    }
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('ChatInfoScreen', () {
    Finder chatInfoSlateFinder() {
      return find.ancestor(
        of: find.text('Chat Information'),
        matching: find.byType(WnSlate),
      );
    }

    testWidgets('displays slate container and chat info header', (tester) async {
      await pumpChatInfoScreen(tester);

      expect(chatInfoSlateFinder(), findsOneWidget);
      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('Chat Information'), findsOneWidget);
      expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
    });

    testWidgets('uses light overlay variant', (tester) async {
      await pumpChatInfoScreen(tester);

      final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
      expect(overlay.variant, WnOverlayVariant.light);
    });

    testWidgets('slate height matches content and is not full screen', (tester) async {
      await pumpChatInfoScreen(tester);

      final slateHeight = tester.getSize(chatInfoSlateFinder()).height;
      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(slateHeight, lessThan(screenHeight));
    });

    testWidgets('renders profile card and copy card', (tester) async {
      _api.metadata = const FlutterMetadata(displayName: 'Alice', custom: {});
      await pumpChatInfoScreen(tester);

      expect(find.byType(WnAvatar), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(WnCopyCard), findsOneWidget);
    });

    testWidgets('does not render nip05 and about in chat info card', (tester) async {
      _api.metadata = const FlutterMetadata(
        displayName: 'Alice',
        nip05: 'alice@example.com',
        about: 'I love Nostr!',
        custom: {},
      );
      await pumpChatInfoScreen(tester);

      expect(find.text('alice@example.com'), findsNothing);
      expect(find.text('I love Nostr!'), findsNothing);
    });

    testWidgets('shows add as contact for non-followed user', (tester) async {
      await pumpChatInfoScreen(tester);
      expect(find.text('Add as contact'), findsOneWidget);
    });

    testWidgets('shows remove as contact for followed user', (tester) async {
      _api.followingPubkeys.add(_otherPubkey);
      await pumpChatInfoScreen(tester);
      expect(find.text('Remove as contact'), findsOneWidget);
    });

    testWidgets('calls follow API when follow is tapped', (tester) async {
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pumpAndSettle();

      expect(_api.followCalls.length, 1);
      expect(_api.followCalls[0].account, _testPubkey);
      expect(_api.followCalls[0].target, _otherPubkey);
    });

    testWidgets('calls unfollow API when unfollow is tapped', (tester) async {
      _api.followingPubkeys.add(_otherPubkey);
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pumpAndSettle();

      expect(_api.unfollowCalls.length, 1);
      expect(_api.unfollowCalls[0].account, _testPubkey);
      expect(_api.unfollowCalls[0].target, _otherPubkey);
    });

    testWidgets('shows contact button loading state during follow action', (tester) async {
      _api.followCompleter = Completer();
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pump();

      final button = tester.widget<WnButton>(find.byKey(const Key('contact_button')));
      expect(button.loading, isTrue);
    });

    testWidgets('shows error notice when follow action fails', (tester) async {
      _api.followError = Exception('Network error');
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to update follow status. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error notice when unfollow action fails', (tester) async {
      _api.followingPubkeys.add(_otherPubkey);
      _api.unfollowError = Exception('Network error');
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to update follow status. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('hides peer actions when dm peer pubkey is unresolved', (tester) async {
      _api.dmMembers = [_testPubkey];
      await pumpChatInfoScreen(tester);

      expect(find.byKey(const Key('contact_button')), findsNothing);
      expect(find.byKey(const Key('search_button')), findsNothing);
      expect(find.byKey(const Key('add_to_group_button')), findsNothing);
      expect(find.byKey(const Key('archive_button')), findsNothing);
      expect(_api.followCalls, isEmpty);
      expect(_api.unfollowCalls, isEmpty);
    });

    testWidgets('shows notice when public key is copied', (tester) async {
      mockClipboard();
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pump();

      expect(find.text('Public key copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows error notice when public key copy fails', (tester) async {
      mockClipboardFailing();
      addTearDown(clearClipboardMock);
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
    });

    testWidgets('dismisses notice after auto-hide duration', (tester) async {
      mockClipboard();
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WnSystemNotice), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsNothing);
    });

    testWidgets('pops screen when search is pressed', (tester) async {
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chat Information'), findsNothing);
    });

    testWidgets('does not show mute action', (tester) async {
      await pumpChatInfoScreen(tester);

      expect(find.byKey(const Key('mute_button')), findsNothing);
      expect(find.text('Mute'), findsNothing);
    });

    testWidgets('navigates to add to group screen when add to group is pressed', (tester) async {
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('add_to_group_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add to group'), findsWidgets);
    });

    testWidgets('navigates back when back button is pressed', (tester) async {
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chat Information'), findsNothing);
    });

    testWidgets('does not show archive or delete actions', (tester) async {
      await pumpChatInfoScreen(tester);

      expect(find.text('Delete chat'), findsNothing);
    });

    testWidgets('shows archive button when chat is not archived', (tester) async {
      _api.archivedAtResult = false;
      await pumpChatInfoScreen(tester);

      expect(find.widgetWithText(WnButton, 'Archive'), findsOneWidget);
    });

    testWidgets('shows unarchive button when chat is archived', (tester) async {
      _api.archivedAtResult = true;
      await pumpChatInfoScreen(tester);

      expect(find.widgetWithText(WnButton, 'Unarchive'), findsOneWidget);
    });

    testWidgets('calls archive API when archive is tapped', (tester) async {
      _api.archivedAtResult = false;
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.archiveChatCallCount, 1);
    });

    testWidgets('calls unarchive API when unarchive is tapped', (tester) async {
      _api.archivedAtResult = true;
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(_api.unarchiveChatCallCount, 1);
    });

    testWidgets('shows archive failure notice when archive action fails', (tester) async {
      _api.archivedAtResult = false;
      _api.shouldFailArchiveChat = true;
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to archive chat. Please try again.'), findsOneWidget);
    });

    testWidgets('shows unarchive failure notice when unarchive action fails', (tester) async {
      _api.archivedAtResult = true;
      _api.shouldFailUnarchiveChat = true;
      await pumpChatInfoScreen(tester);

      await tester.tap(find.byKey(const Key('archive_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to unarchive chat. Please try again.'), findsOneWidget);
    });

    testWidgets('hides search button when opened from invite', (tester) async {
      await pumpChatInfoScreen(tester, showSearch: false);

      expect(find.byKey(const Key('search_button')), findsNothing);
      expect(find.byKey(const Key('contact_button')), findsOneWidget);
      expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
    });

    testWidgets('shows profile load error when chat profile fails', (tester) async {
      _api.groupError = Exception('group load failed');
      await pumpChatInfoScreen(tester);

      expect(find.text('Unable to load profile. Please try again.'), findsOneWidget);
    });
  });
}
