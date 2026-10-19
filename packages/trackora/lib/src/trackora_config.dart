/// Configuration options for the Trackora attribution SDK.
class TrackoraConfig {
  /// Default timeout for querying store adapters.
  final Duration timeout;

  /// Whether to cache the resolved attribution in memory.
  final bool enableCache;

  /// Whether to enable verbose debug logging for troubleshooting.
  final bool debugLogging;

  const TrackoraConfig({
    this.timeout = const Duration(seconds: 10),
    this.enableCache = true,
    this.debugLogging = false,
  });
}
