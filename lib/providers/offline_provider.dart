import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/src/rust/api/relay_defaults.dart' as relay_defaults;

typedef ReachAnyRelayFunction = Future<bool> Function(List<Uri> relayUrls);
typedef CheckConnectivityFunction = Future<List<ConnectivityResult>> Function();

List<Uri>? _relayUrls() {
  final List<String> relayUrls;
  try {
    relayUrls = relay_defaults.defaultRelayUrls();
  } catch (_) {
    return null;
  }
  return relayUrls
      .map(Uri.tryParse)
      .whereType<Uri>()
      .where((url) => url.host.isNotEmpty)
      .toList(growable: false);
}

int _relayPort(Uri url) {
  if (url.port != 0) return url.port;
  return url.scheme == 'ws' ? 80 : 443;
}

Future<bool> _reachAnyRelayHost(List<Uri> relayUrls) async {
  if (relayUrls.isEmpty) return false;

  final checks = relayUrls.map((url) async {
    try {
      final socket = await Socket.connect(
        url.host,
        _relayPort(url),
        timeout: const Duration(seconds: 3),
      );
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

Future<bool> _tryReachAnyRelay(ReachAnyRelayFunction fn, List<Uri>? relayUrls) async {
  if (relayUrls == null) {
    return true;
  }
  try {
    return await fn(relayUrls);
  } catch (_) {
    return true;
  }
}

final offlineProvider = StreamProvider<bool>((ref) async* {
  final reachAnyRelayHostFunction = ref.watch(reachAnyRelayHostFunctionProvider);
  final checkConnectivity = ref.watch(checkConnectivityFunctionProvider);
  final connectionStream = ref.watch(connectivityStreamProvider);
  final relayUrls = _relayUrls();

  final initialResults = await checkConnectivity();
  if (_isOffline(initialResults)) {
    yield true;
  } else {
    yield !await _tryReachAnyRelay(reachAnyRelayHostFunction, relayUrls);
  }

  await for (final results in connectionStream) {
    if (_isOffline(results)) {
      yield true;
    } else {
      yield !await _tryReachAnyRelay(reachAnyRelayHostFunction, relayUrls);
    }
  }
});
