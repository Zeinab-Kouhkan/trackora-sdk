import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:trackora/trackora.dart';

/// Store adapter for Myket install referrer.
class MyketStoreAdapter extends TrackoraStoreAdapter {
  final MethodChannel _channel;

  MyketStoreAdapter({
    @visibleForTesting MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.trackora/myket');

  @override
  TrackoraStore get store => TrackoraStore.myket;

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
        message: 'Myket adapter is only supported on Android devices.',
      );
    }

    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('fetchReferrer');
      if (response == null) {
        return AttributionData.failed(
          platform: TrackoraPlatform.android,
          store: store,
          error: 'Empty response received from Myket plugin',
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

          final metadata = <String, dynamic>{
            if (clickTimestampSec != null && clickTimestampSec > 0)
              'referrer_click_timestamp_seconds': clickTimestampSec,
            if (installBeginTimestampSec != null &&
                installBeginTimestampSec > 0)
              'install_begin_timestamp_seconds': installBeginTimestampSec,
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

        case 'not_found':
        case 'service_unavailable':
          return AttributionData.notAvailable(
            platform: TrackoraPlatform.android,
            store: store,
            message:
                message ?? 'Myket referrer not found or service unavailable',
          );

        case 'developer_error':
        case 'timeout':
        default:
          return AttributionData.failed(
            platform: TrackoraPlatform.android,
            store: store,
            error:
                message ?? 'Failed to retrieve Myket referrer (status=$status)',
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
