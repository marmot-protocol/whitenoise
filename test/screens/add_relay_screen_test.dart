import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_network_relays.dart' show RelayCategory;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

late _MockApi _mockApi;

void main() {
  setUpAll(() {
    _mockApi = _MockApi();
    RustLib.initMock(api: _mockApi);
  });

  Future<void> pumpAddRelayScreen(
    WidgetTester tester,
    RelayCategory category, {
    Future<void> Function(String)? onRelayAdded,
  }) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToAddRelay(
      tester.element(find.byType(Scaffold)),
      category: category,
      onRelayAdded: onRelayAdded ?? (_) async {},
    );
    await tester.pumpAndSettle();
  }

  group('AddRelayScreen', () {
    group('title', () {
      testWidgets('shows "Add my relay" title for normal category', (tester) async {
        await pumpAddRelayScreen(tester, RelayCategory.normal);
        expect(find.text('Add my relay'), findsOneWidget);
      });

      testWidgets('shows "Add inbox relay" title for inbox category', (tester) async {
        await pumpAddRelayScreen(tester, RelayCategory.inbox);
        expect(find.text('Add inbox relay'), findsOneWidget);
      });

      testWidgets('shows "Add key package relay" title for keyPackage category', (tester) async {
        await pumpAddRelayScreen(tester, RelayCategory.keyPackage);
        expect(find.text('Add key package relay'), findsOneWidget);
      });
    });

    testWidgets('displays relay address input', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);
      expect(find.text('Relay address'), findsOneWidget);
    });

    testWidgets('displays add relay submit button', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);
      expect(find.byKey(const Key('add_relay_submit_button')), findsOneWidget);
    });

    testWidgets('submit button is medium size', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);
      final button = tester.widget<WnButton>(
        find.byKey(const Key('add_relay_submit_button')),
      );
      expect(button.size, WnButtonSize.medium);
    });

    testWidgets('submit button is disabled when input is empty', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);
      final button = tester.widget<WnButton>(
        find.byKey(const Key('add_relay_submit_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('back button navigates back', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);
      expect(find.text('Add my relay'), findsOneWidget);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('calls onRelayAdded and navigates back when valid relay is submitted', (
      tester,
    ) async {
      String? addedRelay;
      await pumpAddRelayScreen(
        tester,
        RelayCategory.normal,
        onRelayAdded: (url) async => addedRelay = url,
      );

      await tester.enterText(find.byType(TextField), 'wss://test.relay.com');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_relay_submit_button')));
      await tester.pumpAndSettle();

      expect(addedRelay, equals('wss://test.relay.com'));
    });

    testWidgets('shows scheme error when URL has wrong scheme', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);

      await tester.enterText(find.byType(TextField), 'http://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('URL must start with wss:// or ws://'), findsOneWidget);
    });

    testWidgets('shows invalid URL error when URL has no valid host', (tester) async {
      await pumpAddRelayScreen(tester, RelayCategory.normal);

      await tester.enterText(find.byType(TextField), 'wss://relay');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Invalid relay URL'), findsOneWidget);
    });
  });
}
