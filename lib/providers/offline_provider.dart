import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/src/rust/api/relay_defaults.dart' as relay_defaults;

typedef ReachAnyRelayFunction = Future<bool> Function(List<String> hosts);

List<String> _relayHosts() {
  final relayUrls = relay_defaults.defaultRelayUrls();
  return relayUrls
      .map((url) => Uri.tryParse(url)?.host ?? '')
      .where((host) => host.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

Future<bool> _reachAnyRelayHost(List<String> hosts) async {
  try {
    final futures = hosts.map((host) async {
      final socket = await Socket.connect(host, 443, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    });
    return await Future.any(futures);
  } catch (_) {
    return false;
  }
}

final reachAnyRelayHostFunctionProvider = Provider<ReachAnyRelayFunction>(
  (ref) => _reachAnyRelayHost,
);

final connectivityStreamProvider = Provider<Stream<List<ConnectivityResult>>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final offlineProvider = StreamProvider<bool>((ref) async* {
  final reachAnyRelayHostFunction = ref.watch(reachAnyRelayHostFunctionProvider);
  final connectionStream = ref.watch(connectivityStreamProvider);

  await for (final results in connectionStream) {
    final hasInterface = results.any((result) => result != ConnectivityResult.none);
    if (!hasInterface) {
      yield true;
    } else {
      yield !(await reachAnyRelayHostFunction(_relayHosts()));
    }
  }
});
