import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show PlatformInt64;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/chat_summary.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType, RequiredProposal;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_list_menu.dart';
import 'package:whitenoise/widgets/chat_list_tile.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatSummary _chatSummary({
  String? name,
  GroupType groupType = GroupType.group,
  bool pendingConfirmation = false,
  bool selfRemoved = false,
  String? lastMessageContent,
  String? lastMessageAuthor,
  String? lastMessageAuthorDisplayName,
  String? groupImagePath,
  String? groupImageUrl,
  String? welcomerPubkey,
  String? dmPeerPubkey,
  int? pinOrder,
  int lastMessageMediaAttachmentCount = 0,
}) => ChatSummary(
  mlsGroupId: testGroupId,
  name: name,
  groupType: groupType,
  createdAt: DateTime(2024),
  pendingConfirmation: pendingConfirmation,
  selfRemoved: selfRemoved,
  unreadCount: BigInt.zero,
  groupImagePath: groupImagePath,
  groupImageUrl: groupImageUrl,
  welcomerPubkey: welcomerPubkey,
  dmPeerPubkey: dmPeerPubkey,
  pinOrder: pinOrder,
  lastMessage: (lastMessageContent != null || lastMessageMediaAttachmentCount > 0)
      ? ChatMessageSummary(
          mlsGroupId: testGroupId,
          author:
              lastMessageAuthor ??
              '0000000000000000000000000000000000000000000000000000000000000000',
          authorDisplayName: lastMessageAuthorDisplayName,
          content: lastMessageContent ?? '',
          createdAt: DateTime(2024),
          mediaAttachmentCount: BigInt.from(lastMessageMediaAttachmentCount),
        )
      : null,
);

class _MockApi extends MockWnApi {
  FlutterMetadata welcomerMetadata = const FlutterMetadata(custom: {});
  bool shouldThrow = false;
  bool shouldThrowOnPin = false;
  int setChatPinOrderCallCount = 0;
  PlatformInt64? lastPinOrder;

  List<RequiredProposal> mockRequiredProposals = [RequiredProposal.selfRemove];
  List<String> mockAdminPubkeys = [];

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

  bool shouldThrowOnProposals = false;

