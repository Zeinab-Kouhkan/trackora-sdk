/// Status of an attribution resolution attempt.
enum AttributionStatus {
  /// Attribution data was successfully found and parsed.
  available,

  /// The check completed successfully, but no attribution/referrer record exists
  /// (e.g., organic install without referrer data).
  notAvailable,

  /// Attribution data resolution is currently pending.
  pending,

  /// The platform, store, or environment does not support install referrer
  /// or attribution retrieval.
  unsupported,

  /// An error occurred while retrieving or parsing attribution data.
  failed;

  /// Returns the string name of the status.
  String toJson() => name;

  /// Parses a status from its string name.
  static AttributionStatus fromJson(String value) {
    return AttributionStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttributionStatus.failed,
    );
  }
}
