/// Google sign-in configuration, supplied at build time:
///
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web client ID>.apps.googleusercontent.com
///   --dart-define=GOOGLE_IOS_CLIENT_ID=<iOS client ID>.apps.googleusercontent.com   (iOS only)
///
/// The server (web) client ID is the audience of the ID token the backend verifies — it
/// must equal the backend's GOOGLE_CLIENT_ID. Without it the Google button is hidden.
class GoogleConfig {
  GoogleConfig._();

  static const serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get enabled => serverClientId.isNotEmpty;
}
