import 'package:whitenoise/utils/encoding.dart' show hexFromNpub;

enum DeepLinkTargetType { user, chat, settings }

class DeepLinkTarget {
  const DeepLinkTarget({
    required this.type,
    required this.location,
  });

  final DeepLinkTargetType type;
  final String location;
}

abstract final class DeepLinks {
  static const productionScheme = 'whitenoise';
  static const stagingScheme = 'whitenoise-staging';

  static const _settingsLocations = {
    'settings': '/settings',
    'settings/share-profile': '/share-profile',
    'settings/switch-profile': '/switch-profile',
    'settings/edit-profile': '/edit-profile',
    'settings/profile-keys': '/profile-keys',
    'settings/network': '/network',
    'settings/privacy-security': '/privacy-security',
    'settings/appearance': '/appearance',
    'settings/notifications': '/notification-settings',
    'settings/report-bug': '/report-bug',
    'settings/donate': '/donate',
    'settings/developer': '/developer-settings',
    'settings/developer/key-packages': '/key-package-management',
    'settings/developer/relay-state': '/relay-control-state',
    'settings/developer/app-logs': '/app-logs',
  };

  static String userUri(String npub, {String scheme = productionScheme}) {
    return Uri(scheme: scheme, host: 'user', pathSegments: [npub]).toString();
  }

  static String chatUri(String groupId, {String scheme = productionScheme}) {
    return Uri(scheme: scheme, host: 'chat', pathSegments: [groupId]).toString();
  }

  static DeepLinkTarget? parse(Uri uri) {
    if (!_isSupportedScheme(uri.scheme)) return null;

    final segments = _segments(uri);
    if (segments.isEmpty) return null;

    return switch (segments.first.toLowerCase()) {
      'user' => _parseUser(segments),
      'chat' => _parseChat(segments),
      'settings' => _parseSettings(segments),
      _ => null,
    };
  }

  static DeepLinkTarget? parseString(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;
    return parse(uri);
  }

  static bool _isSupportedScheme(String scheme) {
    return scheme == productionScheme || scheme == stagingScheme;
  }

  static List<String> _segments(Uri uri) {
    return [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((segment) => segment.isNotEmpty).toList(growable: false);
  }

  static DeepLinkTarget? _parseUser(List<String> segments) {
    if (segments.length != 2) return null;

    final pubkey = hexFromNpub(segments[1]);
    if (pubkey == null) return null;

    return DeepLinkTarget(
      type: DeepLinkTargetType.user,
      location: '/start-chat/${Uri.encodeComponent(pubkey)}',
    );
  }

  static DeepLinkTarget? _parseChat(List<String> segments) {
    if (segments.length != 2) return null;

    final groupId = segments[1];
    if (groupId.isEmpty) return null;

    return DeepLinkTarget(
      type: DeepLinkTargetType.chat,
      location: '/chats/${Uri.encodeComponent(groupId)}',
    );
  }

  static DeepLinkTarget? _parseSettings(List<String> segments) {
    final location = _settingsLocations[segments.join('/')];
    if (location == null) return null;

    return DeepLinkTarget(
      type: DeepLinkTargetType.settings,
      location: location,
    );
  }
}
