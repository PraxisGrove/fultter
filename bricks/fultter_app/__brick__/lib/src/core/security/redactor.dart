class Redactor {
  static final List<RegExp> _patterns = [
    RegExp(r'(authorization:\s*bearer\s+)[^\s,;]+', caseSensitive: false),
    RegExp(r'(password\s*[:=]\s*)[^\s,;}]+', caseSensitive: false),
    RegExp(r'(token\s*[:=]\s*)[^\s,;}]+', caseSensitive: false),
    RegExp(r'(cookie:\s*)[^\n\r]+', caseSensitive: false),
    RegExp(r'(x-api-key\s*[:=]\s*)[^\s,;}]+', caseSensitive: false),
  ];

  static String redact(Object? value) {
    var output = value?.toString() ?? '';
    for (final pattern in _patterns) {
      output = output.replaceAllMapped(pattern, (match) {
        return '${match.group(1) ?? ''}[REDACTED]';
      });
    }
    return output;
  }

  static Map<String, Object?> redactMap(Map<String, Object?> values) {
    return values.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(key, value is String ? redact(value) : value);
    });
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'authorization' ||
        normalized == 'cookie' ||
        normalized == 'password' ||
        normalized == 'token' ||
        normalized == 'x-api-key';
  }
}
