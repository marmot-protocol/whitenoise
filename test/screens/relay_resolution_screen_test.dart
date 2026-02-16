import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' show GoRoute, GoRouter;
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/screens/relay_resolution_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart'
    show LoginResult, LoginStatus, Account, AccountType;
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_overlay.dart' show WnOverlay;
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
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
}

class _MockAuthNotifier extends AuthNotifier {
  LoginResult? publishDefaultRelaysResult;
  LoginResult? customRelayResult;
  Exception? publishDefaultRelaysError;
  Exception? customRelayError;
  bool loginCancelCalled = false;
  String? lastCancelPubkey;

  @override
  Future<String?> build() async => null;

  @override
  Future<LoginResult> loginPublishDefaultRelays(String pubkey) async {
    if (publishDefaultRelaysError != null) throw publishDefaultRelaysError!;
    return publishDefaultRelaysResult ??
        LoginResult(
          account: Account(
            pubkey: pubkey,
            accountType: AccountType.local,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: LoginStatus.complete,
        );
  }

  @override
  Future<LoginResult> loginWithCustomRelay(String pubkey, String relayUrl) async {
    if (customRelayError != null) throw customRelayError!;
    return customRelayResult ??
        LoginResult(
          account: Account(
            pubkey: pubkey,
            accountType: AccountType.local,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: LoginStatus.complete,
        );
  }

  @override
  Future<void> loginCancel(String pubkey) async {
    loginCancelCalled = true;
    lastCancelPubkey = pubkey;
  }

  @override
  Future<LoginResult> loginExternalSignerPublishDefaultRelays(String pubkey) async {
    if (publishDefaultRelaysError != null) throw publishDefaultRelaysError!;
    return publishDefaultRelaysResult ??
        LoginResult(
          account: Account(
            pubkey: pubkey,
            accountType: AccountType.external_,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: LoginStatus.complete,
        );
  }

  @override
  Future<LoginResult> loginExternalSignerWithCustomRelay(String pubkey, String relayUrl) async {
    if (customRelayError != null) throw customRelayError!;
    return customRelayResult ??
        LoginResult(
          account: Account(
            pubkey: pubkey,
            accountType: AccountType.external_,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: LoginStatus.complete,
        );
  }
}

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  setUpAll(() {
    RustLib.initMock(api: _MockApi());
  });

  late _MockAuthNotifier mockAuth;

  Future<void> pumpRelayResolutionScreen(
    WidgetTester tester, {
    bool isExternalSigner = false,
    bool useRouter = false,
    MediaQueryData? mediaQueryData,
  }) async {
    mockAuth = _MockAuthNotifier();
    setUpTestView(tester);

    if (useRouter) {
      final router = GoRouter(
        initialLocation: '/relay-resolution',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
          GoRoute(
            path: '/relay-resolution',
            builder: (context, state) => RelayResolutionScreen(
              pubkey: testPubkeyA,
              isExternalSigner: isExternalSigner,
            ),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const Scaffold(
              body: Text('Chat List'),
            ),
          ),
        ],
      );

      Widget app = MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );

      if (mediaQueryData != null) {
        app = MediaQuery(data: mediaQueryData, child: app);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => mockAuth)],
          child: ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => app,
          ),
        ),
      );
    } else {
      final Widget home = RelayResolutionScreen(
        pubkey: testPubkeyA,
        isExternalSigner: isExternalSigner,
      );

      Widget app = MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

      if (mediaQueryData != null) {
        app = MediaQuery(data: mediaQueryData, child: app);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => mockAuth)],
          child: ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => app,
          ),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  group('RelayResolutionScreen', () {
    group('rendering', () {
      testWidgets('renders title', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.text('Relay Setup'), findsOneWidget);
      });

      testWidgets('renders description', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(
          find.text(
            "We couldn't find your relay lists on the network. You can provide a relay where your lists are published, or use our default relays to get started.",
          ),
          findsOneWidget,
        );
      });

      testWidgets('renders relay URL input', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.byKey(const Key('relay_url_input')), findsOneWidget);
      });

      testWidgets('renders search relay button', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.byKey(const Key('try_custom_relay_button')), findsOneWidget);
      });

      testWidgets('renders use default relays button', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.byKey(const Key('use_default_relays_button')), findsOneWidget);
      });
    });

    group('button states', () {
      testWidgets('search relay button is disabled when relay URL is empty', (tester) async {
        await pumpRelayResolutionScreen(tester);
        final button = tester.widget<WnButton>(find.byKey(const Key('try_custom_relay_button')));
        expect(button.disabled, isTrue);
      });

      testWidgets('search relay button is enabled when relay URL is entered', (tester) async {
        await pumpRelayResolutionScreen(tester);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();
        final button = tester.widget<WnButton>(find.byKey(const Key('try_custom_relay_button')));
        expect(button.disabled, isFalse);
      });

      testWidgets('use default relays button is always enabled', (tester) async {
        await pumpRelayResolutionScreen(tester);
        final button = tester.widget<WnButton>(
          find.byKey(const Key('use_default_relays_button')),
        );
        expect(button.disabled, isFalse);
      });
    });

    group('back button', () {
      testWidgets('calls loginCancel when back button is tapped', (tester) async {
        await pumpRelayResolutionScreen(tester, useRouter: true);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(mockAuth.loginCancelCalled, isTrue);
        expect(mockAuth.lastCancelPubkey, testPubkeyA);
      });
    });

    group('error handling', () {
      testWidgets('shows error notice when custom relay search fails', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.customRelayResult = LoginResult(
          account: Account(
            pubkey: testPubkeyA,
            accountType: AccountType.local,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: LoginStatus.needsRelayLists,
        );
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(
          find.text('No relay lists found on this relay. Try another or use defaults.'),
          findsOneWidget,
        );
      });

      testWidgets('shows generic error when publish defaults fails', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.publishDefaultRelaysError = Exception('Network error');
        await tester.tap(find.byKey(const Key('use_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(
          find.text('An error occurred during login. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows generic error for unknown error key', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.customRelayError = Exception('Unknown error');
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(
          find.text('An error occurred during login. Please try again.'),
          findsOneWidget,
        );
      });
    });

    group('successful navigation', () {
      testWidgets('navigates to chat list when use default relays succeeds', (tester) async {
        await pumpRelayResolutionScreen(tester, useRouter: true);
        await tester.tap(find.byKey(const Key('use_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.text('Chat List'), findsOneWidget);
      });

      testWidgets('navigates to chat list when try custom relay succeeds', (tester) async {
        await pumpRelayResolutionScreen(tester, useRouter: true);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.text('Chat List'), findsOneWidget);
      });
    });

    group('external signer', () {
      testWidgets('uses external signer callbacks for publish defaults', (tester) async {
        await pumpRelayResolutionScreen(tester, isExternalSigner: true, useRouter: true);
        await tester.tap(find.byKey(const Key('use_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.text('Chat List'), findsOneWidget);
      });

      testWidgets('uses external signer callbacks for custom relay', (tester) async {
        await pumpRelayResolutionScreen(tester, isExternalSigner: true, useRouter: true);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.text('Chat List'), findsOneWidget);
      });
    });

    group('keyboard overlay', () {
      testWidgets('shows WnOverlay when keyboard is open', (tester) async {
        await pumpRelayResolutionScreen(
          tester,
          mediaQueryData: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        );
        expect(find.byType(WnOverlay), findsOneWidget);
      });

      testWidgets('does not show WnOverlay when keyboard is closed', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.byType(WnOverlay), findsNothing);
      });
    });
  });
}
