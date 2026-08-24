import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');
  static const _productionUrl = 'https://vipraseva.mathxmedia.tech/api';

  static String get baseUrl {
    final value = (_overrideUrl.isNotEmpty ? _overrideUrl : _productionUrl).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || (kReleaseMode && uri.scheme != 'https')) {
      throw StateError('Release builds require a valid HTTPS API_BASE_URL');
    }
    if (!kReleaseMode && !const ['http', 'https'].contains(uri.scheme)) {
      throw StateError('API_BASE_URL must use HTTP or HTTPS');
    }
    return value;
  }

  static String mediaUrl(String value) {
    final url = value.trim();
    if (url.isEmpty || url.startsWith('data:')) return url;
    final parsed = Uri.tryParse(url);
    if (parsed?.hasAuthority == true) {
      if (kReleaseMode && parsed!.scheme != 'https') return '';
      return const ['http', 'https'].contains(parsed!.scheme) ? url : '';
    }
    final root = baseUrl;
return url.startsWith('/') ? '$root$url' : '$root/$url';

  }
}