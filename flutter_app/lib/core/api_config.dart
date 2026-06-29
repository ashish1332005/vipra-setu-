class ApiConfig {
  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');
  static const _productionUrl = 'https://vipra-setu.onrender.com/api';

  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) return _overrideUrl;
    return _productionUrl;
  }

  static String mediaUrl(String value) {
    final url = value.trim();
    if (url.isEmpty || url.startsWith('http') || url.startsWith('data:')) {
      return url;
    }
    final root = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    return url.startsWith('/') ? '$root$url' : '$root/$url';
  }
}
