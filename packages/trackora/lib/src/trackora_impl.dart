import 'dart:async';
import 'package:flutter/foundation.dart';

import 'adapter/trackora_store_adapter.dart';
import 'model/attribution_data.dart';
import 'model/attribution_method.dart';
import 'model/attribution_status.dart';
import 'model/trackora_platform.dart';
import 'model/trackora_store.dart';
import 'normalizer/attribution_normalizer.dart';
import 'trackora_config.dart';
import 'web/web_referrer_reader.dart';

/// Main entry point for the Trackora attribution SDK.
class Trackora {
  static Trackora? _instance;

  final List<TrackoraStoreAdapter> _adapters;
  final TrackoraConfig _config;
  final StreamController<AttributionData> _attributionStreamController =
      StreamController<AttributionData>.broadcast();

  AttributionData? _cachedAttribution;

  Trackora._({
    List<TrackoraStoreAdapter> adapters = const [],
    TrackoraConfig config = const TrackoraConfig(),
  })  : _adapters = List.of(adapters),
        _config = config;

  /// Returns the singleton instance of [Trackora].
  ///
  /// Throws a [StateError] if [Trackora.initialize] has not been called.
  static Trackora get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'Trackora has not been initialized. Call `await Trackora.initialize(...)` '
        'in your `main()` before calling `Trackora.instance`.',
      );
    }
    return inst;
  }

  /// Whether Trackora has been initialized.
  static bool get isInitialized => _instance != null;

  /// Initializes the Trackora singleton with the provided store adapters and configuration.
  ///
  /// Store adapters (e.g. `GooglePlayStoreAdapter`, `CafeBazaarStoreAdapter`, `MyketStoreAdapter`)
  /// should be explicitly passed here.
  static Future<Trackora> initialize({
    List<TrackoraStoreAdapter> adapters = const [],
    TrackoraConfig config = const TrackoraConfig(),
  }) async {
    final trackora = Trackora._(adapters: adapters, config: config);
    _instance = trackora;
    return trackora;
  }

  /// Visible for testing: resets the singleton instance.
  @visibleForTesting
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  /// The list of registered store adapters.
  List<TrackoraStoreAdapter> get registeredAdapters =>
      List.unmodifiable(_adapters);

  /// Registers an additional store adapter dynamically.
  void registerAdapter(TrackoraStoreAdapter adapter) {
    if (!_adapters.any((a) => a.store == adapter.store)) {
      _adapters.add(adapter);
      _log('Registered adapter for store: ${adapter.store.identifier}');
    }
  }

  /// Currently cached attribution data, or null if attribution has not been fetched yet.
  AttributionData? get currentAttribution => _cachedAttribution;

  /// Broadcast stream notifying listeners whenever attribution changes.
  Stream<AttributionData> get onAttributionChanged =>
      _attributionStreamController.stream;

  /// Detects the current execution platform.
  TrackoraPlatform get currentPlatform {
    if (kIsWeb) return TrackoraPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return TrackoraPlatform.android;
      case TargetPlatform.iOS:
        return TrackoraPlatform.ios;
      case TargetPlatform.windows:
        return TrackoraPlatform.windows;
      case TargetPlatform.macOS:
        return TrackoraPlatform.macos;
      case TargetPlatform.linux:
        return TrackoraPlatform.linux;
      case TargetPlatform.fuchsia:
        return TrackoraPlatform.fuchsia;
    }
  }

  /// Retrieves the attribution data for the current app install or session.
  ///
  /// - On **Flutter Web**, parses URL parameters (`utm_*`, click IDs) from `window.location.href`.
  /// - On **Android**, queries the registered store adapters in order (Google Play, CafeBazaar, Myket)
  ///   until one resolves with [AttributionStatus.available].
  /// - On **iOS**, App Store install referrers are not exposed by the operating system.
  ///   Attribution is captured through Universal Links or AdAttributionKit.
  ///
  /// Never throws unhandled exceptions; returns [AttributionData] with the appropriate [AttributionStatus].
  Future<AttributionData> getAttribution({
    Duration? timeout,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _config.enableCache && _cachedAttribution != null) {
      _log('Returning cached attribution: ${_cachedAttribution!.status}');
      return _cachedAttribution!;
    }

    final effectiveTimeout = timeout ?? _config.timeout;
    final platform = currentPlatform;

    AttributionData result;

    if (platform == TrackoraPlatform.web) {
      result = _resolveWebAttribution();
    } else if (platform == TrackoraPlatform.android) {
      result = await _resolveAndroidAttribution(effectiveTimeout);
    } else if (platform == TrackoraPlatform.ios) {
      result = _resolveIosAttribution();
    } else {
      result = AttributionData.unsupported(
        platform: platform,
        message:
            'Platform ${platform.name} does not support app store install attribution.',
      );
    }

    if (_config.enableCache && result.status == AttributionStatus.available) {
      _cachedAttribution = result;
    }

    _attributionStreamController.add(result);
    return result;
  }

  /// Normalizes and applies attribution from a deep link or web campaign URL.
  ///
  /// This is useful when the app is launched or resumed via an iOS Universal Link
  /// or an Android custom scheme deep link.
  AttributionData parseUrl(
    Uri uri, {
    AttributionMethod method = AttributionMethod.universalLink,
  }) {
    final result = AttributionNormalizer.fromUri(
      uri,
      platform: currentPlatform,
      method: method,
    );

    if (result.status == AttributionStatus.available) {
      _cachedAttribution = result;
      _attributionStreamController.add(result);
    }

    return result;
  }

  /// Manually injects or updates attribution data (e.g. for testing or custom attribution sources).
  void setAttribution(AttributionData data) {
    _cachedAttribution = data;
    _attributionStreamController.add(data);
  }

  AttributionData _resolveWebAttribution() {
    final webUri = readCurrentWebUri();
    if (webUri == null) {
      return AttributionData.notAvailable(
        platform: TrackoraPlatform.web,
        store: TrackoraStore.web,
        method: AttributionMethod.webQueryParam,
        message: 'Could not read current web browser URI',
      );
    }

    return AttributionNormalizer.fromUri(
      webUri,
      platform: TrackoraPlatform.web,
      store: TrackoraStore.web,
      method: AttributionMethod.webQueryParam,
    );
  }

  Future<AttributionData> _resolveAndroidAttribution(Duration timeout) async {
    if (_adapters.isEmpty) {
      return AttributionData.notAvailable(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.unknown,
        message: 'No Android store adapters registered in Trackora. '
            'Add `trackora_google_play`, `trackora_cafebazaar`, or `trackora_myket` '
            'and pass them to `Trackora.initialize(adapters: [...])`.',
      );
    }

    AttributionData? lastResult;

    for (final adapter in _adapters) {
      _log('Querying store adapter: ${adapter.name}...');
      try {
        final available = await adapter.isAvailable().timeout(
              timeout,
              onTimeout: () => false,
            );

        if (!available) {
          _log('Store adapter ${adapter.name} is not available on this device');
          continue;
        }

        final data = await adapter.fetchAttribution().timeout(
              timeout,
              onTimeout: () => AttributionData.failed(
                platform: TrackoraPlatform.android,
                store: adapter.store,
                error:
                    'Timed out waiting for ${adapter.name} response after ${timeout.inSeconds}s',
              ),
            );

        lastResult = data;
        _log('Store adapter ${adapter.name} result status: ${data.status}');

        if (data.status == AttributionStatus.available) {
          return data;
        }
      } catch (e, stack) {
        _log('Error querying ${adapter.name}: $e\n$stack');
        lastResult = AttributionData.failed(
          platform: TrackoraPlatform.android,
          store: adapter.store,
          error: e.toString(),
        );
      }
    }

    return lastResult ??
        AttributionData.notAvailable(
          platform: TrackoraPlatform.android,
          store: TrackoraStore.unknown,
          message:
              'None of the registered store adapters found attribution data',
        );
  }

  AttributionData _resolveIosAttribution() {
    return AttributionData.notAvailable(
      platform: TrackoraPlatform.ios,
      store: TrackoraStore.appleAppStore,
      method: AttributionMethod.universalLink,
      message: 'iOS App Store does not expose client-side install referrer. '
          'Use `Trackora.instance.parseUrl(uri)` to handle incoming Universal Links '
          'or integrate AdAttributionKit for ad network measurement.',
    );
  }

  void _log(String message) {
    if (_config.debugLogging) {
      debugPrint('[Trackora] $message');
    }
  }

  /// Closes all adapters and streams.
  Future<void> dispose() async {
    for (final adapter in _adapters) {
      await adapter.dispose();
    }
    _adapters.clear();
    await _attributionStreamController.close();
  }
}
