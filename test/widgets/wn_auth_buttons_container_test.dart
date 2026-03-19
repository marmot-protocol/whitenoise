import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_auth_buttons_container.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import '../test_helpers.dart';

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
  });
}
