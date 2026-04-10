import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show RelayType;
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_tooltip.dart';

import '../mocks/mock_relay_type.dart';
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  List<Relay> normalRelays = [];
  List<Relay> inboxRelays = [];
  List<Relay> keyPackageRelays = [];
  List<String> addedRelays = [];
  List<String> removedRelays = [];
  bool restoreDefaultRelaysCalled = false;
  bool shouldThrowOnRestore = false;

  @override
  Future<void> crateApiAccountsRestoreDefaultRelays({required String pubkey}) async {
    if (shouldThrowOnRestore) throw Exception('Restore error');
    restoreDefaultRelaysCalled = true;
    normalRelays = [];
    inboxRelays = [];
    keyPackageRelays = [];
  }

  @override
  Future<RelayType> crateApiRelaysRelayTypeNip65() async => MockRelayType('nip65');

  @override
  Future<RelayType> crateApiRelaysRelayTypeInbox() async => MockRelayType('inbox');

  @override
  Future<RelayType> crateApiRelaysRelayTypeKeyPackage() async => MockRelayType('keyPackage');

  @override
  Future<List<Relay>> crateApiAccountsAccountRelays({
    required String pubkey,
    required RelayType relayType,
  }) async {
    final type = (relayType as MockRelayType).type;
    if (type == 'nip65') return normalRelays;
    if (type == 'inbox') return inboxRelays;
    if (type == 'keyPackage') return keyPackageRelays;
    return [];
  }

  @override
  Future<void> crateApiAccountsAddAccountRelay({
    required String pubkey,
    required String url,
    required RelayType relayType,
  }) async {
    addedRelays.add(url);
    final relay = Relay(url: url, createdAt: DateTime.now(), updatedAt: DateTime.now());
    final type = (relayType as MockRelayType).type;
    if (type == 'nip65') normalRelays.add(relay);
    if (type == 'inbox') inboxRelays.add(relay);
    if (type == 'keyPackage') keyPackageRelays.add(relay);
  }

  @override
  Future<void> crateApiAccountsRemoveAccountRelay({
    required String pubkey,
    required String url,
    required RelayType relayType,
  }) async {
    removedRelays.add(url);
    final type = (relayType as MockRelayType).type;
    if (type == 'nip65') normalRelays.removeWhere((r) => r.url == url);
    if (type == 'inbox') inboxRelays.removeWhere((r) => r.url == url);
    if (type == 'keyPackage') keyPackageRelays.removeWhere((r) => r.url == url);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.normalRelays = [];
    mockApi.inboxRelays = [];
    mockApi.keyPackageRelays = [];
    mockApi.addedRelays = [];
    mockApi.removedRelays = [];
    mockApi.restoreDefaultRelaysCalled = false;
    mockApi.shouldThrowOnRestore = false;
  });

  Future<void> pumpNetworkScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToNetwork(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('NetworkScreen', () {
    testWidgets('displays Network Relays title', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('Network Relays'), findsOneWidget);
    });

    testWidgets('displays My Relays section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('My Relays'), findsOneWidget);
    });

    testWidgets('displays Inbox Relays section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('Inbox Relays'), findsOneWidget);
    });

    testWidgets('displays Key Package Relays section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('Key Package Relays'), findsOneWidget);
    });

    testWidgets('displays info icons for each section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.byKey(const Key('info_icon_my_relays')), findsOneWidget);
      expect(find.byKey(const Key('info_icon_inbox_relays')), findsOneWidget);
      expect(find.byKey(const Key('info_icon_key_package_relays')), findsOneWidget);
    });

    testWidgets('displays add buttons for each section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.byKey(const Key('add_button_my_relays')), findsOneWidget);
      expect(find.byKey(const Key('add_button_inbox_relays')), findsOneWidget);
      expect(find.byKey(const Key('add_button_key_package_relays')), findsOneWidget);
    });

    testWidgets('displays add button labels', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('Add my relay'), findsOneWidget);
      expect(find.text('Add inbox relay'), findsOneWidget);
      expect(find.text('Add key package relay'), findsOneWidget);
    });

    testWidgets('displays "No relays configured" for empty sections', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.text('No relays configured'), findsNWidgets(3));
    });

    group('tooltip', () {
      testWidgets('My Relays section has tooltip with correct message', (tester) async {
        await pumpNetworkScreen(tester);
        final tooltipFinder = find.ancestor(
          of: find.byKey(const Key('info_icon_my_relays')),
          matching: find.byType(WnTooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        final tooltip = tester.widget<WnTooltip>(tooltipFinder);
        expect(
          tooltip.message,
          'Relays you have defined for use across all your Nostr applications.',
        );
      });

      testWidgets('Inbox Relays section has tooltip with correct message', (tester) async {
        await pumpNetworkScreen(tester);
        final tooltipFinder = find.ancestor(
          of: find.byKey(const Key('info_icon_inbox_relays')),
          matching: find.byType(WnTooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        final tooltip = tester.widget<WnTooltip>(tooltipFinder);
        expect(
          tooltip.message,
          'Relays used to receive invitations and start secure conversations with new users.',
        );
      });

      testWidgets('Key Package Relays section has tooltip with correct message', (tester) async {
        await pumpNetworkScreen(tester);
        final tooltipFinder = find.ancestor(
          of: find.byKey(const Key('info_icon_key_package_relays')),
          matching: find.byType(WnTooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        final tooltip = tester.widget<WnTooltip>(tooltipFinder);
        expect(
          tooltip.message,
          'Relays that store your secure key so others can invite you to encrypted conversations.',
        );
      });

      testWidgets('first tooltip uses bottom position, others use top', (tester) async {
        await pumpNetworkScreen(tester);

        final myRelaysTooltip = tester.widget<WnTooltip>(
          find.ancestor(
            of: find.byKey(const Key('info_icon_my_relays')),
            matching: find.byType(WnTooltip),
          ),
        );
        expect(myRelaysTooltip.position, WnTooltipPosition.bottom);

        final inboxRelaysTooltip = tester.widget<WnTooltip>(
          find.ancestor(
            of: find.byKey(const Key('info_icon_inbox_relays')),
            matching: find.byType(WnTooltip),
          ),
        );
        expect(inboxRelaysTooltip.position, WnTooltipPosition.top);

        final keyPackageRelaysTooltip = tester.widget<WnTooltip>(
          find.ancestor(
            of: find.byKey(const Key('info_icon_key_package_relays')),
            matching: find.byType(WnTooltip),
          ),
        );
        expect(keyPackageRelaysTooltip.position, WnTooltipPosition.top);
      });

      testWidgets('all tooltips use tap trigger mode', (tester) async {
        await pumpNetworkScreen(tester);
        final tooltips = tester.widgetList<WnTooltip>(find.byType(WnTooltip));
        for (final tooltip in tooltips) {
          expect(tooltip.triggerMode, WnTooltipTriggerMode.tap);
        }
      });
    });

    group('scroll behavior', () {
      testWidgets('collapses list items when scrolling starts', (tester) async {
        mockApi.normalRelays = List.generate(
          20,
          (i) => Relay(
            url: 'wss://relay$i.com',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await pumpNetworkScreen(tester);

        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);

        await tester.drag(listView, const Offset(0, -200));
        await tester.pump();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('add relay', () {
      testWidgets('navigates to add relay screen when add button is tapped', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_button_my_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add my relay'), findsOneWidget);
        expect(find.text('Relay address'), findsOneWidget);
      });

      testWidgets('navigates to add relay screen for inbox relays', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_button_inbox_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add inbox relay'), findsOneWidget);
        expect(find.text('Relay address'), findsOneWidget);
      });

      testWidgets('navigates to add relay screen for key package relays', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_button_key_package_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add key package relay'), findsOneWidget);
        expect(find.text('Relay address'), findsOneWidget);
      });

      testWidgets('adds relay when submitted through add relay screen', (tester) async {
        await pumpNetworkScreen(tester);

        await tester.tap(find.byKey(const Key('add_button_my_relays')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'wss://test.relay.com');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_relay_submit_button')));
        await tester.pumpAndSettle();

        expect(mockApi.addedRelays.contains('wss://test.relay.com'), isTrue);
      });
    });

    group('relay list', () {
      testWidgets('displays relay items when relays exist', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          Relay(url: 'wss://relay2.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];

        await pumpNetworkScreen(tester);

        expect(find.text('wss://relay1.com'), findsOneWidget);
        expect(find.text('wss://relay2.com'), findsOneWidget);
        expect(find.text('No relays configured'), findsNWidgets(2));
      });

      testWidgets('does not show status icons for relay items', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];

        await pumpNetworkScreen(tester);

        expect(find.byKey(const Key('relay_item_normal_wss://relay1.com')), findsOneWidget);
        expect(find.byKey(const Key('list_item_type_icon')), findsNothing);
      });

      testWidgets('removes relay when Remove action is tapped', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];

        await pumpNetworkScreen(tester);

        expect(find.text('wss://relay1.com'), findsOneWidget);

        await tester.tap(find.byKey(const Key('list_item_menu_button')).first);
        await tester.pump();

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(mockApi.removedRelays.contains('wss://relay1.com'), isTrue);
      });
    });

    group('restore default relays', () {
      testWidgets('displays restore default relays button', (tester) async {
        await pumpNetworkScreen(tester);
        expect(find.byKey(const Key('restore_default_relays_button')), findsOneWidget);
        expect(find.text('Restore default relays'), findsOneWidget);
      });

      testWidgets('restore button is primary type', (tester) async {
        await pumpNetworkScreen(tester);
        final button = tester.widget<WnButton>(
          find.byKey(const Key('restore_default_relays_button')),
        );
        expect(button.type, WnButtonType.primary);
      });

      testWidgets('tapping restore button shows confirmation modal', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.text('Restore default relays?'), findsOneWidget);
        expect(
          find.text(
            "Are you sure you want to restore the app's default relays? This will erase and replace your current relays.",
          ),
          findsOneWidget,
        );
      });

      testWidgets('confirmation modal has Cancel and Restore relays buttons', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byKey(const Key('confirm_button')), findsOneWidget);
      });

      testWidgets('confirm button is destructive type', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
        expect(confirmButton.type, WnButtonType.destructive);
      });

      testWidgets('cancelling confirmation dismisses the modal', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Restore default relays?'), findsNothing);
      });

      testWidgets('confirming calls restoreDefaultRelays and dismisses modal', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pumpAndSettle();
        expect(mockApi.restoreDefaultRelaysCalled, isTrue);
        expect(find.text('Restore default relays?'), findsNothing);
      });

      testWidgets('shows error notice when restore fails', (tester) async {
        mockApi.shouldThrowOnRestore = true;

        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('restore_default_relays_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pumpAndSettle();

        expect(mockApi.restoreDefaultRelaysCalled, isFalse);
        expect(
          find.text('Failed to restore default relays. Please try again.'),
          findsOneWidget,
        );
      });
    });

    group('navigation', () {
      testWidgets('back button is visible', (tester) async {
        await pumpNetworkScreen(tester);

        expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
      });

      testWidgets('back button pops the screen', (tester) async {
        await pumpNetworkScreen(tester);

        expect(find.text('Network Relays'), findsOneWidget);

        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();

        expect(find.text('Network Relays'), findsNothing);
      });
    });
  });
}
