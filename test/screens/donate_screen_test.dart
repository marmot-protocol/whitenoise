import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_clipboard.dart';
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

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => testPubkeyA;
}

void main() {
  setUpAll(() => RustLib.initMock(api: _MockApi()));
  Future<void> pumpDonateScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _AuthenticatedAuthNotifier())],
    );

    Routes.pushToDonate(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('DonateScreen', () {
    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpDonateScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('shows lightning address', (tester) async {
      await pumpDonateScreen(tester);

      expect(find.text('whitenoise@npub.cash'), findsOneWidget);
    });

    testWidgets('shows bitcoin address', (tester) async {
      await pumpDonateScreen(tester);

      expect(
        find.textContaining('sp1qqvp56mxcj9pz9xudvlch5g4ah5hrc8rj6neu25p'),
        findsOneWidget,
      );
    });

    testWidgets('shows updated donation copy', (tester) async {
      await pumpDonateScreen(tester);

      expect(find.textContaining('As a 501(c)3 non-profit'), findsOneWidget);
      expect(
        find.text(
          'If you need a contribution acknowledgement letter for a donation, get in touch with us at info@ipf.dev',
        ),
        findsOneWidget,
      );
    });

    group('when copying lightning address', () {
      testWidgets('shows feedback message', (tester) async {
        await pumpDonateScreen(tester);

        await tester.tap(find.byKey(const Key('copy_button')).first);
        await tester.pump();

        expect(find.text('Copied to clipboard. Thank you!'), findsOneWidget);
      });

      testWidgets('saves lightning address to clipboard', (tester) async {
        final getClipboard = mockClipboard();
        await pumpDonateScreen(tester);

        await tester.tap(find.byKey(const Key('copy_button')).first);
        await tester.pump();

        expect(getClipboard(), 'whitenoise@npub.cash');
      });
    });

    group('when copying bitcoin address', () {
      testWidgets('shows feedback message', (tester) async {
        await pumpDonateScreen(tester);

        await tester.tap(find.byKey(const Key('copy_button')).last);
        await tester.pump();

        expect(find.text('Copied to clipboard. Thank you!'), findsOneWidget);
      });

      testWidgets('saves bitcoin address to clipboard', (tester) async {
        final getClipboard = mockClipboard();
        await pumpDonateScreen(tester);

        await tester.tap(find.byKey(const Key('copy_button')).last);
        await tester.pump();

        expect(
          getClipboard(),
          'sp1qqvp56mxcj9pz9xudvlch5g4ah5hrc8rj6neu25p34rc9gxhp38cwqqlmld28u57w2srgckr34dkyg3q02phu8tm05cyj483q026xedp0s5f5j40p',
        );
      });
    });

    group('system notice', () {
      testWidgets('auto-dismisses after timeout', (tester) async {
        await pumpDonateScreen(tester);

        await tester.tap(find.byKey(const Key('copy_button')).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Copied to clipboard. Thank you!'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(find.text('Copied to clipboard. Thank you!'), findsNothing);
      });
    });
  });
}
