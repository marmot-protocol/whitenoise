import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/src/rust/api/relay_defaults.dart' as relay_defaults;

typedef ReachAnyRelayFunction = Future<bool> Function(List<String> hosts);
typedef CheckConnectivityFunction = Future<List<ConnectivityResult>> Function();

List<String>? _relayHosts() {
  final List<String> relayUrls;
  try {
    relayUrls = relay_defaults.defaultRelayUrls();
  } catch (_) {
    return null;
  }
  return relayUrls
      .map((url) => Uri.tryParse(url)?.host ?? '')
      .where((host) => host.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

Future<bool> _reachAnyRelayHost(List<String> hosts) async {
  if (hosts.isEmpty) return false;

  final checks = hosts.map((host) async {
    try {
      final socket = await Socket.connect(host, 443, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }).toList();

  await for (final reachable in Stream.fromFutures(checks)) {
    if (reachable) {
      return true;
    }
  }
  return false;
}

final reachAnyRelayHostFunctionProvider = Provider<ReachAnyRelayFunction>(
  (ref) => _reachAnyRelayHost,
);

final connectivityStreamProvider = Provider<Stream<List<ConnectivityResult>>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final checkConnectivityFunctionProvider = Provider<CheckConnectivityFunction>(
  (ref) => Connectivity().checkConnectivity,
);

bool _isOffline(List<ConnectivityResult> results) {
  return !results.any((result) => result != ConnectivityResult.none);
}

Future<bool> _tryReachAnyRelay(ReachAnyRelayFunction fn, List<String>? hosts) async {
  if (hosts == null) {
    return true;
  }
  try {
    return await fn(hosts);
  } catch (_) {
    return true;
  }
}

final offlineProvider = StreamProvider<bool>((ref) async* {
  final reachAnyRelayHostFunction = ref.watch(reachAnyRelayHostFunctionProvider);
  final checkConnectivity = ref.watch(checkConnectivityFunctionProvider);
  final connectionStream = ref.watch(connectivityStreamProvider);
  final hosts = _relayHosts();

  final initialResults = await checkConnectivity();
  if (_isOffline(initialResults)) {
    yield true;
  } else {
    yield !await _tryReachAnyRelay(reachAnyRelayHostFunction, hosts);
  }

  await for (final results in connectionStream) {
    if (_isOffline(results)) {
      yield true;
    } else {
      yield !await _tryReachAnyRelay(reachAnyRelayHostFunction, hosts);
    }
  }
});
