import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';

void main() {
  group('AttributionNormalizer', () {
    test('extracts standard UTM parameters accurately', () {
      const raw =
          'utm_source=google&utm_medium=cpc&utm_campaign=black_friday&utm_id=bf_2026&utm_term=shoes&utm_content=v1_ad';

      final data = AttributionNormalizer.fromReferrerString(
        rawReferrer: raw,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );

      expect(data.status, AttributionStatus.available);
      expect(data.source, 'google');
      expect(data.medium, 'cpc');
      expect(data.campaign, 'black_friday');
      expect(data.campaignId, 'bf_2026');
      expect(data.adGroup, 'shoes');
      expect(data.creative, 'v1_ad');
      expect(data.rawReferrer, raw);
    });

    test('extracts single click identifiers (gclid, fbclid, ttclid, msclkid)',
        () {
      final googleData = AttributionNormalizer.fromReferrerString(
        rawReferrer: 'gclid=TeSt_GcLiD_123',
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(googleData.clickId, 'TeSt_GcLiD_123');
      expect(googleData.status, AttributionStatus.available);

      final fbData = AttributionNormalizer.fromReferrerString(
        rawReferrer: 'fbclid=IwAR123xyz',
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(fbData.clickId, 'IwAR123xyz');

      final tiktokData = AttributionNormalizer.fromReferrerString(
        rawReferrer: 'ttclid=tt_click_456',
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(tiktokData.clickId, 'tt_click_456');

      final bingData = AttributionNormalizer.fromReferrerString(
        rawReferrer: 'msclkid=ms_click_789',
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(bingData.clickId, 'ms_click_789');
    });

    test(
        'handles multiple click IDs by selecting primary and storing all in metadata',
        () {
      const raw = 'utm_source=ad_network&gclid=google_123&fbclid=fb_456';
      final data = AttributionNormalizer.fromReferrerString(
        rawReferrer: raw,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );

      expect(data.clickId, 'google_123');
      final clickIds = data.metadata['click_ids'] as Map<String, String>;
      expect(clickIds['gclid'], 'google_123');
      expect(clickIds['fbclid'], 'fb_456');
    });

    test('handles URL-encoded strings and spaces encoded as + or %20', () {
      const raw =
          'utm_source=summer+newsletter&utm_campaign=spring%20sale%202026&utm_content=%D8%AA%D8%AE%D9%81%DB%8C%D9%81';

      final data = AttributionNormalizer.fromReferrerString(
        rawReferrer: raw,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.cafebazaar,
      );

      expect(data.source, 'summer newsletter');
      expect(data.campaign, 'spring sale 2026');
      expect(data.creative, 'تخفیف'); // Persian UTF-8 decoded
    });

    test('resilient to malformed percent encoding without throwing', () {
      const malformed = 'utm_source=promo%ZZ&utm_campaign=sale%2';
      final data = AttributionNormalizer.fromReferrerString(
        rawReferrer: malformed,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );

      expect(data.source, isNotNull);
      expect(data.status, AttributionStatus.available);
    });

    test('ignores empty strings and does not overwrite valid values', () {
      const raw = 'utm_source=&utm_medium=cpc&utm_campaign=test';
      final data = AttributionNormalizer.fromReferrerString(
        rawReferrer: raw,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );

      expect(data.source, isNull);
      expect(data.medium, 'cpc');
      expect(data.campaign, 'test');
    });

    test('returns notAvailable for null or blank referrer', () {
      final nullData = AttributionNormalizer.fromReferrerString(
        rawReferrer: null,
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(nullData.status, AttributionStatus.notAvailable);

      final emptyData = AttributionNormalizer.fromReferrerString(
        rawReferrer: '   ',
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
      );
      expect(emptyData.status, AttributionStatus.notAvailable);
    });

    test('parses full URL and deep links with fromUri', () {
      final uri = Uri.parse(
        'https://trackora.example.com/products/12?utm_source=email&utm_campaign=nov_deals&gclid=xyz123#checkout',
      );

      final data = AttributionNormalizer.fromUri(
        uri,
        platform: TrackoraPlatform.web,
        store: TrackoraStore.web,
        method: AttributionMethod.webQueryParam,
      );

      expect(data.status, AttributionStatus.available);
      expect(data.source, 'email');
      expect(data.campaign, 'nov_deals');
      expect(data.clickId, 'xyz123');
      expect(data.landingUrl,
          startsWith('https://trackora.example.com/products/12'));
    });
  });
}
