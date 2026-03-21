import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;

class _MockApi extends MockWnApi {
  FlutterMetadata metadata = const FlutterMetadata(
    displayName: 'White Noise Support',
    custom: {},
  );
  Completer<Group>? createGroupCompleter;
  Exception? createGroupError;

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
    if (createGroupCompleter != null) return createGroupCompleter!.future;
    if (createGroupError != null) throw createGroupError!;
    return Group(
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
  void reset() {
    super.reset();
    metadata = const FlutterMetadata(displayName: 'White Noise Support', custom: {});
    createGroupCompleter = null;
    createGroupError = null;
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

  Future<void> pumpStartSupportChatScreen(WidgetTester tester) async {
    setUpTestView(tester);
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToStartSupportChat(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('StartSupportChatScreen', () {
    testWidgets('displays slate container', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.byType(WnSlate), findsAtLeastNWidgets(1));
    });

    testWidgets('displays title', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.text('Chat with support'), findsOneWidget);
    });

    testWidgets('displays avatar', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.byType(WnAvatar), findsOneWidget);
    });

    testWidgets('displays send message button', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.byKey(const Key('start_support_chat_button')), findsOneWidget);
    });

    testWidgets('does not display follow button', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.byKey(const Key('follow_button')), findsNothing);
    });

    testWidgets('does not display add to group button', (tester) async {
      await pumpStartSupportChatScreen(tester);
      expect(find.byKey(const Key('add_to_group_button')), findsNothing);
    });

    testWidgets('tapping send message creates DM and navigates to chat', (tester) async {
      await pumpStartSupportChatScreen(tester);

      await tester.tap(find.byKey(const Key('start_support_chat_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('shows error notice on failure', (tester) async {
      _api.createGroupError = Exception('Network error');

      await pumpStartSupportChatScreen(tester);

      await tester.tap(find.byKey(const Key('start_support_chat_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to start chat with support'), findsOneWidget);
    });

    testWidgets('shows loading indicator while sending', (tester) async {
      _api.createGroupCompleter = Completer();

      await pumpStartSupportChatScreen(tester);

      await tester.tap(find.byKey(const Key('start_support_chat_button')));
      await tester.pump();

      final button = tester.widget<WnButton>(find.byKey(const Key('start_support_chat_button')));
      expect(button.loading, isTrue);

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
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('tapping background dismisses screen', (tester) async {
      await pumpStartSupportChatScreen(tester);

      await tester.tap(find.byKey(const Key('start_support_chat_background')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('tapping header back button dismisses screen', (tester) async {
      await pumpStartSupportChatScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    group('public key copy', () {
      testWidgets('shows success notice when public key is copied', (tester) async {
        mockClipboard();
        addTearDown(clearClipboardMock);
        await pumpStartSupportChatScreen(tester);

        final profileCard = tester.widget<WnUserProfileCard>(find.byType(WnUserProfileCard));
        profileCard.onPublicKeyCopied?.call();
        await tester.pump();

        expect(find.text('Public key copied to clipboard'), findsOneWidget);
      });

      testWidgets('shows error notice when public key copy fails', (tester) async {
        mockClipboardFailing();
        addTearDown(clearClipboardMock);
        await pumpStartSupportChatScreen(tester);

        final profileCard = tester.widget<WnUserProfileCard>(find.byType(WnUserProfileCard));
        profileCard.onPublicKeyCopyError?.call();
        await tester.pumpAndSettle();

        expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
      });
    });
  });
}
