import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData, ProviderScope;
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/home_screen.dart';
import 'package:whitenoise/screens/login_screen.dart';
import 'package:whitenoise/screens/relay_resolution_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';

import '../mocks/mock_android_signer_channel.dart';
import '../mocks/mock_clipboard_paste.dart';
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
  bool loginCalled = false;
  String? lastNsec;
  Exception? errorToThrow;
  LoginStatus loginResultStatus = LoginStatus.complete;
  bool loginWithSignerCalled = false;
  String? lastSignerPubkey;
  Exception? signerErrorToThrow;
  LoginStatus signerLoginResultStatus = LoginStatus.complete;
  Completer<void>? loginCompleter;
  Completer<void>? signerLoginCompleter;

  @override
  Future<String?> build() async => null;

  @override
  Future<LoginResult> loginStart(String nsec) async {
    loginCalled = true;
    lastNsec = nsec;
    if (loginCompleter != null) {
      await loginCompleter!.future;
    }
    if (errorToThrow != null) throw errorToThrow!;
    if (loginResultStatus == LoginStatus.complete) {
      state = const AsyncData(testPubkeyA);
    }
    return LoginResult(
      account: Account(
        pubkey: testPubkeyA,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: loginResultStatus,
    );
  }

  @override
  Future<LoginResult> loginExternalSignerStart({
    required String pubkey,
  }) async {
    loginWithSignerCalled = true;
    lastSignerPubkey = pubkey;
    if (signerLoginCompleter != null) {
      await signerLoginCompleter!.future;
    }
    if (signerErrorToThrow != null) throw signerErrorToThrow!;
    if (signerLoginResultStatus == LoginStatus.complete) {
      state = AsyncData(pubkey);
    }
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: signerLoginResultStatus,
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
  late MockAndroidSignerChannel mockSignerChannel;

  Future<void> pumpLoginScreen(
    WidgetTester tester, {
    bool signerAvailable = false,
  }) async {
    mockAuth = _MockAuthNotifier();
    mockSignerChannel = mockAndroidSignerChannel();
    addTearDown(mockSignerChannel.reset);

    if (signerAvailable) {
      mockSignerChannel.setResult('isExternalSignerInstalled', true);
      mockSignerChannel.setResult('getPublicKey', {'result': testPubkeyA});
      setUpTestView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => mockAuth)],
          child: ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LoginScreen(),
            ),
          ),
        ),
      );
    } else {
      await mountTestApp(
        tester,
        overrides: [authProvider.overrideWith(() => mockAuth)],
      );
      Routes.pushToLogin(tester.element(find.byType(Scaffold)));
    }
    await tester.pumpAndSettle();
  }

  group('LoginScreen', () {
    group('navigation', () {
      testWidgets('tapping back button returns to home screen', (tester) async {
        await pumpLoginScreen(tester);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('tapping outside slate returns to home screen', (tester) async {
        await pumpLoginScreen(tester);
        await tester.tap(find.byKey(const Key('login_background')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('login', () {
      testWidgets('calls login method with entered nsec', (tester) async {
        await pumpLoginScreen(tester);
        await tester.enterText(find.byType(TextField), 'nsec1test');
        await tester.pump();
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();
        expect(mockAuth.lastNsec, 'nsec1test');
        expect(mockAuth.loginCalled, isTrue);
      });

      group('when login is successful', () {
        testWidgets('redirects to chat list screen on success', (tester) async {
          await pumpLoginScreen(tester);
          await tester.enterText(find.byType(TextField), 'nsec1test');
          await tester.pump();
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();
          expect(find.byType(ChatListScreen), findsOneWidget);
        });
      });

      group('when login needs relay lists', () {
        testWidgets('navigates to relay resolution screen', (tester) async {
          await pumpLoginScreen(tester);
          mockAuth.loginResultStatus = LoginStatus.needsRelayLists;
          await tester.enterText(find.byType(TextField), 'nsec1test');
          await tester.pump();
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();
          expect(find.byType(RelayResolutionScreen), findsOneWidget);
        });
      });

      group('when login fails', () {
        testWidgets('does not redirect to chat list screen', (tester) async {
          await pumpLoginScreen(tester);
          mockAuth.errorToThrow = Exception('Invalid key');
          await tester.enterText(find.byType(TextField), 'nsec1test');
          await tester.pump();
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();
          expect(find.byType(ChatListScreen), findsNothing);
        });

        testWidgets('shows error message on failure', (tester) async {
          await pumpLoginScreen(tester);
          mockAuth.errorToThrow = Exception('Invalid key');
          await tester.enterText(find.byType(TextField), 'nsec1test');
          await tester.pump();
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('An error occurred during login. Please try again.'),
            findsOneWidget,
          );
        });
      });
    });

    group('paste button', () {
      late void Function(Map<String, dynamic>?) setClipboardData;
      late void Function() resetClipboard;

      setUp(() {
        final mock = mockClipboardPaste();
        setClipboardData = mock.setData;
        resetClipboard = mock.reset;
      });

      tearDown(() {
        resetClipboard();
      });

      testWidgets('displays paste button', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byKey(const Key('paste_button')), findsOneWidget);
      });

      testWidgets('pastes clipboard text into field', (tester) async {
        await pumpLoginScreen(tester);
        setClipboardData({'text': 'nsec1pasted'});
        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pumpAndSettle();
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'nsec1pasted');
      });
    });

    group('button types and disabled state', () {
      testWidgets('login button is primary when signer is unavailable', (tester) async {
        await pumpLoginScreen(tester);
        final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
        expect(loginButton.type, WnButtonType.primary);
      });

      testWidgets('login button is disabled when nsec is empty', (tester) async {
        await pumpLoginScreen(tester);
        final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
        expect(loginButton.disabled, isTrue);
      });

      testWidgets('login button is enabled when nsec is entered', (tester) async {
        await pumpLoginScreen(tester);
        await tester.enterText(find.byType(TextField), 'nsec1abc');
        await tester.pump();
        final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
        expect(loginButton.disabled, isFalse);
      });

      testWidgets(
        'login is primary and disabled, amber is outline when signer available and nsec empty',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
          final signerButton = tester.widget<WnButton>(
            find.byKey(const Key('android_signer_login_button')),
          );
          expect(loginButton.type, WnButtonType.primary);
          expect(loginButton.disabled, isTrue);
          expect(signerButton.type, WnButtonType.outline);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'login is primary and enabled, amber is outline when signer available and nsec entered',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          await tester.enterText(find.byType(TextField), 'nsec1abc');
          await tester.pump();
          final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
          final signerButton = tester.widget<WnButton>(
            find.byKey(const Key('android_signer_login_button')),
          );
          expect(loginButton.type, WnButtonType.primary);
          expect(loginButton.disabled, isFalse);
          expect(signerButton.type, WnButtonType.outline);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('Android signer login', () {
      testWidgets('does not show signer button when signer unavailable', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byKey(const Key('android_signer_login_button')), findsNothing);
      });

      testWidgets(
        'shows signer button when signer is available',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          expect(find.byKey(const Key('android_signer_login_button')), findsOneWidget);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      group('when signer is loading', () {
        testWidgets(
          'signer button is loading',
          (tester) async {
            await pumpLoginScreen(tester, signerAvailable: true);
            final getPublicKeyCompleter = Completer<Map<String, dynamic>>();
            mockSignerChannel.setResult('getPublicKey', getPublicKeyCompleter.future);
            await tester.tap(find.byKey(const Key('android_signer_login_button')));
            await tester.pump();

            final signerButton = tester.widget<WnButton>(
              find.byKey(const Key('android_signer_login_button')),
            );
            expect(signerButton.loading, isTrue);
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'login button is disabled',
          (tester) async {
            await pumpLoginScreen(tester, signerAvailable: true);
            final getPublicKeyCompleter = Completer<Map<String, dynamic>>();
            mockSignerChannel.setResult('getPublicKey', getPublicKeyCompleter.future);
            await tester.tap(find.byKey(const Key('android_signer_login_button')));
            await tester.pump();
            final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
            expect(loginButton.disabled, isTrue);
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );
      });
      testWidgets(
        'calls loginExternalSignerStart when signer button is tapped',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          mockAuth.signerLoginCompleter = Completer<void>();
          await tester.tap(find.byKey(const Key('android_signer_login_button')));
          await tester.pump();
          expect(mockAuth.loginWithSignerCalled, isTrue);
          expect(mockAuth.lastSignerPubkey, testPubkeyA);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'shows user-friendly error for AndroidSignerException',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          mockSignerChannel.setException(
            'getPublicKey',
            PlatformException(code: 'USER_REJECTED', message: 'User rejected'),
          );
          await tester.tap(find.byKey(const Key('android_signer_login_button')));
          await tester.pumpAndSettle();
          expect(find.text('Login cancelled'), findsOneWidget);
          expect(find.byType(ChatListScreen), findsNothing);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'shows generic error for other exceptions',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          mockSignerChannel.setException(
            'getPublicKey',
            PlatformException(code: 'UNKNOWN', message: 'Network error'),
          );
          await tester.tap(find.byKey(const Key('android_signer_login_button')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('An error occurred with the signer. Please try again.'),
            findsOneWidget,
          );
          expect(find.byType(ChatListScreen), findsNothing);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      group('signer error messages', () {
        Future<void> testSignerError(
          WidgetTester tester,
          String errorCode,
          String expectedMessage,
        ) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          mockSignerChannel.setException(
            'getPublicKey',
            PlatformException(code: errorCode, message: errorCode),
          );
          await tester.tap(find.byKey(const Key('android_signer_login_button')));
          await tester.pumpAndSettle();
          expect(find.text(expectedMessage), findsOneWidget);
        }

        testWidgets(
          'NOT_CONNECTED shows connection error',
          (tester) async {
            await testSignerError(
              tester,
              'NOT_CONNECTED',
              'Not connected to signer. Please try again.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_SIGNER shows no signer error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_SIGNER',
              'No signer app found. Please install a NIP-55 compatible signer.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_RESPONSE shows no response error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_RESPONSE',
              'No response from signer. Please try again.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_PUBKEY shows no pubkey error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_PUBKEY',
              'Unable to get public key from signer.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_RESULT shows no result error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_RESULT',
              'Signer did not return a result.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_EVENT shows no event error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_EVENT',
              'Signer did not return a signed event.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'NO_ACTIVITY shows no activity error',
          (tester) async {
            await testSignerError(
              tester,
              'NO_ACTIVITY',
              'Unable to launch signer. Please try again.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'LAUNCH_ERROR shows launch error',
          (tester) async {
            await testSignerError(
              tester,
              'LAUNCH_ERROR',
              'Failed to launch signer app.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'CONNECTION_ERROR shows connection error',
          (tester) async {
            await testSignerError(
              tester,
              'CONNECTION_ERROR',
              'Unable to connect to signer. Please try again.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );

        testWidgets(
          'REQUEST_IN_PROGRESS shows request in progress error',
          (tester) async {
            await testSignerError(
              tester,
              'REQUEST_IN_PROGRESS',
              'Another request is in progress. Please wait.',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );
      });

      testWidgets(
        'redirects to chat list on successful login with signer',
        (tester) async {
          mockAuth = _MockAuthNotifier();
          mockSignerChannel = mockAndroidSignerChannel();
          addTearDown(mockSignerChannel.reset);
          mockSignerChannel.setResult('isExternalSignerInstalled', true);
          mockSignerChannel.setResult('getPublicKey', {'result': testPubkeyA});

          await mountTestApp(
            tester,
            overrides: [authProvider.overrideWith(() => mockAuth)],
          );
          Routes.pushToLogin(tester.element(find.byType(Scaffold)));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('android_signer_login_button')));
          await tester.pumpAndSettle();
          expect(find.byType(ChatListScreen), findsOneWidget);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('nsec input', () {
      testWidgets('clears error when typing', (tester) async {
        await pumpLoginScreen(tester);
        mockAuth.errorToThrow = Exception('Invalid key');
        await tester.enterText(find.byType(TextField), 'nsec1test');
        await tester.pump();
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('An error occurred during login. Please try again.'),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextField), 'nsec1new');
        await tester.pumpAndSettle();
        expect(
          find.textContaining('An error occurred during login. Please try again.'),
          findsNothing,
        );
      });

      testWidgets('does not call login when nsec is empty', (tester) async {
        await pumpLoginScreen(tester);
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();
        expect(mockAuth.loginCalled, isFalse);
      });
    });

    group('when nsec login is loading', () {
      testWidgets('login button shows loading', (tester) async {
        await pumpLoginScreen(tester);
        final completer = Completer<void>();
        mockAuth.loginCompleter = completer;

        await tester.enterText(find.byType(TextField), 'nsec1test');
        await tester.pump();
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        final loginButton = tester.widget<WnButton>(find.byKey(const Key('login_button')));
        expect(loginButton.loading, isTrue);

        completer.complete();
      });

      testWidgets(
        'signer button is disabled',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          mockAuth.loginCompleter = Completer<void>();

          await tester.enterText(find.byType(TextField), 'nsec1test');
          await tester.pump();
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pump();

          final signerButton = tester.widget<WnButton>(
            find.byKey(const Key('android_signer_login_button')),
          );
          expect(signerButton.disabled, isTrue);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('scan button', () {
      testWidgets('displays scan button', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
      });
    });

    group('carousel', () {
      testWidgets('displays login carousel', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byType(WnOnboardingCarousel), findsOneWidget);
      });

      testWidgets('displays carousel content', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.text('Privacy and security'), findsOneWidget);
      });

      testWidgets('displays carousel indicator', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byKey(const Key('login_carousel_indicator')), findsOneWidget);
      });

      testWidgets('carousel uses smaller bottom padding when signer is unavailable', (
        tester,
      ) async {
        await pumpLoginScreen(tester);
        final padding = tester.widget<Padding>(find.byKey(const Key('login_carousel_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).bottom, lessThan(200));
      });

      testWidgets(
        'carousel uses larger bottom padding when signer is available',
        (tester) async {
          await pumpLoginScreen(tester, signerAvailable: true);
          final padding = tester.widget<Padding>(find.byKey(const Key('login_carousel_padding')));
          expect(padding.padding.resolve(TextDirection.ltr).bottom, greaterThan(200));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('keyboard overlay', () {
      testWidgets('shows WnOverlay when keyboard is open', (tester) async {
        mockAuth = _MockAuthNotifier();
        mockSignerChannel = mockAndroidSignerChannel();
        addTearDown(mockSignerChannel.reset);

        setUpTestView(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authProvider.overrideWith(() => mockAuth)],
            child: ScreenUtilInit(
              designSize: testDesignSize,
              builder: (_, _) => const MediaQuery(
                data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
                child: MaterialApp(
                  locale: Locale('en'),
                  localizationsDelegates: _localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: LoginScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WnOverlay), findsOneWidget);
      });

      testWidgets('does not show WnOverlay when keyboard is closed', (tester) async {
        await pumpLoginScreen(tester);
        expect(find.byType(WnOverlay), findsNothing);
      });
    });
  });
}
