import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/is_adding_account_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/add_profile_screen.dart';
import 'package:whitenoise/screens/login_screen.dart';
import 'package:whitenoise/screens/signup_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

final _mockApi = _MockApi();

class _MockApi extends MockWnApi {}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => testPubkeyA;
}

void main() {
  setUpAll(() => RustLib.initMock(api: _mockApi));

  setUp(() => _mockApi.reset());

  Future<void> pumpAddProfileScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToAddProfile(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('AddProfileScreen', () {
    testWidgets('displays Add a new profile title', (tester) async {
      await pumpAddProfileScreen(tester);
      expect(find.text('Add a new profile'), findsOneWidget);
    });

    testWidgets('displays Login button', (tester) async {
      await pumpAddProfileScreen(tester);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('displays Sign Up button', (tester) async {
      await pumpAddProfileScreen(tester);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders compact slate height for action-only content', (tester) async {
      await pumpAddProfileScreen(tester);

      final scaffoldSize = tester.getSize(find.byType(Scaffold));
      final slateSize = tester.getSize(find.byType(WnSlate));

      expect(slateSize.height, lessThan(scaffoldSize.height * 0.6));
    });

    testWidgets('anchors compact slate to bottom of screen', (tester) async {
      await pumpAddProfileScreen(tester);

      final scaffoldSize = tester.getSize(find.byType(Scaffold));
      final slateTopLeft = tester.getTopLeft(find.byType(WnSlate));
      final slateBottomRight = tester.getBottomRight(find.byType(WnSlate));

      expect(slateTopLeft.dy, greaterThan(scaffoldSize.height * 0.2));
      expect(scaffoldSize.height - slateBottomRight.dy, lessThanOrEqualTo(40));
    });

    testWidgets('tapping Login navigates to LoginScreen', (tester) async {
      await pumpAddProfileScreen(tester);
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('tapping Login sets isAddingAccountProvider to true', (tester) async {
      await pumpAddProfileScreen(tester);
      final context = tester.element(find.byType(Scaffold));
      final container = ProviderScope.containerOf(context);
      expect(container.read(isAddingAccountProvider), false);
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(container.read(isAddingAccountProvider), true);
    });

    testWidgets('tapping Sign Up navigates to SignupScreen', (tester) async {
      await pumpAddProfileScreen(tester);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('tapping Sign Up sets isAddingAccountProvider to true', (tester) async {
      await pumpAddProfileScreen(tester);
      final context = tester.element(find.byType(Scaffold));
      final container = ProviderScope.containerOf(context);
      expect(container.read(isAddingAccountProvider), false);
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      expect(container.read(isAddingAccountProvider), true);
    });

    testWidgets('displays back button', (tester) async {
      await pumpAddProfileScreen(tester);
      expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
    });

    testWidgets('tapping back button returns to previous screen', (tester) async {
      await pumpAddProfileScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AddProfileScreen), findsNothing);
    });

    group('when offline', () {
      Future<void> pumpAddProfileScreenOffline(WidgetTester tester) async {
        await mountTestApp(
          tester,
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier()),
            secureStorageProvider.overrideWithValue(MockSecureStorage()),
            offlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
        );
        Routes.pushToAddProfile(tester.element(find.byType(Scaffold)));
        await tester.pumpAndSettle();
      }

      testWidgets('displays offline notice', (tester) async {
        await pumpAddProfileScreenOffline(tester);
        expect(find.byKey(const Key('offline_notice')), findsOneWidget);
        expect(find.text('Waiting for internet connection'), findsOneWidget);
      });

      testWidgets('Login button is disabled', (tester) async {
        await pumpAddProfileScreenOffline(tester);
        final loginButton = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Login'));
        expect(loginButton.disabled, isTrue);
      });

      testWidgets('Sign Up button is disabled', (tester) async {
        await pumpAddProfileScreenOffline(tester);
        final signupButton = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Sign Up'));
        expect(signupButton.disabled, isTrue);
      });

      testWidgets('tapping Login does not navigate', (tester) async {
        await pumpAddProfileScreenOffline(tester);
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('tapping Sign Up does not navigate', (tester) async {
        await pumpAddProfileScreenOffline(tester);
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(SignupScreen), findsNothing);
      });
    });
  });
}
