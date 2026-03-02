import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_tooltip.dart';

import '../mocks/mock_relay_type.dart';
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  List<Relay> normalRelays = [];
  List<Relay> inboxRelays = [];
  List<Relay> keyPackageRelays = [];
  List<(String, String)> relayStatuses = [];
  List<String> addedRelays = [];
  List<String> removedRelays = [];

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

  @override
  Future<List<(String, String)>> crateApiRelaysGetAccountRelayStatuses({
    required String pubkey,
  }) async {
    return relayStatuses;
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
    mockApi.relayStatuses = [];
    mockApi.addedRelays = [];
    mockApi.removedRelays = [];
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

    testWidgets('displays add icons for each section', (tester) async {
      await pumpNetworkScreen(tester);
      expect(find.byKey(const Key('add_icon_my_relays')), findsOneWidget);
      expect(find.byKey(const Key('add_icon_inbox_relays')), findsOneWidget);
      expect(find.byKey(const Key('add_icon_key_package_relays')), findsOneWidget);
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
        mockApi.relayStatuses = List.generate(
          20,
          (i) => ('wss://relay$i.com', 'connected'),
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
      testWidgets('opens add relay bottom sheet when add icon is tapped', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_icon_my_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add Relay'), findsAtLeastNWidgets(1));
        expect(find.text('Enter relay address'), findsOneWidget);
      });

      testWidgets('opens add relay bottom sheet for inbox relays', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_icon_inbox_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add Relay'), findsAtLeastNWidgets(1));
        expect(find.text('Enter relay address'), findsOneWidget);
      });

      testWidgets('opens add relay bottom sheet for key package relays', (tester) async {
        await pumpNetworkScreen(tester);
        await tester.tap(find.byKey(const Key('add_icon_key_package_relays')));
        await tester.pumpAndSettle();
        expect(find.text('Add Relay'), findsAtLeastNWidgets(1));
        expect(find.text('Enter relay address'), findsOneWidget);
      });

      testWidgets('adds relay when submitted through bottom sheet', (tester) async {
        mockApi.relayStatuses = [('wss://test.relay.com', 'Connected')];

        await pumpNetworkScreen(tester);

        await tester.tap(find.byKey(const Key('add_icon_my_relays')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'wss://test.relay.com');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_relay_submit_button')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        expect(mockApi.addedRelays.contains('wss://test.relay.com'), isTrue);
      });
    });

    group('relay list', () {
      testWidgets('displays relay items when relays exist', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          Relay(url: 'wss://relay2.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];
        mockApi.relayStatuses = [
          ('wss://relay1.com', 'connected'),
          ('wss://relay2.com', 'disconnected'),
        ];

        await pumpNetworkScreen(tester);

        expect(find.text('wss://relay1.com'), findsOneWidget);
        expect(find.text('wss://relay2.com'), findsOneWidget);
        expect(find.text('No relays configured'), findsNWidgets(2));
      });

      testWidgets('shows success icon for connected relays', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];
        mockApi.relayStatuses = [('wss://relay1.com', 'connected')];

        await pumpNetworkScreen(tester);

        expect(find.byKey(const Key('relay_item_normal_wss://relay1.com')), findsOneWidget);
        expect(find.byKey(const Key('list_item_type_icon')), findsOneWidget);
      });

      testWidgets('shows error icon for disconnected relays', (tester) async {
        mockApi.normalRelays = [
          Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];
        mockApi.relayStatuses = [('wss://relay1.com', 'disconnected')];

        await pumpNetworkScreen(tester);

        expect(find.byKey(const Key('relay_item_normal_wss://relay1.com')), findsOneWidget);
        expect(find.byKey(const Key('list_item_type_icon')), findsOneWidget);
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

    group('navigation', () {
      testWidgets('close button is visible', (tester) async {
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
