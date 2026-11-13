/// App-wide configuration.
///
/// The backend base URL can be overridden at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://ward.crlx1q.com
class AppConfig {
  /// Default points at the production domain. Requests append `/api/...`,
  /// so this must NOT include a trailing `/api`.
  /// For local development pass:
  ///   --dart-define=API_BASE_URL=http://10.0.2.2:4000  (Android emulator)
  ///   --dart-define=API_BASE_URL=http://localhost:4000 (iOS sim / desktop / web)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://capsule.crlx1q.com',
  );

  static const String appName = 'Capsule';

  /// Resolves an image URL returned by the API. The backend returns relative
  /// paths (e.g. /api/images/:id); we prefix them with the API base URL so the
  /// same data works on emulator, device and production without a mismatch.
  static String resolveUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }
}
