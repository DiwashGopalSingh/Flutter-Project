/// Application configuration.
/// Set [useMockData] to false after completing Firebase setup
/// (run `flutterfire configure` and add google-services.json).
class AppConfig {
  AppConfig._();

  /// When true, the app uses in-memory mock data and SharedPreferences.
  /// Set to false to connect live to Firebase Authentication and Cloud Firestore.
  static bool useMockData = false;

  /// App environment
  static const String environment = 'development';
}
