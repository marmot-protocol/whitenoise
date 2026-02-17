String? validateRelayUrl(String url) {
  if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
    return 'URL must start with wss:// or ws://';
  }

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    return 'Invalid relay URL';
  }

  if (uri.host.isEmpty) {
    return 'Invalid relay URL';
  }

  if (uri.host.contains('wss://') || uri.host.contains('ws://') || uri.host.contains('://')) {
    return 'Invalid relay URL';
  }

  final hostParts = uri.host.split('.');
  if (hostParts.length < 2 || hostParts.any((part) => part.isEmpty)) {
    return 'Invalid relay URL';
  }

  return null;
}

bool isRelayUrlEmpty(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty || trimmed == 'wss://' || trimmed == 'ws://';
}
