import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';

void main() {
  group('AttributionData', () {
    test('constructs with required and optional fields correctly', () {
      final now = DateTime.now().toUtc();
      final data = AttributionData(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
        source: 'google',
        medium: 'cpc',
        campaign: 'summer_sale',
        campaignId: 'camp_123',
        adGroup: 'shoes',
        creative: 'banner_red',
        clickId: 'gclid_abc123',
        rawReferrer: 'utm_source=google&utm_medium=cpc&gclid=gclid_abc123',
        landingUrl: 'https://example.com/promo?utm_source=google',
        attributionMethod: AttributionMethod.storeReferrer,
        timestamp: now,
        status: AttributionStatus.available,
        metadata: const {'latency_ms': 42},
      );

      expect(data.platform, TrackoraPlatform.android);
      expect(data.store, TrackoraStore.googlePlay);
      expect(data.source, 'google');
      expect(data.medium, 'cpc');
      expect(data.campaign, 'summer_sale');
      expect(data.campaignId, 'camp_123');
      expect(data.adGroup, 'shoes');
      expect(data.creative, 'banner_red');
      expect(data.clickId, 'gclid_abc123');
      expect(data.rawReferrer,
          'utm_source=google&utm_medium=cpc&gclid=gclid_abc123');
      expect(data.landingUrl, 'https://example.com/promo?utm_source=google');
      expect(data.attributionMethod, AttributionMethod.storeReferrer);
      expect(data.timestamp, now);
      expect(data.status, AttributionStatus.available);
      expect(data.metadata['latency_ms'], 42);
    });

    test('serializes to and from JSON faithfully (round-trip)', () {
      final now = DateTime.utc(2026, 10, 19, 12, 0, 0);
      final data = AttributionData(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.cafebazaar,
        source: 'bazaar_campaign',
        medium: 'banner',
        campaign: 'yalda_2026',
        campaignId: 'c_789',
        adGroup: 'app_install',
        creative: 'yalda_art',
        clickId: 'click_xyz',
        rawReferrer: 'utm_source=bazaar_campaign&utm_campaign=yalda_2026',
        attributionMethod: AttributionMethod.storeReferrer,
        timestamp: now,
        status: AttributionStatus.available,
        metadata: const {'click_time': 1700000000},
      );

      final json = data.toJson();
      expect(json['platform'], 'android');
      expect(json['store'], 'cafebazaar');
      expect(json['source'], 'bazaar_campaign');
      expect(json['status'], 'available');
      expect(json['timestamp'], '2026-10-19T12:00:00.000Z');

      final deserialized = AttributionData.fromJson(json);
      expect(deserialized, equals(data));
      expect(deserialized.hashCode, equals(data.hashCode));
    });

    test('handles missing, null, and unexpected JSON fields gracefully', () {
      final json = <String, dynamic>{
        'platform': 'ios',
        'store': 'apple_app_store',
        'status': 'notAvailable',
      };

      final data = AttributionData.fromJson(json);
      expect(data.platform, TrackoraPlatform.ios);
      expect(data.store, TrackoraStore.appleAppStore);
      expect(data.status, AttributionStatus.notAvailable);
      expect(data.source, isNull);
      expect(data.medium, isNull);
      expect(data.clickId, isNull);
      expect(data.metadata, isEmpty);
    });

    test('factory constructors produce valid instances', () {
      final unsupported = AttributionData.unsupported(
        platform: TrackoraPlatform.windows,
        message: 'Unsupported on Windows',
      );
      expect(unsupported.status, AttributionStatus.unsupported);
      expect(unsupported.metadata['message'], 'Unsupported on Windows');

      final notAvailable = AttributionData.notAvailable(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.myket,
      );
      expect(notAvailable.status, AttributionStatus.notAvailable);

      final failed = AttributionData.failed(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
        error: 'Network timeout',
      );
      expect(failed.status, AttributionStatus.failed);
      expect(failed.metadata['error'], 'Network timeout');

      final pending = AttributionData.pending(
        platform: TrackoraPlatform.web,
        store: TrackoraStore.web,
      );
      expect(pending.status, AttributionStatus.pending);
    });

    test('copyWith updates specified fields only', () {
      const initial = AttributionData(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
        source: 'google',
        status: AttributionStatus.available,
      );

      final updated = initial.copyWith(
        campaign: 'winter_fest',
        clickId: 'gclid_999',
      );

      expect(updated.source, 'google');
      expect(updated.campaign, 'winter_fest');
      expect(updated.clickId, 'gclid_999');
      expect(updated.platform, TrackoraPlatform.android);
      expect(updated.store, TrackoraStore.googlePlay);
    });
  });
}
