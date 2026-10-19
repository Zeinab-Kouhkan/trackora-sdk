import '../model/attribution_data.dart';
import '../model/trackora_store.dart';

/// Contract interface that all store-specific attribution adapters must implement.
///
/// Store adapters (e.g., `trackora_google_play`, `trackora_cafebazaar`, `trackora_myket`)
/// communicate with native store APIs on Android and normalize the returned data into [AttributionData].
abstract class TrackoraStoreAdapter {
  const TrackoraStoreAdapter();

  /// Identifies the app store targeted by this adapter.
  TrackoraStore get store;

  /// Human-readable name or identifier of this adapter.
  String get name => store.identifier;

  /// Checks whether this store integration is supported and available on the current device.
  ///
  /// For instance, checks if the store app (Google Play, Bazaar, or Myket) is installed
  /// and exposes the referrer service.
  Future<bool> isAvailable();

  /// Connects to the store referrer API, retrieves the install referrer data,
  /// and normalizes it into [AttributionData].
  ///
  /// This method must handle store-specific errors gracefully and return an [AttributionData]
  /// with [AttributionStatus.notAvailable], [AttributionStatus.unsupported], or [AttributionStatus.failed]
  /// instead of throwing unhandled exceptions.
  Future<AttributionData> fetchAttribution();

  /// Cleans up any resources or background connections held by this adapter.
  Future<void> dispose() async {}
}
