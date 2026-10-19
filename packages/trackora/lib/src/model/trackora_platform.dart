/// Supported platforms for attribution detection.
enum TrackoraPlatform {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
  fuchsia,
  unknown;

  /// Returns the string representation.
  String toJson() => name;

  /// Parses from a string value.
  static TrackoraPlatform fromJson(String value) {
    return TrackoraPlatform.values.firstWhere(
      (p) => p.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TrackoraPlatform.unknown,
    );
  }
}
