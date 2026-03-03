import 'dart:async';

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
import 'package:whitenoise/src/rust/api/error.dart';
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
  Object? publishDefaultRelaysError;
  Object? customRelayError;
  bool loginCancelCalled = false;
  String? lastCancelPubkey;
  Completer<LoginResult>? publishDefaultRelaysCompleter;
  Completer<LoginResult>? customRelayCompleter;
  bool loginPublishDefaultRelaysCalled = false;
  bool loginWithCustomRelayCalled = false;
  bool externalSignerPublishDefaultRelaysCalled = false;
  bool externalSignerWithCustomRelayCalled = false;

  @override
  Future<String?> build() async => null;

  @override
  Future<LoginResult> loginPublishDefaultRelays(String pubkey) async {
    loginPublishDefaultRelaysCalled = true;
    if (publishDefaultRelaysCompleter != null) return publishDefaultRelaysCompleter!.future;
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
    loginWithCustomRelayCalled = true;
    if (customRelayCompleter != null) return customRelayCompleter!.future;
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
    externalSignerPublishDefaultRelaysCalled = true;
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
    externalSignerWithCustomRelayCalled = true;
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
      testWidgets('search relay button is disabled initially with wss:// prefill', (
        tester,
      ) async {
        await pumpRelayResolutionScreen(tester);
        final button = tester.widget<WnButton>(find.byKey(const Key('try_custom_relay_button')));
        expect(button.disabled, isTrue);
      });

      testWidgets('search relay button is enabled when valid URL entered and debounce completes', (
        tester,
      ) async {
        await pumpRelayResolutionScreen(tester);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        final button = tester.widget<WnButton>(find.byKey(const Key('try_custom_relay_button')));
        expect(button.disabled, isFalse);
      });

      testWidgets('search relay button is disabled when URL has validation errors', (
        tester,
      ) async {
        await pumpRelayResolutionScreen(tester);
        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));
        final button = tester.widget<WnButton>(find.byKey(const Key('try_custom_relay_button')));
        expect(button.disabled, isTrue);
      });

      testWidgets('use default relays button is always enabled', (tester) async {
        await pumpRelayResolutionScreen(tester);
        final button = tester.widget<WnButton>(
          find.byKey(const Key('use_default_relays_button')),
        );
        expect(button.disabled, isFalse);
      });
    });

    group('independent button loading', () {
      testWidgets('only use default relays button shows loading when publishing defaults', (
        tester,
      ) async {
        await pumpRelayResolutionScreen(tester, useRouter: true);
        mockAuth.publishDefaultRelaysCompleter = Completer<LoginResult>();
        await tester.tap(find.byKey(const Key('use_default_relays_button')));
        await tester.pump();

        final defaultsButton = tester.widget<WnButton>(
          find.byKey(const Key('use_default_relays_button')),
        );
        expect(defaultsButton.loading, isTrue);

        final searchButton = tester.widget<WnButton>(
          find.byKey(const Key('try_custom_relay_button')),
        );
        expect(searchButton.loading, isFalse);

        expect(defaultsButton.disabled, isTrue);
        expect(searchButton.disabled, isTrue);

        mockAuth.publishDefaultRelaysCompleter!.complete(
          LoginResult(
            account: Account(
              pubkey: testPubkeyA,
              accountType: AccountType.local,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            status: LoginStatus.complete,
          ),
        );
        await tester.pumpAndSettle();
      });

      testWidgets('only search relay button shows loading when searching custom relay', (
        tester,
      ) async {
        await pumpRelayResolutionScreen(tester, useRouter: true);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        mockAuth.customRelayCompleter = Completer<LoginResult>();
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pump();

        final searchButton = tester.widget<WnButton>(
          find.byKey(const Key('try_custom_relay_button')),
        );
        expect(searchButton.loading, isTrue);

        final defaultsButton = tester.widget<WnButton>(
          find.byKey(const Key('use_default_relays_button')),
        );
        expect(defaultsButton.loading, isFalse);

        expect(searchButton.disabled, isTrue);
        expect(defaultsButton.disabled, isTrue);

        mockAuth.customRelayCompleter!.complete(
          LoginResult(
            account: Account(
              pubkey: testPubkeyA,
              accountType: AccountType.local,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            status: LoginStatus.complete,
          ),
        );
        await tester.pumpAndSettle();
      });
    });

    group('validation error display', () {
      testWidgets('shows validation error text for invalid URL', (tester) async {
        await pumpRelayResolutionScreen(tester);
        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Invalid relay URL'), findsOneWidget);
      });

      testWidgets('shows validation error for invalid scheme', (tester) async {
        await pumpRelayResolutionScreen(tester);
        await tester.enterText(find.byType(TextField), 'https://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('URL must start with wss:// or ws://'), findsOneWidget);
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
        await tester.pump(const Duration(milliseconds: 600));
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

      testWidgets('shows timeout error when publish defaults times out', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.publishDefaultRelaysError = const ApiError.loginTimeout(message: 'timed out');
        await tester.tap(find.byKey(const Key('use_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(
          find.text('Login timed out. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows connection error when custom relay has no connections', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.customRelayError = const ApiError.loginNoRelayConnections();
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(
          find.text(
            'Could not connect to any relays. Please check your connection and try again.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows generic error for unknown error key', (tester) async {
        await pumpRelayResolutionScreen(tester);
        mockAuth.customRelayError = Exception('Unknown error');
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
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
        await tester.pump(const Duration(milliseconds: 600));
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
        expect(mockAuth.externalSignerPublishDefaultRelaysCalled, isTrue);
        expect(mockAuth.loginPublishDefaultRelaysCalled, isFalse);
      });

      testWidgets('uses external signer callbacks for custom relay', (tester) async {
        await pumpRelayResolutionScreen(tester, isExternalSigner: true, useRouter: true);
        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const Key('try_custom_relay_button')));
        await tester.pumpAndSettle();
        expect(find.text('Chat List'), findsOneWidget);
        expect(mockAuth.externalSignerWithCustomRelayCalled, isTrue);
        expect(mockAuth.loginWithCustomRelayCalled, isFalse);
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

    group('clear button', () {
      testWidgets('shows paste button initially', (tester) async {
        await pumpRelayResolutionScreen(tester);
        expect(find.byKey(const Key('paste_button')), findsOneWidget);
        expect(find.byKey(const Key('clear_button')), findsNothing);
      });

      testWidgets('shows clear button when text is entered', (tester) async {
        await pumpRelayResolutionScreen(tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(find.byKey(const Key('clear_button')), findsOneWidget);
        expect(find.byKey(const Key('paste_button')), findsNothing);
      });

      testWidgets('clears input when clear button is tapped', (tester) async {
        await pumpRelayResolutionScreen(tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'wss://');
      });

      testWidgets('shows paste button after clearing', (tester) async {
        await pumpRelayResolutionScreen(tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(find.byKey(const Key('clear_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(find.byKey(const Key('paste_button')), findsOneWidget);
        expect(find.byKey(const Key('clear_button')), findsNothing);
      });

      testWidgets('disables search relay button after clearing', (tester) async {
        await pumpRelayResolutionScreen(tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        final buttonBefore = tester.widget<WnButton>(
          find.byKey(const Key('try_custom_relay_button')),
        );
        expect(buttonBefore.disabled, isFalse);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        final buttonAfter = tester.widget<WnButton>(
          find.byKey(const Key('try_custom_relay_button')),
        );
        expect(buttonAfter.disabled, isTrue);
      });

      testWidgets('clears validation error when clear button is tapped', (tester) async {
        await pumpRelayResolutionScreen(tester);

        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text('Invalid relay URL'), findsOneWidget);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(find.text('Invalid relay URL'), findsNothing);
      });
    });
  });
}
