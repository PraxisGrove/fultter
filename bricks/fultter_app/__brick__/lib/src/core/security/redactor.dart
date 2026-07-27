class Redactor {
  static const _redacted = '[REDACTED]';

  static const _sensitiveKeys = {
    'authorization',
    'cookie',
    'password',
    'passcode',
    'token',
    'accesstoken',
    'refreshtoken',
    'apikey',
    'xapikey',
    'clientsecret',
  };

  static final List<RegExp> _patterns = [
    RegExp(
      r'((?:authorization|password|passcode|access[_-]?token|refresh[_-]?token|token|api[_-]?key|x-api-key|client[_-]?secret)"?\s*[:=]\s*"?(?:bearer\s+)?)[^"\s,;}]+',
      caseSensitive: false,
    ),
    RegExp(r'(cookie"?\s*:\s*)[^\n\r,}]+', caseSensitive: false),
  ];

  static String redact(Object? value) {
    var output = value?.toString() ?? '';
    for (final pattern in _patterns) {
      output = output.replaceAllMapped(pattern, (match) {
        return '${match.group(1) ?? ''}$_redacted';
      });
    }
    return output;
  }

  static Map<String, Object?> redactMap(Map<String, Object?> values) {
    return values.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, _redacted);
      }
      return MapEntry(key, redactObject(value));
    });
  }

  static Object? redactObject(Object? value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final redactedValue = _isSensitiveKey(key.toString())
            ? _redacted
            : redactObject(nestedValue);
        return MapEntry(key, redactedValue);
      });
    }
    if (value is Iterable) {
      return value.map(redactObject).toList(growable: false);
    }
    if (value is String) {
      return redact(value);
    }
    if (value == null || value is num || value is bool) {
      return value;
    }
    return redact(value);
  }

  static String redactUri(Uri uri) {
    if (!uri.hasQuery) {
      return redact(uri);
    }

    final queryParameters = uri.queryParametersAll.map((key, values) {
      return MapEntry(
        key,
        _isSensitiveKey(key)
            ? const [_redacted]
            : values.map(redact).toList(growable: false),
      );
    });
    return redact(uri.replace(queryParameters: queryParameters));
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return _sensitiveKeys.contains(normalized);
  }
}
