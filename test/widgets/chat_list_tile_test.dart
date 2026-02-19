import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show PlatformInt64;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_list_tile.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_list_context_menu.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatSummary _chatSummary({
  String? name,
  GroupType groupType = GroupType.group,
  bool pendingConfirmation = false,
  String? lastMessageContent,
  String? lastMessageAuthor,
  String? lastMessageAuthorDisplayName,
  String? groupImagePath,
  String? groupImageUrl,
  String? welcomerPubkey,
  String? dmPeerPubkey,
  int? pinOrder,
}) => ChatSummary(
  mlsGroupId: testGroupId,
  name: name,
  groupType: groupType,
  createdAt: DateTime(2024),
  pendingConfirmation: pendingConfirmation,
  unreadCount: BigInt.zero,
  groupImagePath: groupImagePath,
  groupImageUrl: groupImageUrl,
  welcomerPubkey: welcomerPubkey,
  dmPeerPubkey: dmPeerPubkey,
  pinOrder: pinOrder,
  lastMessage: lastMessageContent != null
      ? ChatMessageSummary(
          mlsGroupId: testGroupId,
          author:
              lastMessageAuthor ??
              '0000000000000000000000000000000000000000000000000000000000000000',
          authorDisplayName: lastMessageAuthorDisplayName,
          content: lastMessageContent,
          createdAt: DateTime(2024),
          mediaAttachmentCount: BigInt.zero,
        )
      : null,
);

class _MockApi extends MockWnApi {
  FlutterMetadata welcomerMetadata = const FlutterMetadata(custom: {});
  bool shouldThrow = false;
  bool shouldThrowOnPin = false;
  int setChatPinOrderCallCount = 0;
  PlatformInt64? lastPinOrder;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return welcomerMetadata;
  }

  @override
  Future<void> crateApiChatListSetChatPinOrder({
    required String accountPubkey,
    required String mlsGroupId,
    PlatformInt64? pinOrder,
  }) async {
    if (shouldThrowOnPin) throw Exception('Pin order update failed');
    setChatPinOrderCallCount++;
    lastPinOrder = pinOrder;
  }
}

final _api = _MockApi();

