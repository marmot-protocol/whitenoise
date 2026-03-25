import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';

void main() {
  late MockWnApi mockApi;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    connectivityController = StreamController<List<ConnectivityResult>>();
  });

  tearDown(() {
    connectivityController.close();
  });

  ProviderContainer createContainer(ReachAnyRelayFunction reachAnyRelayHostFunction) {
    return ProviderContainer(
      overrides: [
        connectivityStreamProvider.overrideWithValue(connectivityController.stream),
        reachAnyRelayHostFunctionProvider.overrideWithValue(reachAnyRelayHostFunction),
      ],
    );
  }

  List<bool> listenToProvider(ProviderContainer container) {
    final emitted = <bool>[];
    container.listen<AsyncValue<bool>>(
      offlineProvider,
      (prev, next) {
        if (next.hasValue) emitted.add(next.value!);
      },
      fireImmediately: true,
    );
    return emitted;
  }

  test('emits true when no interface is present (reachAnyRelayHost not called)', () async {
    bool reachAnyRelayHostCalled = false;
    final container = createContainer((hosts) async {
      reachAnyRelayHostCalled = true;
      return true;
    });

    final emitted = listenToProvider(container);

    connectivityController.add([ConnectivityResult.none]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(emitted, equals([true]));
    expect(reachAnyRelayHostCalled, isFalse);
  });

  test('emits false when interface is present and any relay is reachable', () async {
    final container = createContainer((hosts) async => true);
    final emitted = listenToProvider(container);

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(emitted, equals([false]));
  });

  test('emits true when interface is present and all relays are unreachable', () async {
    final container = createContainer((hosts) async => false);
    final emitted = listenToProvider(container);

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(emitted, equals([true]));
  });

  test(
    'emits true when interface is present but reachAnyRelayHost throws or times out (returns false)',
    () async {
      final container = createContainer((hosts) async => false);
      final emitted = listenToProvider(container);

      connectivityController.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, equals([true]));
    },
  );

  test('emits correct sequence on multiple transitions', () async {
    final container = createContainer((hosts) async => true);
    final emitted = listenToProvider(container);

    connectivityController.add([ConnectivityResult.none]);
    await Future.delayed(const Duration(milliseconds: 10));

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 10));

    connectivityController.add([ConnectivityResult.none]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(emitted, equals([true, false, true]));
  });

  test('reachAnyRelayHost is called with relay hosts loaded for offline checks', () async {
    List<String> capturedHosts = [];
    mockApi.relayDefaultUrls = [
      'wss://nos.lol',
      'wss://relay.primal.net',
      'wss://relay.damus.io',
    ];

    final container = createContainer((hosts) async {
      capturedHosts = hosts;
      return true;
    });

    listenToProvider(container);

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(capturedHosts, containsAll(['nos.lol', 'relay.primal.net', 'relay.damus.io']));
    expect(capturedHosts.length, equals(3));
  });

  test('returns true (offline) when reachAnyRelayHost returns false for all hosts', () async {
    final container = createContainer((hosts) async => false);
    final emitted = listenToProvider(container);

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(emitted, equals([true]));
  });
}
