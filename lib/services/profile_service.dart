import 'package:logging/logging.dart';
import 'package:rust_lib_whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:rust_lib_whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:rust_lib_whitenoise/src/rust/api/utils.dart' as utils_api;
import 'package:whitenoise/utils/mime_type.dart' show getMimeType;

final _logger = Logger('ProfileService');

class ProfileService {
  final String pubkey;

  const ProfileService(this.pubkey);

  Future<void> setProfile({
    required String displayName,
    String? about,
    String? pictureUrl,
    String? nip05,
  }) async {
    _logger.info('Setting profile (for signup)');
    final metadata = FlutterMetadata(
      displayName: displayName,
      about: about,
      picture: pictureUrl,
      nip05: nip05,
      custom: const {},
    );
    await accounts_api.updateAccountMetadata(pubkey: pubkey, metadata: metadata);
    _logger.info('Profile set successfully');
  }

  Future<String> uploadProfilePicture({
    required String filePath,
  }) async {
    _logger.info('Uploading profile picture');
    final serverUrl = await utils_api.getDefaultBlossomServerUrl();
    final imageType = await getMimeType(filePath);
    if (imageType == null) {
      _logger.warning('Failed to determine image type');
      throw Exception('Failed to get image type');
    }
    final url = await accounts_api.uploadAccountProfilePicture(
      pubkey: pubkey,
      serverUrl: serverUrl,
      filePath: filePath,
      imageType: imageType,
    );
    _logger.info('Profile picture uploaded successfully');
    return url;
  }
}
