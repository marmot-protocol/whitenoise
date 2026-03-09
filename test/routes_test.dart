import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_invite_screen.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/screens/developer_settings_screen.dart';
import 'package:whitenoise/screens/donate_screen.dart';
import 'package:whitenoise/screens/home_screen.dart';
import 'package:whitenoise/screens/login_screen.dart';
import 'package:whitenoise/screens/settings_screen.dart';
import 'package:whitenoise/screens/signup_screen.dart';
import 'package:whitenoise/screens/start_support_chat_screen.dart';
import 'package:whitenoise/screens/user_search_screen.dart';
import 'package:whitenoise/screens/user_selection_screen.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'mocks/mock_wn_api.dart';

import 'test_helpers.dart';

class _MockRustLibApi extends MockWnApi {
  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    return const FlutterMetadata(
      name: 'Test User',
      displayName: 'Test Display Name',
      about: 'Test bio',
      custom: {},
    );
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    return Group(
      mlsGroupId: groupId,
      nostrGroupId: '',
      name: 'Test Group',
      description: '',
      adminPubkeys: const [],
      epoch: BigInt.zero,
      state: GroupState.active,
    );
  }
}

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => testPubkeyA;
}

void main() {
  setUpAll(() {
    RustLib.initMock(api: _MockRustLibApi());
  });
  late GoRouter router;

  Future<void> pumpRouter(
    WidgetTester tester, {
    List overrides = const [],
  }) async {
    setUpTestView(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides],
        child: ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              router = Routes.build(ref);
              return MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          ),
        ),
      ),
    );
  }

  BuildContext getContext(WidgetTester tester) => tester.element(find.byType(Scaffold).first);

  group('build', () {
    group('when user is authenticated', () {
      testWidgets('navigates to ChatListScreen', (tester) async {
        await pumpRouter(
          tester,
          overrides: [
            authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
          ],
        );
        Routes.pushToLogin(getContext(tester));
        await tester.pumpAndSettle();
        Routes.pushToHome(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(ChatListScreen), findsOneWidget);
      });
    });

    group('when user is not authenticated', () {
      testWidgets('navigates to HomeScreen', (tester) async {
        await pumpRouter(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('redirects to LoginScreen when accessing /chats', (tester) async {
        await pumpRouter(tester);
        Routes.goToChatList(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('redirects to LoginScreen when accessing /settings', (tester) async {
        await pumpRouter(tester);
        Routes.pushToSettings(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('redirects to LoginScreen when accessing /donate', (tester) async {
        await pumpRouter(tester);
        Routes.pushToDonate(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('redirects to LoginScreen when accessing /start-support-chat', (tester) async {
        await pumpRouter(tester);
        Routes.pushToStartSupportChat(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('redirects to LoginScreen when accessing /user-search', (tester) async {
        await pumpRouter(tester);
        Routes.pushToUserSearch(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });
  });

  group('goBack', () {
    testWidgets('navigates to previous route', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    group('when navigation stack is empty', () {
      testWidgets('navigates to HomeScreen', (tester) async {
        await pumpRouter(tester);
        Routes.goToChatList(getContext(tester));
        await tester.pumpAndSettle();
        Routes.goBack(getContext(tester));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });
  });

  group('goToHome', () {
    testWidgets('navigates to HomeScreen', (tester) async {
      await pumpRouter(tester);
      Routes.goToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goToHome(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('resets navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToChatList(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goToHome(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('pushToHome', () {
    testWidgets('navigates to HomeScreen', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToHome(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToHome(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });

  group('goToLogin', () {
    testWidgets('navigates to LoginScreen', (tester) async {
      await pumpRouter(tester);
      Routes.goToLogin(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('resets navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('pushToLogin', () {
    testWidgets('pushes LoginScreen onto stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });

  group('goToSignup', () {
    testWidgets('navigates to SignupScreen', (tester) async {
      await pumpRouter(tester);
      Routes.goToSignup(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('resets navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.goToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('pushToSignup', () {
    testWidgets('pushes SignupScreen onto stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(tester);
      Routes.pushToLogin(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToSignup(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('goToChatList', () {
    testWidgets('navigates to ChatListScreen', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.goToChatList(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToChatList', () {
    testWidgets('pushes ChatListScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToChatList(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToSettings', () {
    testWidgets('pushes SettingsScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToSettings(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToSettings(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToDonate', () {
    testWidgets('pushes DonateScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToDonate(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(DonateScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToDonate(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToStartSupportChat', () {
    testWidgets('pushes StartSupportChatScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToStartSupportChat(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(StartSupportChatScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToUserSearch(getContext(tester));
      await tester.pumpAndSettle();
      Routes.pushToStartSupportChat(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(StartSupportChatScreen), findsOneWidget);
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(StartSupportChatScreen), findsNothing);
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToDeveloperSettings', () {
    testWidgets('navigates to Developer Settings', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToDeveloperSettings(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperSettingsScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToDeveloperSettings(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToUserSearch', () {
    testWidgets('pushes UserSearchScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToUserSearch(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(UserSearchScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToUserSearch(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToInvite', () {
    testWidgets('pushes ChatInviteScreen onto stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToInvite(getContext(tester), testGroupId);
      await tester.pumpAndSettle();
      expect(find.byType(ChatInviteScreen), findsOneWidget);
    });

    testWidgets('does not reset navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToInvite(getContext(tester), testGroupId);
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });

  group('pushToSetUpGroup', () {
    testWidgets('shows UserSelectionScreen when selectedUsers is empty', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToSetUpGroup(getContext(tester), const <User>[]);
      await tester.pumpAndSettle();
      expect(find.byType(UserSelectionScreen), findsOneWidget);
    });
  });

  group('goToChat', () {
    testWidgets('navigates to ChatScreen', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.goToChat(getContext(tester), testGroupId);
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('resets navigation stack', (tester) async {
      await pumpRouter(
        tester,
        overrides: [
          authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
        ],
      );
      Routes.pushToSettings(getContext(tester));
      await tester.pumpAndSettle();
      Routes.goToChat(getContext(tester), testGroupId);
      await tester.pumpAndSettle();
      Routes.goBack(getContext(tester));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });
}
