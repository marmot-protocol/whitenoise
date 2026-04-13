import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/donate_screen.dart';
import 'package:whitenoise/screens/settings_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard;
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  Future<void> pumpDonateScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Donate'), 500);
    await tester.tap(find.text('Donate'));
    await tester.pumpAndSettle();
  }

  group('DonateScreen', () {
    testWidgets('displays Donate title', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.byType(DonateScreen), findsOneWidget);
      expect(find.text('Donate'), findsWidgets);
    });

    testWidgets('uses shrink wrap slate', (tester) async {
      await pumpDonateScreen(tester);
      final slate = tester.widget<WnSlate>(find.byType(WnSlate));
      expect(slate.shrinkWrapContent, isTrue);
    });

    testWidgets('displays donate description text', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.textContaining('501(c)3 non-profit'), findsOneWidget);
    });

    testWidgets('displays lightning address copyable field', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.text('Lightning Address'), findsOneWidget);
      expect(find.text('whitenoise@npub.cash'), findsOneWidget);
    });

    testWidgets('displays bitcoin silent payment copyable field', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.text('Bitcoin Silent Payment'), findsOneWidget);
      expect(
        find.textContaining('sp1qqvp56mxcj9pz9xudvlch5g4ah5hrc8rj6neu25p'),
        findsOneWidget,
      );
    });

    testWidgets('displays two WnCopyableField widgets', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.byType(WnCopyableField), findsNWidgets(2));
    });

    testWidgets('displays contribution acknowledgment callout', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.byKey(const Key('contribution_acknowledgment_callout')), findsOneWidget);
      expect(find.byType(WnCallout), findsOneWidget);
      expect(find.text('Contribution acknowledgment'), findsOneWidget);
    });

    testWidgets('contribution callout expands to show letter text', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.textContaining('contribution acknowledgement letter'), findsNothing);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('contribution acknowledgement letter'), findsOneWidget);
      expect(find.textContaining('info@ipf.dev'), findsOneWidget);
    });

    testWidgets('tapping back button returns to SettingsScreen', (tester) async {
      await pumpDonateScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('copying lightning address copies correct value and shows notice', (tester) async {
      final getClipboard = mockClipboard();
      addTearDown(clearClipboardMock);
      await pumpDonateScreen(tester);
      final lightningCopyButton = find.descendant(
        of: find.byKey(const Key('lightning_copyable_field')),
        matching: find.byKey(const Key('copy_button')),
      );
      await tester.tap(lightningCopyButton);
      await tester.pump();
      expect(getClipboard(), 'whitenoise@npub.cash');
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('copying bitcoin address copies correct value and shows notice', (tester) async {
      final getClipboard = mockClipboard();
      addTearDown(clearClipboardMock);
      await pumpDonateScreen(tester);
      final bitcoinCopyButton = find.descendant(
        of: find.byKey(const Key('bitcoin_copyable_field')),
        matching: find.byKey(const Key('copy_button')),
      );
      await tester.tap(bitcoinCopyButton);
      await tester.pump();
      expect(
        getClipboard(),
        'sp1qqvp56mxcj9pz9xudvlch5g4ah5hrc8rj6neu25p34rc9gxhp38cwqqlmld28u57w2srgckr34dkyg3q02phu8tm05cyj483q026xedp0s5f5j40p',
      );
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('copied notice auto-dismisses after timeout', (tester) async {
      await pumpDonateScreen(tester);
      final lightningCopyButton = find.descendant(
        of: find.byKey(const Key('lightning_copyable_field')),
        matching: find.byKey(const Key('copy_button')),
      );
      await tester.tap(lightningCopyButton);
      await tester.pump();
      expect(find.byType(WnSystemNotice), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(WnSystemNotice), findsNothing);
    });
  });
}
