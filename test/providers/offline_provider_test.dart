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

  ProviderContainer createContainer({
    required ReachAnyRelayFunction reachAnyRelayHostFunction,
    List<ConnectivityResult> initialConnectivity = const [ConnectivityResult.wifi],
  }) {
    return ProviderContainer(
      overrides: [
        connectivityStreamProvider.overrideWithValue(connectivityController.stream),
        reachAnyRelayHostFunctionProvider.overrideWithValue(reachAnyRelayHostFunction),
        checkConnectivityFunctionProvider.overrideWithValue(() async => initialConnectivity),
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

  group('initial connectivity check', () {
    test('emits true immediately when device is offline at cold start', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => true,
        initialConnectivity: [ConnectivityResult.none],
      );
      final emitted = listenToProvider(container);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, equals([true]));
    });

    test(
      'emits false immediately when device is online and relays reachable at cold start',
      () async {
        final container = createContainer(
          reachAnyRelayHostFunction: (hosts) async => true,
          initialConnectivity: [ConnectivityResult.wifi],
        );
        final emitted = listenToProvider(container);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(emitted, equals([false]));
      },
    );

    test('emits true immediately when online but relays unreachable at cold start', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => false,
        initialConnectivity: [ConnectivityResult.wifi],
      );
      final emitted = listenToProvider(container);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, equals([true]));
    });
  });

  group('connectivity stream events', () {
    test('emits true when no interface is present (reachAnyRelayHost not called)', () async {
      bool reachAnyRelayHostCalled = false;
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async {
          reachAnyRelayHostCalled = true;
          return true;
        },
        initialConnectivity: [ConnectivityResult.wifi],
      );

      final emitted = listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));
      reachAnyRelayHostCalled = false;

      connectivityController.add([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isTrue);
      expect(reachAnyRelayHostCalled, isFalse);
    });

    test('emits false when interface is present and any relay is reachable', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => true,
        initialConnectivity: [ConnectivityResult.none],
      );
      final emitted = listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isFalse);
    });

    test('emits true when interface is present and all relays are unreachable', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => false,
        initialConnectivity: [ConnectivityResult.none],
      );
      final emitted = listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isTrue);
    });

    test('emits true when reachAnyRelayHost throws', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => throw Exception('timeout'),
        initialConnectivity: [ConnectivityResult.none],
      );
      final emitted = listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isTrue);
    });

    test('emits correct sequence on multiple transitions', () async {
      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async => true,
        initialConnectivity: [ConnectivityResult.wifi],
      );
      final emitted = listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 10));

      connectivityController.add([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, equals([false, true, false, true]));
    });

    test('reachAnyRelayHost is called with relay hosts loaded for offline checks', () async {
      List<String> capturedHosts = [];
      mockApi.relayDefaultUrls = [
        'wss://nos.lol',
        'wss://relay.primal.net',
        'wss://relay.damus.io',
      ];

      final container = createContainer(
        reachAnyRelayHostFunction: (hosts) async {
          capturedHosts = hosts;
          return true;
        },
        initialConnectivity: [ConnectivityResult.wifi],
      );

      listenToProvider(container);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(capturedHosts, containsAll(['nos.lol', 'relay.primal.net', 'relay.damus.io']));
      expect(capturedHosts.length, equals(3));
    });
  });
}
