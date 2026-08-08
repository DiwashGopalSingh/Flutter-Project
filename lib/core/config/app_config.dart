/// Application configuration.
/// Set [useMockData] to false after completing Firebase setup
/// (run `flutterfire configure` and add google-services.json).
class AppConfig {
  AppConfig._();

  /// When true, the app uses in-memory mock data and SharedPreferences
  /// for authentication — no Firebase connection required.
  ///
  /// Set to false after completing Firebase setup.
  static bool useMockData = false;

  /// App environment
  static const String environment = 'development';
}
