import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/screens/start_support_chat_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/user_search.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _emptyMetadata = FlutterMetadata(custom: {});

User _userFactory(String pubkey, {String? displayName}) => User(
  pubkey: pubkey,
  metadata: FlutterMetadata(displayName: displayName, custom: const {}),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _MockApi extends MockWnApi {
  final Map<String, User> userByPubkey = {};
  final Map<String, String> npubToPubkey = {};
  final Set<String> errorPubkeys = {};
  final Map<String, String?> dmGroupByPeer = {};

  @override
  Future<List<User>> crateApiAccountsAccountFollows({required String pubkey}) async {
    return follows;
  }

  @override
  Future<User> crateApiUsersGetUser({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    if (errorPubkeys.contains(pubkey)) throw Exception('User not found');
    final user = userByPubkey[pubkey];
    if (user == null) throw Exception('User not found');
    return user;
  }

  @override
  String crateApiUtilsHexPubkeyFromNpub({required String npub}) {
    final pubkey = npubToPubkey[npub];
    if (pubkey == null) throw Exception('Invalid npub');
    return pubkey;
  }

  @override
  Future<String?> crateApiAccountGroupsGetDmGroupWithPeer({
    required String accountPubkey,
    required String peerPubkey,
  }) async {
    return dmGroupByPeer['$accountPubkey|$peerPubkey'];
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

  setUp(() {
    _api.follows = [];
    _api.userByPubkey.clear();
    _api.npubToPubkey.clear();
    _api.errorPubkeys.clear();
    _api.searchUsersController?.close();
    _api.searchUsersController = null;
    _api.dmGroupByPeer.clear();
  });

  Future<void> pumpUserSearchScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToUserSearch(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('UserSearchScreen', () {
    testWidgets('displays slate container', (tester) async {
      await pumpUserSearchScreen(tester);
      expect(find.byType(WnSlate), findsOneWidget);
    });

    testWidgets('displays screen header with title', (tester) async {
      await pumpUserSearchScreen(tester);
      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('Start new chat'), findsOneWidget);
    });

    testWidgets('displays search field', (tester) async {
      await pumpUserSearchScreen(tester);
      expect(find.text('Name or npub1...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays new group chat menu item with icon', (tester) async {
      await pumpUserSearchScreen(tester);
      expect(find.byKey(const Key('create_group_menu_item')), findsOneWidget);
      expect(find.text('New group chat'), findsOneWidget);
      expect(find.byKey(const Key('menu_item_icon')), findsAtLeast(1));
    });

    testWidgets('tapping new group chat menu item navigates to user selection', (tester) async {
      await pumpUserSearchScreen(tester);

      await tester.tap(find.byKey(const Key('create_group_menu_item')));
      await tester.pumpAndSettle();

      expect(find.text('New group chat'), findsAtLeast(1));
    });

    testWidgets('tapping back button goes back', (tester) async {
      await pumpUserSearchScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    group('without follows', () {
      setUp(() => _api.follows = []);

      testWidgets('shows no follows message', (tester) async {
        await pumpUserSearchScreen(tester);
        expect(find.text('No follows yet'), findsOneWidget);
      });
    });

    group('with follows', () {
      setUp(() {
        _api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Bob'),
        ];
      });

      testWidgets('shows follows list using WnUserItem', (tester) async {
        await pumpUserSearchScreen(tester);
        expect(find.byType(WnUserItem), findsOneWidget);
        expect(find.text('Alice'), findsNothing);
        expect(find.text('Bob'), findsOneWidget);
      });

      testWidgets('hides no follows message', (tester) async {
        await pumpUserSearchScreen(tester);
        expect(find.text('No follows yet'), findsNothing);
      });

      testWidgets('shows formatted npub as subtitle', (tester) async {
        await pumpUserSearchScreen(tester);
        final npubWidgets = tester
            .widgetList<WnMiddleEllipsisText>(find.byKey(const Key('user_item_npub')))
            .toList();
        expect(npubWidgets.any((w) => w.text.startsWith('npub 1a1b')), isFalse);
        expect(npubWidgets.any((w) => w.text.startsWith('npub 1b2c')), isTrue);
      });

      testWidgets('passes color derived from pubkey to each avatar', (tester) async {
        await pumpUserSearchScreen(tester);

        final userItems = tester.widgetList<WnUserItem>(find.byType(WnUserItem)).toList();
        expect(userItems.length, 1);
        expect(userItems[0].avatarColor, AvatarColor.amber);
      });
    });

    group('npub search', () {
      setUp(() {
        _api.npubToPubkey[testNpubC] = testPubkeyC;
        _api.userByPubkey[testPubkeyC] = _userFactory(testPubkeyC, displayName: 'Searched User');
        _api.follows = [_userFactory(testPubkeyC, displayName: 'Follow')];
      });

      testWidgets('shows search result when valid npub entered', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), testNpubC);
        await tester.pumpAndSettle();

        expect(find.text('Searched User'), findsOneWidget);
        expect(find.text('Follow'), findsNothing);
      });

      testWidgets('shows filtered follows for invalid npub format', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), testNpubC.substring(0, 10));
        await tester.pumpAndSettle();

        expect(find.text('Follow'), findsOneWidget);
      });

      testWidgets('shows follows list when search cleared', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), testNpubC);
        await tester.pumpAndSettle();
        expect(find.text('Searched User'), findsOneWidget);

        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        expect(find.text('Follow'), findsOneWidget);
      });
    });

    group('user without display name', () {
      setUp(() {
        _api.follows = [
          User(
            pubkey: testPubkeyC,
            metadata: _emptyMetadata,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ];
      });

      testWidgets('shows formatted npub as display name and subtitle', (tester) async {
        await pumpUserSearchScreen(tester);

        final userItem = tester.widget<WnUserItem>(find.byType(WnUserItem));
        expect(userItem.displayName, startsWith('npub 1c3d'));

        final npubWidget = tester.widget<WnMiddleEllipsisText>(
          find.byKey(const Key('user_item_npub')),
        );
        expect(npubWidget.text, startsWith('npub 1c3d'));
      });
    });

    group('user with empty displayName but valid name', () {
      setUp(() {
        _api.follows = [
          User(
            pubkey: testPubkeyC,
            metadata: const FlutterMetadata(displayName: '', name: 'ValidName', custom: {}),
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ];
      });

      testWidgets('falls back to name when displayName is empty', (tester) async {
        await pumpUserSearchScreen(tester);

        expect(find.text('ValidName'), findsOneWidget);
        final ellipsisWidgets = tester
            .widgetList<WnMiddleEllipsisText>(find.byType(WnMiddleEllipsisText))
            .toList();
        expect(ellipsisWidgets.any((w) => w.text.startsWith('npub 1c3d')), isTrue);
      });
    });

    group('partial npub search', () {
      setUp(() {
        _api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Bob'),
        ];
      });

      testWidgets('shows filtered follows for partial npub', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), 'npub1b2c');
        await tester.pumpAndSettle();

        expect(find.text('Alice'), findsNothing);
        expect(find.text('Bob'), findsOneWidget);
      });

      testWidgets('shows no results when no follows match', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), 'npub1xyz');
        await tester.pumpAndSettle();

        expect(find.text('No results'), findsOneWidget);
      });
    });

    group('name search', () {
      testWidgets('shows results for name query', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), 'alice');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        _api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [
              const UserSearchResult(
                pubkey: testPubkeyC,
                metadata: FlutterMetadata(displayName: 'Alice', custom: {}),
                radius: 0,
                matchQuality: MatchQuality.exact,
                bestField: MatchedField.name,
                matchedFields: [MatchedField.name],
              ),
            ],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.text('Alice'), findsOneWidget);
      });

      testWidgets('shows no results when search completes empty', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), 'zzzznonexistent');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        _api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: SearchUpdateTrigger.searchCompleted(
              finalRadius: 2,
              totalResults: BigInt.zero,
            ),
            newResults: const [],
            totalResultCount: BigInt.zero,
          ),
        );
        await tester.pump();

        expect(find.text('No results'), findsOneWidget);
      });
    });

    group('user not found', () {
      const validNpub = 'npub1notfound';

      setUp(() {
        _api.npubToPubkey[validNpub] = testPubkeyD;
        _api.errorPubkeys.add(testPubkeyD);
      });

      testWidgets('shows no results when metadata lookup fails', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), validNpub);
        await tester.pumpAndSettle();

        expect(find.text('No results'), findsOneWidget);
      });
    });

    group('user tap navigates to start chat screen', () {
      setUp(() {
        _api.follows = [_userFactory(testPubkeyB, displayName: 'Bob')];
      });

      testWidgets('navigates to start chat screen when tapping user', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.tap(find.text('Bob'));
        await tester.pumpAndSettle();

        expect(find.text('Start new chat'), findsOneWidget);
        expect(find.byKey(const Key('start_chat_button')), findsOneWidget);
      });

      testWidgets('shows follow button on start chat screen', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.tap(find.text('Bob'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('follow_button')), findsOneWidget);
      });
    });

    group('search result tap navigates to start chat screen', () {
      setUp(() {
        _api.npubToPubkey[testNpubD] = testPubkeyD;
        _api.userByPubkey[testPubkeyD] = _userFactory(testPubkeyD, displayName: 'Found User');
      });

      testWidgets('navigates to start chat screen when tapping search result', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.enterText(find.byType(TextField), testNpubD);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Found User'));
        await tester.pumpAndSettle();

        expect(find.text('Start new chat'), findsOneWidget);
        expect(find.byKey(const Key('start_chat_button')), findsOneWidget);
      });
    });

    group('scan button', () {
      testWidgets('displays scan button', (tester) async {
        await pumpUserSearchScreen(tester);
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
      });

      testWidgets('navigates to scan npub screen when tapped', (tester) async {
        await pumpUserSearchScreen(tester);
        await tester.tap(find.byKey(const Key('scan_button')));
        await tester.pumpAndSettle();

        expect(find.text("Scan a contact's QR code."), findsOneWidget);
      });
    });

    group('chat with support', () {
      testWidgets('displays chat with support menu item', (tester) async {
        await pumpUserSearchScreen(tester);
        expect(find.byKey(const Key('help_and_feedback_menu_item')), findsOneWidget);
        expect(find.text('Chat with support'), findsOneWidget);
      });

      testWidgets('navigates to existing DM when one exists', (tester) async {
        _api.dmGroupByPeer['$testPubkeyA|1136006d965b8ffb0e8d0e842750d68a6cd06093957f14bcefb47bb228f0cc35'] =
            testGroupId;
        await pumpUserSearchScreen(tester);

        await tester.tap(find.byKey(const Key('help_and_feedback_menu_item')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatScreen), findsOneWidget);
      });

      testWidgets('navigates to start help chat when no DM exists', (tester) async {
        await pumpUserSearchScreen(tester);

        await tester.tap(find.byKey(const Key('help_and_feedback_menu_item')));
        await tester.pumpAndSettle();

        expect(find.byType(StartSupportChatScreen), findsOneWidget);
      });
    });
  });
}
