/// Supported app stores and origin sources for attribution.
enum TrackoraStore {
  /// Google Play Store
  googlePlay('google_play'),

  /// CafeBazaar App Store
  cafebazaar('cafebazaar'),

  /// Myket App Store
  myket('myket'),

  /// Apple App Store
  appleAppStore('apple_app_store'),

  /// Web browser origin
  web('web'),

  /// Unknown or unrecognized store
  unknown('unknown');

  const TrackoraStore(this.identifier);

  /// Standard string identifier.
  final String identifier;

  /// Serializes to JSON string.
  String toJson() => identifier;

  /// Parses from standard string identifier.
  static TrackoraStore fromJson(String value) {
    return TrackoraStore.values.firstWhere(
      (s) =>
          s.identifier.toLowerCase() == value.toLowerCase() ||
          s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TrackoraStore.unknown,
    );
  }
}
