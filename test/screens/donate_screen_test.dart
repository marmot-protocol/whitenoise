import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/donate_screen.dart';
import 'package:whitenoise/screens/settings_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

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
    });

    testWidgets('displays two WnCopyableField widgets', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.byType(WnCopyableField), findsNWidgets(2));
    });

    testWidgets('displays contribution letter text', (tester) async {
      await pumpDonateScreen(tester);
      expect(find.textContaining('contribution acknowledgement letter'), findsOneWidget);
    });

    testWidgets('tapping back button returns to SettingsScreen', (tester) async {
      await pumpDonateScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('copying lightning address shows copied notice', (tester) async {
      await pumpDonateScreen(tester);
      await tester.tap(find.byKey(const Key('copy_button')).first);
      await tester.pump();
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.textContaining('Thank you'), findsOneWidget);
    });

    testWidgets('copied notice auto-dismisses after timeout', (tester) async {
      await pumpDonateScreen(tester);
      await tester.tap(find.byKey(const Key('copy_button')).first);
      await tester.pump();
      expect(find.byType(WnSystemNotice), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(WnSystemNotice), findsNothing);
    });
  });
}
