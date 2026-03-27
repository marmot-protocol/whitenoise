import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/relay_control_state_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard;
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {}

void main() {
  final api = _MockApi();

  setUpAll(() => RustLib.initMock(api: api));
  setUp(api.reset);

  testWidgets('loads relay control dump on open and renders result', (tester) async {
    api.relayControlStateResult = '{\n  "group": {"active": true}\n}';

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    expect(api.relayControlStateCallCount, 1);
    expect(find.byKey(const Key('relay_control_state_result')), findsOneWidget);
    expect(find.textContaining('"group"'), findsOneWidget);
  });

  testWidgets('refresh button requests a fresh dump', (tester) async {
    api.relayControlStateResult = '{"snapshot":1}';

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    api.relayControlStateResult = '{"snapshot":2}';
    await tester.tap(find.byKey(const Key('relay_control_state_refresh_button')));
    await tester.pumpAndSettle();

    expect(api.relayControlStateCallCount, 2);
    expect(find.textContaining('"snapshot":2'), findsOneWidget);
  });

  testWidgets('shows errors from relay control dump', (tester) async {
    api.shouldFailRelayControlState = true;

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    expect(find.byType(WnSystemNotice), findsOneWidget);
    expect(find.textContaining('Failed to load relay control state'), findsOneWidget);
  });

  testWidgets('copy button is disabled before a result is loaded', (tester) async {
    api.shouldFailRelayControlState = true;

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    final copyButton = tester.widget<WnButton>(
      find.byKey(const Key('relay_control_state_copy_button')),
    );
    expect(copyButton.onPressed, isNull);
  });

  testWidgets('back button is rendered', (tester) async {
    await mountWidget(const RelayControlStateScreen(), tester);

    expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
  });

  testWidgets('copy button copies dump to clipboard', (tester) async {
    final getClipboard = mockClipboard();
    addTearDown(clearClipboardMock);
    api.relayControlStateResult = '{"relay":"active"}';

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('relay_control_state_copy_button')));
    await tester.pumpAndSettle();

    expect(getClipboard(), '{"relay":"active"}');
  });

  testWidgets('copy button shows system notice after copying', (tester) async {
    mockClipboard();
    addTearDown(clearClipboardMock);
    api.relayControlStateResult = '{"relay":"active"}';

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('relay_control_state_copy_button')));
    await tester.pump();

    expect(find.byType(WnSystemNotice), findsOneWidget);
  });

  group('when offline', () {
    testWidgets('offlineProvider returns true when offline', (tester) async {
      setUpTestView(tester);
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          offlineProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      await tester.pump();
      api.relayControlStateCallCount = 0;

      Routes.pushToRelayControlState(tester.element(find.byType(Scaffold)));
      await tester.pump();
      expect(find.byKey(const Key('offline_notice')), findsOneWidget);
      expect(api.relayControlStateCallCount, 0);
    });

    testWidgets('displays offline notice text', (tester) async {
      setUpTestView(tester);
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          offlineProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      await tester.pump();
      api.relayControlStateCallCount = 0;

      Routes.pushToRelayControlState(tester.element(find.byType(Scaffold)));
      await tester.pump();
      expect(find.text('Waiting for internet connection'), findsOneWidget);
      expect(api.relayControlStateCallCount, 0);
    });

    testWidgets('copy works after going offline with cached dump', (tester) async {
      final getClipboard = mockClipboard();
      addTearDown(clearClipboardMock);
      api.relayControlStateResult = '{"cached":true}';

      final offlineStream = StreamController<bool>();
      addTearDown(offlineStream.close);

      await mountWidget(
        const RelayControlStateScreen(),
        tester,
        overrides: [
          offlineProvider.overrideWith((ref) => offlineStream.stream),
        ],
      );

      offlineStream.add(false);
      await tester.pumpAndSettle();

      offlineStream.add(true);
      await tester.pumpAndSettle();

      final copyButton = tester.widget<WnButton>(
        find.byKey(const Key('relay_control_state_copy_button')),
      );
      expect(copyButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('relay_control_state_copy_button')));
      await tester.pumpAndSettle();

      expect(getClipboard(), '{"cached":true}');
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}
