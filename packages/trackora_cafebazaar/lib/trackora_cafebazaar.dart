import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:trackora/trackora.dart';

/// Store adapter for CafeBazaar install referrer.
class CafeBazaarStoreAdapter extends TrackoraStoreAdapter {
  final MethodChannel _channel;

  CafeBazaarStoreAdapter({
    @visibleForTesting MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.trackora/cafebazaar');

  @override
  TrackoraStore get store => TrackoraStore.cafebazaar;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AttributionData> fetchAttribution() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AttributionData.unsupported(
        platform: kIsWeb ? TrackoraPlatform.web : TrackoraPlatform.unknown,
        store: store,
        message: 'CafeBazaar adapter is only supported on Android devices.',
      );
    }

    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('fetchReferrer');
      if (response == null) {
        return AttributionData.failed(
          platform: TrackoraPlatform.android,
          store: store,
          error: 'Empty response received from CafeBazaar plugin',
        );
      }

      final status = response['status'] as String?;
      final message = response['message'] as String?;

      switch (status) {
        case 'ok':
          final rawReferrer = response['rawReferrer'] as String?;
          final clickTimestampMs =
              response['referrerClickTimestampMilliseconds'] as int?;
          final installBeginTimestampMs =
              response['installBeginTimestampMilliseconds'] as int?;
          final appVersion = response['appVersion'] as String?;

          final metadata = <String, dynamic>{
            if (clickTimestampMs != null && clickTimestampMs > 0)
              'referrer_click_timestamp_milliseconds': clickTimestampMs,
            if (installBeginTimestampMs != null && installBeginTimestampMs > 0)
              'install_begin_timestamp_milliseconds': installBeginTimestampMs,
            if (appVersion != null && appVersion.isNotEmpty)
              'app_version': appVersion,
          };

          DateTime? timestamp;
          if (clickTimestampMs != null && clickTimestampMs > 0) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(clickTimestampMs,
                isUtc: true);
          }

          return AttributionNormalizer.fromReferrerString(
            rawReferrer: rawReferrer,
            platform: TrackoraPlatform.android,
            store: store,
            method: AttributionMethod.storeReferrer,
            metadata: metadata,
            timestamp: timestamp,
          );

        case 'not_found':
        case 'service_unavailable':
          return AttributionData.notAvailable(
            platform: TrackoraPlatform.android,
            store: store,
            message: message ??
                'CafeBazaar referrer not found or service unavailable',
          );

        case 'timeout':
        default:
          return AttributionData.failed(
            platform: TrackoraPlatform.android,
            store: store,
            error: message ??
                'Failed to retrieve CafeBazaar referrer (status=$status)',
          );
      }
    } on PlatformException catch (e) {
      return AttributionData.failed(
        platform: TrackoraPlatform.android,
        store: store,
        error: '${e.code}: ${e.message}',
      );
    } catch (e) {
      return AttributionData.failed(
        platform: TrackoraPlatform.android,
        store: store,
        error: e.toString(),
      );
    }
  }
}
