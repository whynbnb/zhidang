/// User-facing app version. Keep in sync with `pubspec.yaml`.
const appVersion = '0.13.0';

/// The UI only shows major.minor, even if the stored version has a patch or
/// build suffix.
String displayVersion(String version) {
  final parts = version.split('+').first.split('.');
  return parts.take(2).join('.');
}
