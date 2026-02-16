import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData, Consumer, ProviderScope;
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/home_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  @override
  Future<Account> crateApiAccountsCreateIdentity() async {
    return Account(
      pubkey: testPubkeyA,
      accountType: AccountType.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    return const FlutterMetadata(displayName: 'Test User', custom: {});
  }
}

class _MockAuthNotifier extends AuthNotifier {
  Exception? errorToThrow;

  @override
  Future<String?> build() async => null;

  @override
  Future<String> signup() async {
    if (errorToThrow != null) throw errorToThrow!;
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

void main() {
  setUpAll(() => RustLib.initMock(api: _MockApi()));

  Future<void> pumpSignupScreen(WidgetTester tester, {List overrides = const []}) async {
    await mountTestApp(tester, overrides: overrides);
    Routes.pushToSignup(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('SignupScreen', () {
    testWidgets('displays Setup profile title', (tester) async {
      await pumpSignupScreen(tester);
      expect(find.text('Setup profile'), findsOneWidget);
    });

    testWidgets('displays name input field', (tester) async {
      await pumpSignupScreen(tester);
      expect(find.text('Choose a name'), findsOneWidget);
    });

    testWidgets('displays bio input field', (tester) async {
      await pumpSignupScreen(tester);
      expect(find.text('Introduce yourself'), findsOneWidget);
    });

    testWidgets('displays Cancel button', (tester) async {
      await pumpSignupScreen(tester);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays Sign Up button', (tester) async {
      await pumpSignupScreen(tester);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    group('navigation', () {
      testWidgets('tapping back button returns to home screen', (tester) async {
        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('tapping Cancel returns to home screen', (tester) async {
        await pumpSignupScreen(tester);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('tapping outside slate returns to home screen', (tester) async {
        await pumpSignupScreen(tester);
        // Tap on the left margin area where the background is exposed
        await tester.tapAt(const Offset(5, 400));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('carousel', () {
      testWidgets('displays Learn more button', (tester) async {
        await pumpSignupScreen(tester);
        expect(find.text('Learn more'), findsOneWidget);
        expect(find.byKey(const Key('learn_more_arrow')), findsOneWidget);
      });

      testWidgets('tapping Learn more shows onboarding carousel', (tester) async {
        await pumpSignupScreen(tester);
        expect(find.byType(WnOnboardingCarousel), findsNothing);

        await tester.tap(find.byKey(const Key('learn_more_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnOnboardingCarousel), findsOneWidget);
      });

      testWidgets('carousel shows Back to sign up button', (tester) async {
        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('learn_more_button')));
        await tester.pumpAndSettle();

        expect(find.text('Back to sign up'), findsOneWidget);
        expect(find.byKey(const Key('back_to_signup_arrow')), findsOneWidget);
      });

      testWidgets('tapping Back to sign up hides carousel', (tester) async {
        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('learn_more_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnOnboardingCarousel), findsOneWidget);

        await tester.tap(find.byKey(const Key('back_to_signup_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnOnboardingCarousel), findsNothing);
        expect(find.text('Setup profile'), findsOneWidget);
      });

      testWidgets('tapping outside does not dismiss when carousel is visible', (tester) async {
        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('learn_more_button')));
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(195, 50));
        await tester.pumpAndSettle();

        expect(find.byType(WnOnboardingCarousel), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      });
    });

    group('submit', () {
      late _MockAuthNotifier mockAuth;
      late List overrides;

      setUp(() {
        mockAuth = _MockAuthNotifier();
        overrides = [
          authProvider.overrideWith(() => mockAuth),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ];
      });

      testWidgets('redirects to chat list on success', (tester) async {
        await pumpSignupScreen(tester, overrides: overrides);
        await tester.enterText(find.byType(TextField).first, 'Test User');
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(ChatListScreen), findsOneWidget);
      });

      testWidgets('does not redirect on failure', (tester) async {
        mockAuth.errorToThrow = Exception('Network error');
        await pumpSignupScreen(tester, overrides: overrides);
        await tester.enterText(find.byType(TextField).first, 'Test User');
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(ChatListScreen), findsNothing);
      });
    });

    group('keyboard', () {
      testWidgets(
        'inputs remain visible when keyboard appears',
        (tester) async {
          tester.view.physicalSize = const Size(390, 550);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              child: ScreenUtilInit(
                designSize: testDesignSize,
                builder: (_, _) => Consumer(
                  builder: (context, ref, _) {
                    return MaterialApp.router(
                      routerConfig: Routes.build(ref),
                      locale: const Locale('en'),
                      localizationsDelegates: AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                    );
                  },
                ),
              ),
            ),
          );

          Routes.pushToSignup(tester.element(find.byType(Scaffold)));
          await tester.pumpAndSettle();

          expect(find.text('Choose a name'), findsOneWidget);
          expect(find.text('Sign Up'), findsOneWidget);

          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text('Choose a name'), findsOneWidget);

          addTearDown(() => tester.view.resetViewInsets());
        },
      );
    });

    group('image picker', () {
      testWidgets('shows system notice when image picker fails', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'error', message: 'Test error');
          },
        );
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('plugins.flutter.io/image_picker'),
                null,
              );
        });

        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('avatar_edit_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to pick image. Please try again.'), findsOneWidget);
      });

      testWidgets('dismisses notice after auto-hide duration', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'error', message: 'Test error');
          },
        );
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('plugins.flutter.io/image_picker'),
                null,
              );
        });

        await pumpSignupScreen(tester);
        await tester.tap(find.byKey(const Key('avatar_edit_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsNothing);
      });
    });
  });
}
