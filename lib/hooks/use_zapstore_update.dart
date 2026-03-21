import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/src/rust/api/zapstore.dart';

({String? availableVersion, bool isDismissed, void Function() dismiss}) useZapstoreUpdate() {
  final isDismissed = useState(false);

  final future = useMemoized(
    () async {
      if (defaultTargetPlatform != TargetPlatform.android) return null;
      final installed = (await PackageInfo.fromPlatform()).version;
      final latest = await fetchLatestZapstoreVersion();
      if (latest != null && _isNewer(latest, installed)) {
        return latest;
      }
      return null;
    },
    [],
  );

  final snapshot = useFuture(future);

  return (
    availableVersion: snapshot.data,
    isDismissed: isDismissed.value,
    dismiss: () {
      isDismissed.value = true;
    },
  );
}

/// Returns true when [candidate] is strictly newer than [installed].
///
/// Both strings use CalVer format (e.g. "2026.3.5"). Segments are compared
/// numerically left-to-right. When both segments parse as integers they are
/// compared numerically. When one parses and the other does not, the numeric
/// segment is considered greater (a well-formed version beats a malformed one).
/// When neither parses, segments are compared lexicographically so the hook
/// degrades gracefully if the format ever changes.
bool _isNewer(String candidate, String installed) {
  final c = candidate.split('.');
  final i = installed.split('.');
  final length = c.length > i.length ? c.length : i.length;

  for (var idx = 0; idx < length; idx++) {
    final cs = idx < c.length ? c[idx] : '';
    final is_ = idx < i.length ? i[idx] : '';
    final cv = int.tryParse(cs);
    final iv = int.tryParse(is_);

    if (cv != null && iv != null) {
      if (cv > iv) return true;
      if (cv < iv) return false;
    } else if (cv != null) {
      // candidate segment is numeric, installed is not — candidate wins
      return true;
    } else if (iv != null) {
      // installed segment is numeric, candidate is not — installed wins
      return false;
    } else {
      final cmp = cs.compareTo(is_);
      if (cmp > 0) return true;
      if (cmp < 0) return false;
    }
  }

  return false;
}
