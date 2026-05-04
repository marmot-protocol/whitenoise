import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_auth_buttons_container.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import '../test_helpers.dart';

class MockNavigatorObserver extends NavigatorObserver {
  int didPushCount = 0;
  int didReplaceCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount++;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    didReplaceCount++;
  }
}

void main() {
  group('WnAuthButtonsContainer', () {
    testWidgets('displays Login button', (tester) async {
      const widget = WnAuthButtonsContainer();
      await mountWidget(widget, tester);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('displays Sign Up button', (tester) async {
      const widget = WnAuthButtonsContainer();
      await mountWidget(widget, tester);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('displays two WnButton widgets', (tester) async {
      const widget = WnAuthButtonsContainer();
      await mountWidget(widget, tester);
      expect(find.byType(WnButton), findsNWidgets(2));
    });

    testWidgets('calls onLogin when Login button is tapped', (tester) async {
      var onLoginCalled = false;
      final widget = WnAuthButtonsContainer(
        onLogin: () {
          onLoginCalled = true;
        },
      );
      await mountWidget(widget, tester);
      await tester.tap(find.text('Login'));
      expect(onLoginCalled, isTrue);
    });

    testWidgets('calls onSignup when Sign Up button is tapped', (tester) async {
      var onSignupCalled = false;
      final widget = WnAuthButtonsContainer(
        onSignup: () {
          onSignupCalled = true;
        },
      );
      await mountWidget(widget, tester);
      await tester.tap(find.text('Sign Up'));
      expect(onSignupCalled, isTrue);
    });

    testWidgets('calls both callbacks when provided', (tester) async {
      var onLoginCalled = false;
      var onSignupCalled = false;
      final widget = WnAuthButtonsContainer(
        onLogin: () {
          onLoginCalled = true;
        },
        onSignup: () {
          onSignupCalled = true;
        },
      );
      await mountWidget(widget, tester);
      await tester.tap(find.text('Login'));
      expect(onLoginCalled, isTrue);
      expect(onSignupCalled, isFalse);
      onLoginCalled = false;
      await tester.tap(find.text('Sign Up'));
      expect(onLoginCalled, isFalse);
      expect(onSignupCalled, isTrue);
    });

    testWidgets('navigates to login screen when Login tapped without callback', (tester) async {
      await mountTestApp(tester);
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your private key'), findsOneWidget);
    });

    testWidgets('navigates to signup screen when Sign Up tapped without callback', (tester) async {
      await mountTestApp(tester);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
    });

    group('when disabled', () {
      testWidgets('both buttons have disabled set to true', (tester) async {
        const widget = WnAuthButtonsContainer(disabled: true);
        await mountWidget(widget, tester);

        final loginButton = tester.widget<WnButton>(
          find.widgetWithText(WnButton, 'Login'),
        );
        final signupButton = tester.widget<WnButton>(
          find.widgetWithText(WnButton, 'Sign Up'),
        );

        expect(loginButton.disabled, isTrue);
        expect(signupButton.disabled, isTrue);
      });

      testWidgets('does not call onLogin when disabled and Login tapped', (tester) async {
        var onLoginCalled = false;
        final widget = WnAuthButtonsContainer(
          onLogin: () {
            onLoginCalled = true;
          },
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.text('Login'));
        expect(onLoginCalled, isFalse);
      });

      testWidgets('does not call onSignup when disabled and Sign Up tapped', (tester) async {
        var onSignupCalled = false;
        final widget = WnAuthButtonsContainer(
          onSignup: () {
            onSignupCalled = true;
          },
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.text('Sign Up'));
        expect(onSignupCalled, isFalse);
      });

      testWidgets('Login button onPressed is null when disabled', (tester) async {
        const widget = WnAuthButtonsContainer(disabled: true);
        await mountWidget(widget, tester);

        final loginButton = tester.widget<WnButton>(
          find.widgetWithText(WnButton, 'Login'),
        );
        expect(loginButton.onPressed, isNull);
      });

      testWidgets('Sign Up button onPressed is null when disabled', (tester) async {
        const widget = WnAuthButtonsContainer(disabled: true);
        await mountWidget(widget, tester);

        final signupButton = tester.widget<WnButton>(
          find.widgetWithText(WnButton, 'Sign Up'),
        );
        expect(signupButton.onPressed, isNull);
      });

      testWidgets('default navigation is prevented when disabled', (tester) async {
        final navigatorObserver = MockNavigatorObserver();
        const widget = WnAuthButtonsContainer(disabled: true);
        await mountWidget(
          widget,
          tester,
          navigatorObservers: [navigatorObserver],
        );

        final baselinePushCount = navigatorObserver.didPushCount;

        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        expect(navigatorObserver.didPushCount, baselinePushCount);
        expect(navigatorObserver.didReplaceCount, 0);
      });
    });
  });
}
