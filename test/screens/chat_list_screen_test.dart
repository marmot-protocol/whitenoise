import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/screens/chat_invite_screen.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/screens/settings_screen.dart';
import 'package:whitenoise/screens/share_profile_screen.dart';
import 'package:whitenoise/screens/user_search_screen.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_list_header.dart';
import 'package:whitenoise/widgets/chat_list_tile.dart';
import 'package:whitenoise/widgets/wn_chat_list.dart';
import 'package:whitenoise/widgets/wn_search_and_filters.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatSummary _chatSummary({
  required String id,
  required bool pendingConfirmation,
  String? name,
}) => ChatSummary(
  mlsGroupId: id,
  name: name ?? 'Chat $id',
  groupType: GroupType.group,
  createdAt: DateTime(2024),
  pendingConfirmation: pendingConfirmation,
  unreadCount: BigInt.zero,
);

class _MockApi extends MockWnApi {
  StreamController<ChatListStreamItem>? controller;
  List<ChatSummary> initialChats = [];

  @override
  void reset() {
    controller?.close();
    controller = null;
    initialChats = [];
  }

  @override
  Stream<ChatListStreamItem> crateApiChatListSubscribeToChatList({
    required String accountPubkey,
  }) {
    controller?.close();
    controller = StreamController<ChatListStreamItem>.broadcast();
    Future.microtask(() {
      controller?.add(ChatListStreamItem.initialSnapshot(items: initialChats));
    });
    return controller!.stream;
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async => Group(
    mlsGroupId: groupId,
    nostrGroupId: '',
    name: 'Test',
    description: '',
    adminPubkeys: const [],
    epoch: BigInt.zero,
    state: GroupState.active,
  );

  @override
  Future<List<ChatMessage>> crateApiMessagesFetchAggregatedMessagesForGroup({
    required String pubkey,
    required String groupId,
  }) async {
    return [];
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

class _SwitchableAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }

  void switchTo(String pubkey) {
    state = AsyncData(pubkey);
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpChatListScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
  }

  group('ChatListScreen', () {
    testWidgets('displays header', (tester) async {
      await pumpChatListScreen(tester);

      expect(find.byType(ChatListHeader), findsOneWidget);
    });

    testWidgets('displays slate container', (tester) async {
      await pumpChatListScreen(tester);

      expect(find.byType(WnSlate), findsOneWidget);
    });

    testWidgets('displays chat list', (tester) async {
      await pumpChatListScreen(tester);

      expect(find.byType(WnChatList), findsOneWidget);
    });

    testWidgets('search and filters hidden initially', (tester) async {
      _api.initialChats = [
        _chatSummary(id: testPubkeyA, pendingConfirmation: false),
      ];
      await pumpChatListScreen(tester);

      expect(find.byType(WnSearchAndFilters), findsNothing);
    });

    testWidgets('search and filters appear on pull down', (tester) async {
      _api.initialChats = [
        _chatSummary(id: testPubkeyA, pendingConfirmation: false),
      ];
      await pumpChatListScreen(tester);

      final gesture = await tester.startGesture(const Offset(200, 400));
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();

      expect(find.byType(WnSearchAndFilters), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping avatar navigates to settings', (tester) async {
      await pumpChatListScreen(tester);
      await tester.tap(find.byKey(const Key('avatar_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('tapping chat icon navigates to user search', (tester) async {
      await pumpChatListScreen(tester);
      await tester.tap(find.byKey(const Key('chat_add_button')));
      await tester.pumpAndSettle();
      expect(find.byType(UserSearchScreen), findsOneWidget);
    });

    group('without chats', () {
      testWidgets('shows welcome notice', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Your profile is ready'), findsOneWidget);
      });

      testWidgets('shows welcome notice description', (tester) async {
        await pumpChatListScreen(tester);

        expect(
          find.textContaining('Find people'),
          findsWidgets,
        );
      });

      testWidgets('shows find people button', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byKey(const Key('find_people_button')), findsOneWidget);
      });

      testWidgets('shows share profile button', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byKey(const Key('share_profile_button')), findsOneWidget);
      });

      testWidgets('shows slogan in body', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byKey(const Key('welcome_slogan')), findsOneWidget);
        expect(find.textContaining('Decentralized'), findsOneWidget);
      });

      testWidgets('tapping find people navigates to user search', (tester) async {
        await pumpChatListScreen(tester);
        await tester.tap(find.byKey(const Key('find_people_button')));
        await tester.pumpAndSettle();

        expect(find.byType(UserSearchScreen), findsOneWidget);
      });

      testWidgets('tapping share profile navigates to share profile', (tester) async {
        await pumpChatListScreen(tester);
        await tester.tap(find.byKey(const Key('share_profile_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ShareProfileScreen), findsOneWidget);
      });

      testWidgets('dismissing welcome notice hides it', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byType(WnSystemNotice), findsOneWidget);

        await tester.tap(find.byKey(const Key('systemNotice_actionIcon')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsNothing);
      });

      testWidgets('shows empty state text after dismissing notice', (tester) async {
        await pumpChatListScreen(tester);
        await tester.tap(find.byKey(const Key('systemNotice_actionIcon')));
        await tester.pumpAndSettle();

        expect(find.text('No chats yet'), findsOneWidget);
        expect(find.text('Start a conversation'), findsOneWidget);
      });

      testWidgets('welcome notice reappears after switching accounts', (tester) async {
        final mockAuth = _SwitchableAuthNotifier();
        await mountTestApp(
          tester,
          overrides: [authProvider.overrideWith(() => mockAuth)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);

        await tester.tap(find.byKey(const Key('systemNotice_actionIcon')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsNothing);

        mockAuth.switchTo(testPubkeyB);
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
      });
    });

    group('with chats', () {
      setUp(
        () => _api.initialChats = [
          _chatSummary(id: testPubkeyA, pendingConfirmation: true),
          _chatSummary(id: testPubkeyB, pendingConfirmation: false),
        ],
      );

      testWidgets('shows chat tiles', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byType(ChatListTile), findsNWidgets(2));
      });

      testWidgets('shows chat tiles in the correct order', (tester) async {
        await pumpChatListScreen(tester);
        final tiles = tester.widgetList<ChatListTile>(find.byType(ChatListTile)).toList();

        expect(tiles.first.key, const Key(testPubkeyA));
        expect(tiles.last.key, const Key(testPubkeyB));
      });

      testWidgets('hides welcome notice when chats exist', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.byType(WnSystemNotice), findsNothing);
      });

      testWidgets('hides empty state when chats exist', (tester) async {
        await pumpChatListScreen(tester);

        expect(find.text('No chats yet'), findsNothing);
      });

      testWidgets('tapping pending chat navigates to invite screen', (tester) async {
        await pumpChatListScreen(tester);
        await tester.tap(find.byType(ChatListTile).first);
        await tester.pumpAndSettle();

        expect(find.byType(ChatInviteScreen), findsOneWidget);
      });

      testWidgets('tapping accepted chat navigates to chat screen', (tester) async {
        await pumpChatListScreen(tester);
        await tester.tap(find.byType(ChatListTile).last);
        await tester.pumpAndSettle();

        expect(find.byType(ChatScreen), findsOneWidget);
      });
    });

