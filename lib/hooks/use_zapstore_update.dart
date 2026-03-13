import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/src/rust/api/zapstore.dart';

({String? availableVersion, bool isDismissed, void Function() dismiss}) useZapstoreUpdate({
  String? simulatedVersion,
}) {
  final isDismissed = useState(false);

  // Reset dismissed state whenever the simulated version changes — this way
  // toggling the dev-settings switch off and back on shows the banner again.
  useEffect(() {
    isDismissed.value = false;
    return null;
  }, [simulatedVersion]);

  final future = useMemoized(
    () async {
      final installed = (await PackageInfo.fromPlatform()).version;
      final latest = simulatedVersion ?? await fetchLatestZapstoreVersion();
      if (latest != null && _isNewer(latest, installed)) {
        return latest;
      }
      return null;
    },
    [simulatedVersion],
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
/// numerically left-to-right; any non-numeric segment falls back to a
/// lexicographic comparison so the hook degrades gracefully if the format
/// ever changes.
bool _isNewer(String candidate, String installed) {
  final c = candidate.split('.');
  final i = installed.split('.');
  final length = c.length > i.length ? c.length : i.length;

  for (var idx = 0; idx < length; idx++) {
    final cv = idx < c.length ? int.tryParse(c[idx]) : 0;
    final iv = idx < i.length ? int.tryParse(i[idx]) : 0;

    if (cv != null && iv != null) {
      if (cv > iv) return true;
      if (cv < iv) return false;
    } else {
      final cs = idx < c.length ? c[idx] : '';
      final is_ = idx < i.length ? i[idx] : '';
      final cmp = cs.compareTo(is_);
      if (cmp > 0) return true;
      if (cmp < 0) return false;
    }
  }

  return false;
}
