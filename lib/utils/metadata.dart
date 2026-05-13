import 'dart:convert';

import 'package:rust_lib_whitenoise/src/rust/api/metadata.dart';

String? presentName(FlutterMetadata? metadata) {
  if (metadata == null) return null;
  if (metadata.displayName?.isNotEmpty == true) {
    return sanitizeForDisplay(metadata.displayName!);
  }
  if (metadata.name?.isNotEmpty == true) {
    return sanitizeForDisplay(metadata.name!);
  }
  return null;
}

String sanitizeForDisplay(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if (_isHighSurrogate(code)) {
      if (i + 1 < value.length && _isLowSurrogate(value.codeUnitAt(i + 1))) {
        buffer.writeCharCode(code);
        buffer.writeCharCode(value.codeUnitAt(i + 1));
        i++;
      } else {
        buffer.write('\u{FFFD}');
      }
    } else if (_isLowSurrogate(code)) {
      buffer.write('\u{FFFD}');
    } else {
      buffer.writeCharCode(code);
    }
  }
  final sanitized = buffer.toString();
  return _roundTripUtf8(sanitized);
}

String _roundTripUtf8(String value) {
  try {
    return utf8.decode(utf8.encode(value));
  } catch (_) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '\u{FFFD}');
  }
}

bool _isHighSurrogate(int code) => code >= 0xD800 && code <= 0xDBFF;
bool _isLowSurrogate(int code) => code >= 0xDC00 && code <= 0xDFFF;
