import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/utils/deep_links.dart';

final deepLinkSchemeProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return deepLinkSchemeForPackageName(info.packageName);
});

String deepLinkSchemeForPackageName(String packageName) {
  if (packageName.endsWith('.staging')) return DeepLinks.stagingScheme;
  return DeepLinks.productionScheme;
}
