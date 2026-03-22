class BuildConfig {
  static const int versionCode = int.fromEnvironment(
    'app.code',
    defaultValue: 1,
  );
  static const String versionName = String.fromEnvironment(
    'app.name',
    defaultValue: 'SNAPSHOT',
  );
  static const String versionTag = String.fromEnvironment(
    'app.tag',
    defaultValue: versionName,
  );
  static const int buildTime = int.fromEnvironment('app.time');
  static const String commitHash = String.fromEnvironment(
    'app.hash',
    defaultValue: 'N/A',
  );
}
