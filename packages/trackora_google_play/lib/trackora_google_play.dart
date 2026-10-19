import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:trackora/trackora.dart';

/// Store adapter for Google Play Store install referrer.
class GooglePlayStoreAdapter extends TrackoraStoreAdapter {
  final MethodChannel _channel;

  GooglePlayStoreAdapter({
    @visibleForTesting MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.trackora/google_play');

  @override
  TrackoraStore get store => TrackoraStore.googlePlay;

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
        message: 'Google Play adapter is only supported on Android devices.',
      );
    }

    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('fetchReferrer');
      if (response == null) {
        return AttributionData.failed(
          platform: TrackoraPlatform.android,
          store: store,
          error: 'Empty response received from Google Play plugin',
        );
      }

      final status = response['status'] as String?;
      final message = response['message'] as String?;

      switch (status) {
        case 'ok':
          final rawReferrer = response['rawReferrer'] as String?;
          final clickTimestampSec =
              response['referrerClickTimestampSeconds'] as int?;
          final installBeginTimestampSec =
              response['installBeginTimestampSeconds'] as int?;
          final instantParam = response['googlePlayInstantParam'] as bool?;

          final metadata = <String, dynamic>{
            if (clickTimestampSec != null && clickTimestampSec > 0)
              'referrer_click_timestamp_seconds': clickTimestampSec,
            if (installBeginTimestampSec != null &&
                installBeginTimestampSec > 0)
              'install_begin_timestamp_seconds': installBeginTimestampSec,
            if (instantParam != null) 'google_play_instant': instantParam,
          };

          DateTime? timestamp;
          if (clickTimestampSec != null && clickTimestampSec > 0) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(
              clickTimestampSec * 1000,
              isUtc: true,
            );
          }

          return AttributionNormalizer.fromReferrerString(
            rawReferrer: rawReferrer,
            platform: TrackoraPlatform.android,
            store: store,
            method: AttributionMethod.storeReferrer,
            metadata: metadata,
            timestamp: timestamp,
          );

        case 'feature_not_supported':
          return AttributionData.unsupported(
            platform: TrackoraPlatform.android,
            store: store,
            message: message ??
                'Google Play install referrer not supported on this device',
          );

        case 'service_unavailable':
          return AttributionData.notAvailable(
            platform: TrackoraPlatform.android,
            store: store,
            message: message ?? 'Google Play Referrer service unavailable',
          );

        case 'developer_error':
        default:
          return AttributionData.failed(
            platform: TrackoraPlatform.android,
            store: store,
            error: message ??
                'Failed to retrieve Google Play referrer (status=$status)',
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
