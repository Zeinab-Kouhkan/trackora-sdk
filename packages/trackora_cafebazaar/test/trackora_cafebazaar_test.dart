import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_cafebazaar/trackora_cafebazaar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CafeBazaarStoreAdapter adapter;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    adapter = CafeBazaarStoreAdapter();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.trackora/cafebazaar'),
      (MethodCall call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'isAvailable':
            return true;
          case 'fetchReferrer':
            return <String, dynamic>{
              'status': 'ok',
              'rawReferrer':
                  'utm_source=bazaar_ads&utm_campaign=winter_promo&utm_content=v2',
              'referrerClickTimestampMilliseconds': 1700000000000,
              'installBeginTimestampMilliseconds': 1700000050000,
              'appVersion': '2.1.0',
            };
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.trackora/cafebazaar'),
      null,
    );
  });

  group('CafeBazaarStoreAdapter', () {
    test('store property is cafebazaar', () {
      expect(adapter.store, TrackoraStore.cafebazaar);
    });

    test('isAvailable returns true when channel responds true', () async {
      final available = await adapter.isAvailable();
      expect(available, isTrue);
      expect(methodCalls.map((c) => c.method), contains('isAvailable'));
    });

    test(
        'fetchAttribution parses successful CafeBazaar referrer with timestamps and app version',
        () async {
      final data = await adapter.fetchAttribution();

      expect(data.status, AttributionStatus.available);
      expect(data.store, TrackoraStore.cafebazaar);
      expect(data.source, 'bazaar_ads');
      expect(data.campaign, 'winter_promo');
      expect(data.creative, 'v2');
      expect(data.metadata['referrer_click_timestamp_milliseconds'],
          1700000000000);
      expect(
          data.metadata['install_begin_timestamp_milliseconds'], 1700000050000);
      expect(data.metadata['app_version'], '2.1.0');
    });

    test('maps not_found to AttributionStatus.notAvailable', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/cafebazaar'),
        (call) async => <String, dynamic>{
          'status': 'not_found',
          'message': 'No referrer data found',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.notAvailable);
    });

    test('maps service_unavailable to AttributionStatus.notAvailable',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/cafebazaar'),
        (call) async => <String, dynamic>{
          'status': 'service_unavailable',
          'message': 'CafeBazaar not installed',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.notAvailable);
    });

    test('maps timeout to AttributionStatus.failed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/cafebazaar'),
        (call) async => <String, dynamic>{
          'status': 'timeout',
          'message': 'Timed out',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.failed);
    });

    test('handles PlatformException safely', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/cafebazaar'),
        (call) async => throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'Native error',
        ),
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.failed);
      expect(data.metadata['error'], contains('UNAVAILABLE'));
    });
  });
}
