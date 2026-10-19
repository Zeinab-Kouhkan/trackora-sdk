/// Method by which the attribution was acquired.
enum AttributionMethod {
  /// Acquired through an app store install referrer API (Google Play, Bazaar, Myket).
  storeReferrer('store_referrer'),

  /// Acquired through an iOS Universal Link.
  universalLink('universal_link'),

  /// Acquired through an app custom scheme deep link.
  deepLink('deep_link'),

  /// Acquired from browser URL query parameters in Flutter Web.
  webQueryParam('web_query_param'),

  /// Injected manually or via test harness.
  manual('manual'),

  /// Unknown attribution method.
  unknown('unknown');

  const AttributionMethod(this.identifier);

  final String identifier;

  String toJson() => identifier;

  static AttributionMethod fromJson(String value) {
    return AttributionMethod.values.firstWhere(
      (m) =>
          m.identifier.toLowerCase() == value.toLowerCase() ||
          m.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttributionMethod.unknown,
    );
  }
}
