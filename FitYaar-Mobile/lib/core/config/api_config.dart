/// Central API configuration.
///
/// Base URL notes (dev backend runs on port 2098):
///   - Android emulator  -> http://10.0.2.2:2098  (10.0.2.2 = host machine)
///   - iOS simulator     -> http://localhost:2098
///   - Physical device   -> http://<your-machine-LAN-IP>:2098
class ApiConfig {
  const ApiConfig._();

  /// Override at build time with: --dart-define=API_BASE_URL=http://192.168.x.x:2098
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:2098',
  );

  static const String apiPrefix = '/api';

  /// Web app base (Razorpay checkout, marketing). Override with
  /// --dart-define=WEB_BASE_URL=https://app.fityaar.com
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://app.fityaar.com',
  );
}