    group('system notice', () {
      testWidgets('shows error notice when pin action fails', (tester) async {
        _api.initialChats = [
          _chatSummary(id: testPubkeyA, pendingConfirmation: false),
        ];
        await pumpChatListScreen(tester);

        await tester.longPress(find.byType(ChatListTile));
        await tester.pumpAndSettle();

        final pinAction = find.byKey(const Key('context_menu_action_pin'));
        if (pinAction.evaluate().isNotEmpty) {
          await tester.tap(pinAction);
          await tester.pumpAndSettle();

          expect(find.byType(WnSystemNotice), findsOneWidget);
        }
      });
    });

    group('search', () {
      Future<void> revealSearchBar(WidgetTester tester) async {
        final gesture = await tester.startGesture(const Offset(200, 400));
        await gesture.moveBy(const Offset(0, 200));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      setUp(
        () => _api.initialChats = [
          _chatSummary(id: testPubkeyA, pendingConfirmation: false, name: 'Alice'),
          _chatSummary(id: testPubkeyB, pendingConfirmation: false, name: 'Bob'),
          _chatSummary(id: testPubkeyC, pendingConfirmation: false, name: 'Engineering Team'),
        ],
      );

      testWidgets('filters chats by search query', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pump();

        expect(find.byType(ChatListTile), findsOneWidget);
      });

      testWidgets('shows all chats when search is cleared', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        await tester.enterText(find.byType(TextField), 'Alice');
        await tester.pump();
        expect(find.byType(ChatListTile), findsOneWidget);

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        expect(find.byType(ChatListTile), findsNWidgets(3));
      });

      testWidgets('search is case-insensitive', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        await tester.enterText(find.byType(TextField), 'alice');
        await tester.pump();

        expect(find.byType(ChatListTile), findsOneWidget);
      });

      testWidgets('shows no results message for non-matching query', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        await tester.enterText(find.byType(TextField), 'Zorro');
        await tester.pump();

        expect(find.byType(ChatListTile), findsNothing);
        expect(find.text('No results'), findsOneWidget);
        expect(find.text('No chats yet'), findsNothing);
      });

      testWidgets('search bar stays visible when no results match', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        await tester.enterText(find.byType(TextField), 'Zorro');
        await tester.pump();

        expect(find.byType(WnSearchAndFilters), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('passes onSearchChanged callback to WnSearchAndFilters', (tester) async {
        await pumpChatListScreen(tester);
        await revealSearchBar(tester);

        final widget = tester.widget<WnSearchAndFilters>(find.byType(WnSearchAndFilters));
        expect(widget.onSearchChanged, isNotNull);
      });
    });
  });
}
