import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_network_relays.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_relay_type.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class MockApi extends MockWnApi {
  List<Relay> normalRelays = [];
  List<Relay> inboxRelays = [];
  List<Relay> keyPackageRelays = [];
  bool shouldThrow = false;

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
    if (shouldThrow) throw Exception('Network error');
    final mockType = relayType as MockRelayType;
    switch (mockType.type) {
      case 'nip65':
        return normalRelays;
      case 'inbox':
        return inboxRelays;
      case 'keyPackage':
        return keyPackageRelays;
      default:
        return [];
    }
  }

  @override
  Future<void> crateApiAccountsAddAccountRelay({
    required String pubkey,
    required String url,
    required RelayType relayType,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    final relay = Relay(
      url: url,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final mockType = relayType as MockRelayType;
    switch (mockType.type) {
      case 'nip65':
        normalRelays.add(relay);
        break;
      case 'inbox':
        inboxRelays.add(relay);
        break;
      case 'keyPackage':
        keyPackageRelays.add(relay);
        break;
    }
  }

  @override
  Future<void> crateApiAccountsRemoveAccountRelay({
    required String pubkey,
    required String url,
    required RelayType relayType,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    final mockType = relayType as MockRelayType;
    switch (mockType.type) {
      case 'nip65':
        normalRelays.removeWhere((r) => r.url == url);
        break;
      case 'inbox':
        inboxRelays.removeWhere((r) => r.url == url);
        break;
      case 'keyPackage':
        keyPackageRelays.removeWhere((r) => r.url == url);
        break;
    }
  }
}

late MockApi mockApi;

void main() {
  setUpAll(() {
    mockApi = MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.normalRelays = [];
    mockApi.inboxRelays = [];
    mockApi.keyPackageRelays = [];
    mockApi.shouldThrow = false;
  });

  group('RelayListState', () {
    test('copyWith preserves values when not provided', () {
      const state = RelayListState(isLoading: true);
      final newState = state.copyWith(relays: []);

      expect(newState.isLoading, isTrue);
      expect(newState.relays, isEmpty);
    });

    test('copyWith clears error when clearError is true', () {
      const state = RelayListState(error: 'Some error');
      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
    });
  });

  group('NetworkRelaysState', () {
    test('copyWith preserves values when not provided', () {
      const state = NetworkRelaysState(isAddingRelay: true);
      final newState = state.copyWith();

      expect(newState.isAddingRelay, isTrue);
    });

    test('copyWith preserves isRemovingRelay when not provided', () {
      const state = NetworkRelaysState(isRemovingRelay: true);
      final newState = state.copyWith();

      expect(newState.isRemovingRelay, isTrue);
    });

    test('updateCategory updates specific category', () {
      const state = NetworkRelaysState();
      final newState = state.updateCategory(
        RelayCategory.normal,
        const RelayListState(isLoading: true),
      );

      expect(newState.normalRelays.isLoading, isTrue);
      expect(newState.inboxRelays.isLoading, isFalse);
      expect(newState.keyPackageRelays.isLoading, isFalse);
    });

    test('getCategory returns correct state', () {
      const state = NetworkRelaysState(
        categoryStates: {
          RelayCategory.normal: RelayListState(isLoading: true),
        },
      );

      expect(state.getCategory(RelayCategory.normal).isLoading, isTrue);
      expect(state.getCategory(RelayCategory.inbox).isLoading, isFalse);
    });

    test('normalRelays getter returns correct state', () {
      const state = NetworkRelaysState(
        categoryStates: {
          RelayCategory.normal: RelayListState(isLoading: true),
        },
      );

      expect(state.normalRelays.isLoading, isTrue);
    });

    test('inboxRelays getter returns correct state', () {
      const state = NetworkRelaysState(
        categoryStates: {
          RelayCategory.inbox: RelayListState(isLoading: true),
        },
      );

      expect(state.inboxRelays.isLoading, isTrue);
    });

    test('keyPackageRelays getter returns correct state', () {
      const state = NetworkRelaysState(
        categoryStates: {
          RelayCategory.keyPackage: RelayListState(isLoading: true),
        },
      );

      expect(state.keyPackageRelays.isLoading, isTrue);
    });
  });

  group('fetchAll', () {
    testWidgets('loads all relay types', (tester) async {
      mockApi.normalRelays = [
        Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      mockApi.inboxRelays = [
        Relay(url: 'wss://inbox1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      mockApi.keyPackageRelays = [
        Relay(url: 'wss://keypackage1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 1);
      expect(getHook().state.inboxRelays.relays.length, 1);
      expect(getHook().state.keyPackageRelays.relays.length, 1);
    });

    testWidgets('sets error on failure for normal relays', (tester) async {
      mockApi.shouldThrow = true;

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      expect(getHook().state.normalRelays.error, isNotNull);
    });
  });

  group('addRelay', () {
    testWidgets('adds relay to normal relays', (tester) async {
      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().addRelay('wss://newrelay.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 1);
      expect(getHook().state.normalRelays.relays.first.url, 'wss://newrelay.com');
    });

    testWidgets('adds relay to inbox relays', (tester) async {
      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().addRelay('wss://newinbox.com', RelayCategory.inbox);
      await tester.pump();

      expect(getHook().state.inboxRelays.relays.length, 1);
      expect(getHook().state.inboxRelays.relays.first.url, 'wss://newinbox.com');
    });

    testWidgets('adds relay to key package relays', (tester) async {
      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().addRelay('wss://newkeypackage.com', RelayCategory.keyPackage);
      await tester.pump();

      expect(getHook().state.keyPackageRelays.relays.length, 1);
      expect(getHook().state.keyPackageRelays.relays.first.url, 'wss://newkeypackage.com');
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().addRelay('wss://newrelay.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.error, isNotNull);
    });

    testWidgets('does not add relay when already adding', (tester) async {
      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));

      getHook().addRelay('wss://relay1.com', RelayCategory.normal);
      await getHook().addRelay('wss://relay2.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 1);
    });
  });

  group('removeRelay', () {
    testWidgets('removes relay from normal relays', (tester) async {
      mockApi.normalRelays = [
        Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 1);

      await getHook().removeRelay('wss://relay1.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.relays, isEmpty);
    });

    testWidgets('removes relay from inbox relays', (tester) async {
      mockApi.inboxRelays = [
        Relay(url: 'wss://inbox1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      expect(getHook().state.inboxRelays.relays.length, 1);

      await getHook().removeRelay('wss://inbox1.com', RelayCategory.inbox);
      await tester.pump();

      expect(getHook().state.inboxRelays.relays, isEmpty);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.normalRelays = [
        Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      mockApi.shouldThrow = true;
      await getHook().removeRelay('wss://relay1.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.error, isNotNull);
    });

    testWidgets('does not remove relay when already removing', (tester) async {
      mockApi.normalRelays = [
        Relay(url: 'wss://relay1.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Relay(url: 'wss://relay2.com', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final getHook = await mountHook(tester, () => useNetworkRelays(testPubkeyA));
      await getHook().fetchAll();
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 2);

      getHook().removeRelay('wss://relay1.com', RelayCategory.normal);
      await getHook().removeRelay('wss://relay2.com', RelayCategory.normal);
      await tester.pump();

      expect(getHook().state.normalRelays.relays.length, 1);
    });
  });
}