class MockAccountPubkeyNotifier extends AccountPubkeyNotifier {
  @override
  String build() => testPubkeyA;
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() {
    _api.welcomerMetadata = const FlutterMetadata(custom: {});
    _api.shouldThrow = false;
    _api.shouldThrowOnPin = false;
    _api.setChatPinOrderCallCount = 0;
    _api.lastPinOrder = null;
  });

  Future<void> pumpTile(
    WidgetTester tester,
    ChatSummary chatSummary, {
    bool settle = true,
    void Function(String)? onError,
  }) async {
    await mountWidget(
      ChatListTile(chatSummary: chatSummary, onError: onError),
      tester,
      overrides: [
        accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
      ],
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('ChatListTile', () {
    group('title', () {
      testWidgets('shows name when present', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'My Group'));
        expect(find.text('My Group'), findsOneWidget);
      });

      testWidgets('shows name for DM with name', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(name: 'Alice', groupType: GroupType.directMessage),
        );
        expect(find.text('Alice'), findsOneWidget);
      });

      testWidgets('shows "Unknown user" for DM without name', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(groupType: GroupType.directMessage),
        );
        expect(find.text('Unknown user'), findsOneWidget);
      });

      testWidgets('shows "Unknown group" for group without name', (tester) async {
        await pumpTile(tester, _chatSummary());
        expect(find.text('Unknown group'), findsOneWidget);
      });

      testWidgets('shows "Unknown user" for DM with empty name', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(name: '', groupType: GroupType.directMessage),
        );
        expect(find.text('Unknown user'), findsOneWidget);
      });
    });

    group('subtitle', () {
      group('when pending', () {
        group('DM', () {
          testWidgets('shows invite message when no messages', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                groupType: GroupType.directMessage,
                pendingConfirmation: true,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Has invited you to a secure chat');
          });

          testWidgets('shows last message when messages exist', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                groupType: GroupType.directMessage,
                pendingConfirmation: true,
                lastMessageContent: 'Hello from pending chat',
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Hello from pending chat');
          });
        });

        group('group', () {
          testWidgets('uses group name as avatarName when present', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                name: 'Dev Team',
                pendingConfirmation: true,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.title, 'Dev Team');
            final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
            expect(avatar.displayName, 'Dev Team');
          });

          testWidgets('shows welcomer name in invite when available', (tester) async {
            _api.welcomerMetadata = const FlutterMetadata(
              displayName: 'Charlie',
              custom: {},
            );
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                welcomerPubkey: testPubkeyB,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Charlie has invited you to a secure chat');
          });

          testWidgets('shows generic invite without welcomer metadata', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(pendingConfirmation: true),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'You have been invited to a secure chat');
          });

          testWidgets('shows generic invite when metadata fetch fails', (tester) async {
            _api.shouldThrow = true;
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                welcomerPubkey: testPubkeyB,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'You have been invited to a secure chat');
          });

          testWidgets('shows generic invite when metadata has only picture', (tester) async {
            _api.welcomerMetadata = const FlutterMetadata(
              picture: 'https://example.com/avatar.png',
              custom: {},
            );
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                welcomerPubkey: testPubkeyB,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'You have been invited to a secure chat');
          });

          testWidgets('shows last message when messages exist', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageContent: 'Group message in pending chat',
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Group message in pending chat');
          });
        });
      });

      testWidgets('shows last message content when available', (tester) async {
        await pumpTile(tester, _chatSummary(lastMessageContent: 'Hello world'));
        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.subtitle, 'Hello world');
      });

      testWidgets('shows prefix "You: " when last message is from me', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            lastMessageContent: 'Hello world',
            lastMessageAuthor: testPubkeyA,
          ),
        );

        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.prefixSubtitle, 'You: ');
        expect(item.subtitle, 'Hello world');
      });

      testWidgets(
        'shows prefix "{name}: " for group chat messages from others',
        (tester) async {
          await pumpTile(
            tester,
            _chatSummary(
              name: 'Dev Team',
              lastMessageContent: 'Hello everyone',
              lastMessageAuthor: testPubkeyB,
              lastMessageAuthorDisplayName: 'Alice',
            ),
          );

          final finder = find.byType(WnChatListItem);
          final item = tester.widget<WnChatListItem>(finder);
          expect(item.prefixSubtitle, 'Alice: ');
          expect(item.subtitle, 'Hello everyone');
        },
      );

      testWidgets('does not show name prefix for DM messages from others', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            name: 'Alice',
            groupType: GroupType.directMessage,
            lastMessageContent: 'Hello',
            lastMessageAuthor: testPubkeyB,
            lastMessageAuthorDisplayName: 'Alice',
          ),
        );

        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.prefixSubtitle, isNull);
        expect(item.subtitle, 'Hello');
      });

      testWidgets('does not show name prefix when authorDisplayName is null', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            name: 'Dev Team',
            lastMessageContent: 'Hello',
            lastMessageAuthor: testPubkeyB,
          ),
        );

        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.prefixSubtitle, isNull);
        expect(item.subtitle, 'Hello');
      });

      testWidgets('does not show name prefix when authorDisplayName is empty', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            name: 'Dev Team',
            lastMessageContent: 'Hello',
            lastMessageAuthor: testPubkeyB,
            lastMessageAuthorDisplayName: '',
          ),
        );

        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.prefixSubtitle, isNull);
        expect(item.subtitle, 'Hello');
      });

      testWidgets('shows "You:" not sender name for own messages in groups', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            name: 'Dev Team',
            lastMessageContent: 'My message',
            lastMessageAuthor: testPubkeyA,
            lastMessageAuthorDisplayName: 'My Name',
          ),
        );

        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.prefixSubtitle, 'You: ');
        expect(item.subtitle, 'My message');
      });

      testWidgets('shows empty string when no last message', (tester) async {
        await pumpTile(tester, _chatSummary());
        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.subtitle, '');
      });
    });

    group('avatar', () {
      testWidgets('receives expected name', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'My Group'));
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.displayName, 'My Group');
      });

      testWidgets('uses groupImagePath for groups', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(groupImagePath: '/path/to/image'),
          settle: false,
        );
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.pictureUrl, '/path/to/image');
      });

      testWidgets('uses groupImageUrl for DMs', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(
            groupType: GroupType.directMessage,
            groupImageUrl: 'https://example.com/avatar.png',
          ),
          settle: false,
        );
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.pictureUrl, 'https://example.com/avatar.png');
      });

      testWidgets('group uses color derived from mlsGroupId', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test'));
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.color, AvatarColor.fromPubkey(testGroupId));
      });

      testWidgets('DM uses color derived from dmPeerPubkey when available', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(
            groupType: GroupType.directMessage,
            dmPeerPubkey: testPubkeyB,
          ),
          settle: false,
        );
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.color, AvatarColor.fromPubkey(testPubkeyB));
      });

      testWidgets('DM falls back to mlsGroupId when dmPeerPubkey is null', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(groupType: GroupType.directMessage),
          settle: false,
        );
        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.color, AvatarColor.fromPubkey(testGroupId));
      });

      testWidgets('uses medium size', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test'));

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.size, WnAvatarSize.medium);
      });

      testWidgets('shows pin badge when pinOrder is set', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Pinned', pinOrder: 1));

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.showPinned, isTrue);
      });

      testWidgets('does not show pin badge when pinOrder is null', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Not Pinned'));

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.showPinned, isFalse);
      });
    });

    group('navigation', () {
      GoRouter buildRouter(initialLocation) {
        return GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/pending',
              builder: (_, _) => Scaffold(
                body: ChatListTile(chatSummary: _chatSummary(pendingConfirmation: true)),
              ),
            ),
            GoRoute(
              path: '/not-pending',
              builder: (_, _) => Scaffold(
                body: ChatListTile(chatSummary: _chatSummary()),
              ),
            ),
            GoRoute(
              name: 'invite',
              path: '/invites/:mlsGroupId',
              builder: (_, _) => const Text('Invite Screen'),
            ),
            GoRoute(
              name: 'chat',
              path: '/chats/:groupId',
              builder: (_, _) => const Text('Chat Screen'),
            ),
          ],
        );
      }

      group('when pending', () {
        testWidgets('navigates to invite when pending', (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
              ],
              child: ScreenUtilInit(
                designSize: testDesignSize,
                builder: (_, _) => MaterialApp.router(
                  routerConfig: buildRouter('/pending'),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ChatListTile));
          await tester.pumpAndSettle();

          expect(find.text('Invite Screen'), findsOneWidget);
        });
      });

      group('when not pending', () {
        testWidgets('navigates to chat when not pending', (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
              ],
              child: ScreenUtilInit(
                designSize: testDesignSize,
                builder: (_, _) => MaterialApp.router(
                  routerConfig: buildRouter('/not-pending'),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ChatListTile));
          await tester.pumpAndSettle();

          expect(find.text('Chat Screen'), findsOneWidget);
        });
      });
    });

    group('context menu', () {
      testWidgets('long press on accepted chat shows context menu', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsOneWidget);
      });

      testWidgets('context menu shows Pin, Mute, Archive, Delete actions', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.text('Pin'), findsOneWidget);
        expect(find.text('Mute'), findsOneWidget);
        expect(find.text('Archive'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('pending chat has no onLongPress handler', (tester) async {
        await pumpTile(tester, _chatSummary(pendingConfirmation: true));

        final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
        expect(item.onLongPress, isNull);
      });

      testWidgets('context menu contains a preview of the chat item', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Preview Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_card')), findsOneWidget);
        final contextMenuFinder = find.byType(WnChatListContextMenu);
        final contextMenu = tester.widget<WnChatListContextMenu>(contextMenuFinder);
        expect(contextMenu.child, isA<WnChatListItem>());
      });

      testWidgets('context menu is dismissed when tapping outside', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsOneWidget);

        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsNothing);
      });

      testWidgets('shows Pin label and icon for unpinned chat', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.text('Pin'), findsOneWidget);
        expect(find.byKey(const Key('context_menu_action_pin')), findsOneWidget);
      });

      testWidgets('shows Unpin label and icon for pinned chat', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Pinned Chat', pinOrder: 0));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.text('Unpin'), findsOneWidget);
        expect(find.byKey(const Key('context_menu_action_unpin')), findsOneWidget);
      });

      testWidgets('tapping Pin calls setChatPinOrder with pinOrder 0', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_pin')));
        await tester.pumpAndSettle();

        expect(_api.setChatPinOrderCallCount, 1);
        expect(_api.lastPinOrder, 0);
      });

      testWidgets('tapping Unpin calls setChatPinOrder with null', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Pinned Chat', pinOrder: 0));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_unpin')));
        await tester.pumpAndSettle();

        expect(_api.setChatPinOrderCallCount, 1);
        expect(_api.lastPinOrder, isNull);
      });

      testWidgets('pinned chat preview in context menu shows pin badge', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Pinned Chat', pinOrder: 0));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        final contextMenu = tester.widget<WnChatListContextMenu>(
          find.byType(WnChatListContextMenu),
        );
        final previewItem = contextMenu.child as WnChatListItem;
        expect(previewItem.showPinned, isTrue);
      });

      testWidgets('calls onError when setChatPinOrder fails', (tester) async {
        _api.shouldThrowOnPin = true;
        String? errorMessage;

        await pumpTile(
          tester,
          _chatSummary(name: 'Test Chat'),
          onError: (msg) => errorMessage = msg,
        );

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_pin')));
        await tester.pumpAndSettle();

        expect(errorMessage, isNotNull);
        expect(_api.setChatPinOrderCallCount, 0);
      });

      testWidgets('does not call onChatListChanged when pin fails', (tester) async {
        _api.shouldThrowOnPin = true;
        var refreshCalled = false;

        await mountWidget(
          ChatListTile(
            chatSummary: _chatSummary(name: 'Test Chat'),
            onChatListChanged: () => refreshCalled = true,
            onError: (_) {},
          ),
          tester,
          overrides: [
            accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
          ],
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_pin')));
        await tester.pumpAndSettle();

        expect(refreshCalled, isFalse);
      });

      testWidgets('tapping Mute dismisses menu without error', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_mute')));
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsNothing);
      });

      testWidgets('tapping Archive dismisses menu without error', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_archive')));
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsNothing);
      });

      testWidgets('tapping Delete dismisses menu without error', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_delete')));
        await tester.pumpAndSettle();

        expect(find.byType(WnChatListContextMenu), findsNothing);
      });
    });
  });
}