  @override
  Future<List<RequiredProposal>> crateApiGroupsGroupRequiredProposals({
    required String accountPubkey,
    required String groupId,
  }) async {
    if (shouldThrowOnProposals) throw Exception('Failed to fetch proposals');
    return mockRequiredProposals;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async => mockAdminPubkeys;

  @override
  Future<void> crateApiGroupsSelfDemote({
    required String pubkey,
    required String groupId,
  }) async {}
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
    _api.mockRequiredProposals = [RequiredProposal.selfRemove];
    _api.mockAdminPubkeys = [];
    _api.shouldThrowOnProposals = false;
    _api.reset();
  });

  Future<void> pumpTile(
    WidgetTester tester,
    ChatSummary chatSummary, {
    bool settle = true,
    void Function(String)? onError,
    bool isArchived = false,
    List extraOverrides = const [],
  }) async {
    await mountWidget(
      ChatListTile(chatSummary: chatSummary, onError: onError, isArchived: isArchived),
      tester,
      overrides: [
        accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
        ...extraOverrides,
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

          testWidgets('shows media subtitle and icon for media-only message', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                groupType: GroupType.directMessage,
                pendingConfirmation: true,
                lastMessageMediaAttachmentCount: 1,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Media item');
            expect(item.subtitleIcon, isNotNull);
            expect(find.byKey(const Key('media_subtitle_icon')), findsOneWidget);
          });

          testWidgets('shows media subtitle for multiple media-only message', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                groupType: GroupType.directMessage,
                pendingConfirmation: true,
                lastMessageMediaAttachmentCount: 3,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Media items');
            expect(item.subtitleIcon, isNotNull);
          });

          testWidgets('shows text content when media message also has text', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                groupType: GroupType.directMessage,
                pendingConfirmation: true,
                lastMessageContent: 'Check this out',
                lastMessageMediaAttachmentCount: 2,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Check this out');
            expect(item.subtitleIcon, isNull);
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

          testWidgets('shows media subtitle and icon for media-only message', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageMediaAttachmentCount: 1,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Media item');
            expect(item.subtitleIcon, isNotNull);
            expect(find.byKey(const Key('media_subtitle_icon')), findsOneWidget);
          });

          testWidgets('shows media subtitle for multiple media-only message', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageMediaAttachmentCount: 3,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Media items');
            expect(item.subtitleIcon, isNotNull);
          });

          testWidgets('shows text content when media message also has text', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageContent: 'Look at this',
                lastMessageMediaAttachmentCount: 2,
              ),
            );
            final finder = find.byType(WnChatListItem);
            final item = tester.widget<WnChatListItem>(finder);
            expect(item.subtitle, 'Look at this');
            expect(item.subtitleIcon, isNull);
          });

          testWidgets('shows "You: " prefix for own message in pending group', (tester) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageContent: 'My message',
                lastMessageAuthor: testPubkeyA,
              ),
            );
            final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
            expect(item.prefixSubtitle, 'You: ');
            expect(item.subtitle, 'My message');
          });

          testWidgets("shows author name prefix for other's message in pending group", (
            tester,
          ) async {
            await pumpTile(
              tester,
              _chatSummary(
                pendingConfirmation: true,
                lastMessageContent: 'Hello group',
                lastMessageAuthor: testPubkeyB,
                lastMessageAuthorDisplayName: 'Alice',
              ),
            );
            final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
            expect(item.prefixSubtitle, 'Alice: ');
            expect(item.subtitle, 'Hello group');
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

      testWidgets('shows "Media item" and media icon when single media-only message', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(lastMessageMediaAttachmentCount: 1),
        );
        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.subtitle, 'Media item');
        expect(item.subtitleIcon, isNotNull);
        expect(find.byKey(const Key('media_subtitle_icon')), findsOneWidget);
      });

      testWidgets('shows "Media items" and media icon when multiple media-only message', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(lastMessageMediaAttachmentCount: 3),
        );
        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.subtitle, 'Media items');
        expect(item.subtitleIcon, isNotNull);
        expect(find.byKey(const Key('media_subtitle_icon')), findsOneWidget);
      });

      testWidgets('shows message content when media message also has text', (
        tester,
      ) async {
        await pumpTile(
          tester,
          _chatSummary(
            lastMessageContent: 'Check this out',
            lastMessageMediaAttachmentCount: 2,
          ),
        );
        final finder = find.byType(WnChatListItem);
        final item = tester.widget<WnChatListItem>(finder);
        expect(item.subtitle, 'Check this out');
        expect(item.subtitleIcon, isNull);
      });

      group('selfRemoved', () {
        testWidgets('shows "You left the group" when selfRemoved is true', (tester) async {
          await pumpTile(tester, _chatSummary(selfRemoved: true));
          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.subtitle, 'You left the group');
        });

        testWidgets('suppresses author prefix when selfRemoved is true', (tester) async {
          await pumpTile(
            tester,
            _chatSummary(
              selfRemoved: true,
              lastMessageContent: 'Last message before leaving',
              lastMessageAuthor: testPubkeyA,
            ),
          );
          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.prefixSubtitle, isNull);
        });

        testWidgets('overrides last message content when selfRemoved is true', (tester) async {
          await pumpTile(
            tester,
            _chatSummary(
              selfRemoved: true,
              lastMessageContent: 'Last message before leaving',
            ),
          );
          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.subtitle, 'You left the group');
          expect(item.subtitle, isNot(contains('Last message before leaving')));
        });

        testWidgets('shows last message normally when selfRemoved is false', (tester) async {
          await pumpTile(
            tester,
            _chatSummary(lastMessageContent: 'Regular message'),
          );
          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.subtitle, 'Regular message');
        });
      });

      group('searchSnippet', () {
        testWidgets('overrides subtitle with the snippet text', (tester) async {
          await mountWidget(
            ChatListTile(
              chatSummary: _chatSummary(
                name: 'Dev Team',
                lastMessageContent: 'Hello world',
                lastMessageAuthor: testPubkeyA,
              ),
              searchSnippet: '...matched text...',
            ),
            tester,
            overrides: [
              accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
            ],
          );
          await tester.pumpAndSettle();

          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.subtitle, '...matched text...');
        });

        testWidgets('clears prefixSubtitle when snippet is provided', (tester) async {
          await mountWidget(
            ChatListTile(
              chatSummary: _chatSummary(
                name: 'Dev Team',
                lastMessageContent: 'Hello world',
                lastMessageAuthor: testPubkeyA,
              ),
              searchSnippet: '...matched text...',
            ),
            tester,
            overrides: [
              accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
            ],
          );
          await tester.pumpAndSettle();

          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.prefixSubtitle, isNull);
        });

        testWidgets('clears subtitleIcon when snippet is provided', (tester) async {
          await mountWidget(
            ChatListTile(
              chatSummary: _chatSummary(lastMessageMediaAttachmentCount: 2),
              searchSnippet: '...matched text...',
            ),
            tester,
            overrides: [
              accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
            ],
          );
          await tester.pumpAndSettle();

          final item = tester.widget<WnChatListItem>(find.byType(WnChatListItem));
          expect(item.subtitleIcon, isNull);
          expect(find.byKey(const Key('media_subtitle_icon')), findsNothing);
        });
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

        expect(find.byType(ChatListMenu), findsOneWidget);
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
        expect(
          find.descendant(
            of: find.byKey(const Key('context_menu_card')),
            matching: find.text('Preview Chat'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('context menu is dismissed when tapping outside', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byType(ChatListMenu), findsOneWidget);

        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        expect(find.byType(ChatListMenu), findsNothing);
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

        expect(
          find.descendant(
            of: find.byKey(const Key('context_menu_card')),
            matching: find.byKey(const Key('avatar_pin_badge')),
          ),
          findsOneWidget,
        );
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
    });

    group('archive context menu', () {
      testWidgets('archive action calls onChatListChanged on success', (tester) async {
        var refreshCalled = false;

        await mountWidget(
          ChatListTile(
            chatSummary: _chatSummary(name: 'Test Chat'),
            onChatListChanged: () => refreshCalled = true,
          ),
          tester,
          overrides: [
            accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
          ],
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_archive')));
        await tester.pumpAndSettle();

        expect(refreshCalled, isTrue);
      });

      testWidgets('unarchive action calls onChatListChanged on success', (tester) async {
        var refreshCalled = false;

        await mountWidget(
          ChatListTile(
            chatSummary: _chatSummary(name: 'Test Chat'),
            isArchived: true,
            onChatListChanged: () => refreshCalled = true,
          ),
          tester,
          overrides: [
            accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
          ],
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_unarchive')));
        await tester.pumpAndSettle();

        expect(refreshCalled, isTrue);
      });

      testWidgets('context menu shows archive action for non-archived chat', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_archive')), findsOneWidget);
        expect(find.text('Archive'), findsOneWidget);
      });

      testWidgets('context menu shows unarchive action for archived chat', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'), isArchived: true);

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_unarchive')), findsOneWidget);
        expect(find.text('Unarchive'), findsOneWidget);
      });

      testWidgets('archive action calls archiveChat with correct args', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_archive')));
        await tester.pumpAndSettle();

        expect(_api.archiveChatCallCount, 1);
        expect(_api.lastArchivedGroupId, testGroupId);
      });

      testWidgets('archive action does not call unarchiveChat', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_archive')));
        await tester.pumpAndSettle();

        expect(_api.unarchiveChatCallCount, 0);
      });

      testWidgets('unarchive action calls unarchiveChat with correct args', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Test Chat'), isArchived: true);

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_unarchive')));
        await tester.pumpAndSettle();

        expect(_api.unarchiveChatCallCount, 1);
        expect(_api.lastUnarchivedGroupId, testGroupId);
      });

      testWidgets('archive action shows error notice on failure', (tester) async {
        _api.shouldFailArchiveChat = true;
        String? errorMessage;

        await pumpTile(
          tester,
          _chatSummary(name: 'Test Chat'),
          onError: (msg) => errorMessage = msg,
        );

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_archive')));
        await tester.pumpAndSettle();

        expect(errorMessage, isNotNull);
        expect(errorMessage, contains('archive'));
      });

      testWidgets('unarchive action shows error notice on failure', (tester) async {
        _api.shouldFailUnarchiveChat = true;
        String? errorMessage;

        await pumpTile(
          tester,
          _chatSummary(name: 'Test Chat'),
          isArchived: true,
          onError: (msg) => errorMessage = msg,
        );

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_unarchive')));
        await tester.pumpAndSettle();

        expect(errorMessage, isNotNull);
        expect(errorMessage, contains('unarchive'));
      });
    });

    group('leave group context menu', () {
      testWidgets('does not show Leave group for DMs', (tester) async {
        await pumpTile(tester, _chatSummary(name: 'Alice', groupType: GroupType.directMessage));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_leave_group')), findsNothing);
      });

      testWidgets(
        'tapping Leave group transitions overlay to confirmation',
        (tester) async {
          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('context_menu_action_confirm_leave_group')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('context_menu_action_cancel_leave')), findsOneWidget);
        },
      );

      testWidgets(
        'confirmation shows leave warning text',
        (tester) async {
          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Are you sure you want to leave this group? The chat will stay in your list '
              "if you don't delete it, but you won't be able to send or receive new messages "
              'unless someone re-invites you.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'confirmation title is "Leave group"',
        (tester) async {
          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_navigation_header')), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(WnSlateNavigationHeader),
              matching: find.text('Leave group'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Cancel on confirmation returns to initial menu',
        (tester) async {
          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_cancel_leave')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'back arrow on confirmation returns to initial menu',
        (tester) async {
          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
          await tester.tap(find.byKey(const Key('slate_back_button')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'confirming Leave calls leaveGroup with correct args',
        (tester) async {
          await pumpTile(
            tester,
            _chatSummary(name: 'My Group'),
          );

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_confirm_leave_group')));
          await tester.pumpAndSettle();

          expect(_api.leaveGroupCallCount, 1);
          expect(_api.lastLeaveGroupId, testGroupId);
          expect(_api.lastLeaveGroupPubkey, testPubkeyA);
        },
      );

      testWidgets(
        'confirming Leave calls onChatListChanged',
        (tester) async {
          var refreshCalled = false;

          await mountWidget(
            ChatListTile(
              chatSummary: _chatSummary(name: 'My Group'),
              onChatListChanged: () => refreshCalled = true,
            ),
            tester,
            overrides: [
              accountPubkeyProvider.overrideWith(MockAccountPubkeyNotifier.new),
            ],
          );
          await tester.pumpAndSettle();

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_confirm_leave_group')));
          await tester.pumpAndSettle();

          expect(refreshCalled, isTrue);
        },
      );

      testWidgets('does not show Leave group when selfRemoved is true', (tester) async {
        await pumpTile(
          tester,
          _chatSummary(name: 'My Group', selfRemoved: true),
        );

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_leave_group')), findsNothing);
      });

      testWidgets('leaveGroup failure calls onError', (tester) async {
        _api.shouldFailLeaveGroup = true;
        String? errorMessage;

        await pumpTile(
          tester,
          _chatSummary(name: 'My Group'),
          onError: (msg) => errorMessage = msg,
        );

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('context_menu_action_confirm_leave_group')));
        await tester.pumpAndSettle();

        expect(errorMessage, isNotNull);
        expect(errorMessage, contains('leave'));
      });

      testWidgets('shows Leave group item (disabled) when user is last admin', (tester) async {
        _api.mockRequiredProposals = [RequiredProposal.selfRemove];
        _api.mockAdminPubkeys = [testPubkeyA];

        await pumpTile(tester, _chatSummary(name: 'My Group'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
      });

      testWidgets(
        'tapping last admin leave item shows warning step',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('context_menu_action_confirm_leave_group')),
            findsNothing,
          );
          expect(find.byKey(const Key('context_menu_action_close_leave_warning')), findsOneWidget);
          expect(
            find.byKey(const Key('context_menu_action_leave_group_warning')),
            findsOneWidget,
          );
        },
      );

      testWidgets('shows Leave group item (disabled) when no capabilities', (tester) async {
        _api.mockRequiredProposals = [];

        await pumpTile(tester, _chatSummary(name: 'My Group'));

        await tester.longPress(find.byType(WnChatListItem));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
      });

      testWidgets(
        'tapping noCapabilities leave item shows warning step, not confirmation',
        (tester) async {
          _api.mockRequiredProposals = [];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('context_menu_action_confirm_leave_group')),
            findsNothing,
          );
          expect(find.byKey(const Key('context_menu_action_close_leave_warning')), findsOneWidget);
          expect(
            find.byKey(const Key('context_menu_action_leave_group_warning')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'tapping last admin leave item shows warning text in step 2',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          expect(
            find.text(
              "You're the only admin in this group. Promote at least one member to admin before you can leave.",
            ),
            findsNothing,
          );

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.text(
              "You're the only admin in this group. Promote at least one member to admin before you can leave.",
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'tapping noCapabilities leave item shows warning text in step 2',
        (tester) async {
          _api.mockRequiredProposals = [];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          expect(
            find.text(
              "This group was created with an older version and doesn't support leaving. "
              'Admins may upgrade the group capabilities once all members are on a version that supports leaving.',
            ),
            findsNothing,
          );

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(
            find.text(
              "This group was created with an older version and doesn't support leaving. "
              'Admins may upgrade the group capabilities once all members are on a version that supports leaving.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'tapping leave item when proposals fetch fails shows error notice in step 2',
        (tester) async {
          _api.shouldThrowOnProposals = true;

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(find.byType(WnSystemNotice), findsOneWidget);
          expect(
            find.text(
              "Something went wrong loading group info. You won't be able to leave right now.",
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'warning step for last admin shows navigation header with Leave group title',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_navigation_header')), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(WnSlateNavigationHeader),
              matching: find.text('Leave group'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'close button on last admin warning step returns to initial menu',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_close_leave_warning')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'back arrow on last admin warning step returns to initial menu',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('slate_back_button')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'back arrow on fetchError warning step returns to initial menu',
        (tester) async {
          _api.shouldThrowOnProposals = true;

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('slate_back_button')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'back arrow on noCapabilities warning step returns to initial menu',
        (tester) async {
          _api.mockRequiredProposals = [];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('slate_back_button')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'close button on noCapabilities warning step returns to initial menu',
        (tester) async {
          _api.mockRequiredProposals = [];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_close_leave_warning')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'close button on fetchError warning step returns to initial menu',
        (tester) async {
          _api.shouldThrowOnProposals = true;

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('context_menu_action_close_leave_warning')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('context_menu_action_leave_group')), findsOneWidget);
          expect(find.byKey(const Key('context_menu_navigation_header')), findsNothing);
        },
      );

      testWidgets(
        'warning step for last admin does not call leaveGroup',
        (tester) async {
          _api.mockRequiredProposals = [RequiredProposal.selfRemove];
          _api.mockAdminPubkeys = [testPubkeyA];

          await pumpTile(tester, _chatSummary(name: 'My Group'));

          await tester.longPress(find.byType(WnChatListItem));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('context_menu_action_leave_group')));
          await tester.pumpAndSettle();

          expect(_api.leaveGroupCallCount, 0);
        },
      );
    });
  });
}
