enum RelayValidationError {
  invalidScheme,
  invalidUrl,
}

RelayValidationError? validateRelayUrl(String url) {
  final trimmed = url.trim();
  if (!trimmed.startsWith('wss://') && !trimmed.startsWith('ws://')) {
    return RelayValidationError.invalidScheme;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    return RelayValidationError.invalidUrl;
  }

  if (uri.host.isEmpty) {
    return RelayValidationError.invalidUrl;
  }

  if (uri.host.contains('wss://') || uri.host.contains('ws://') || uri.host.contains('://')) {
    return RelayValidationError.invalidUrl;
  }

  final hostParts = uri.host.split('.');
  if (hostParts.length < 2 || hostParts.any((part) => part.isEmpty)) {
    return RelayValidationError.invalidUrl;
  }

  return null;
}

bool isRelayUrlEmpty(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty || trimmed == 'wss://' || trimmed == 'ws://';
}
