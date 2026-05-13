import 'package:rust_lib_whitenoise/src/rust/api/utils.dart' as utils_api;

String? npubFromHex(String hexPubkey) {
  try {
    return utils_api.npubFromHexPubkey(hexPubkey: hexPubkey);
  } catch (_) {
    return null;
  }
}

String? hexFromNpub(String npub) {
  try {
    return utils_api.hexPubkeyFromNpub(npub: npub);
  } catch (_) {
    return null;
  }
}
