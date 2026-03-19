import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/screens/relay_control_state_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard;
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

    expect(find.byKey(const Key('relay_control_state_error')), findsOneWidget);
    expect(find.textContaining('Failed to load relay control state'), findsOneWidget);
  });

  testWidgets('copy button is disabled before a result is loaded', (tester) async {
    api.shouldFailRelayControlState = true;

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    final copyButton = tester.widget<TextButton>(
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

  testWidgets('copy button shows snackbar after copying', (tester) async {
    mockClipboard();
    addTearDown(clearClipboardMock);
    api.relayControlStateResult = '{"relay":"active"}';

    await mountWidget(const RelayControlStateScreen(), tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('relay_control_state_copy_button')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
