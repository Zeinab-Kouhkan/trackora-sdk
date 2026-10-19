import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_google_play/trackora_google_play.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GooglePlayStoreAdapter adapter;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    adapter = GooglePlayStoreAdapter();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.trackora/google_play'),
      (MethodCall call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'isAvailable':
            return true;
          case 'fetchReferrer':
            return <String, dynamic>{
              'status': 'ok',
              'rawReferrer':
                  'utm_source=play_promo&utm_campaign=summer_sale&gclid=gclid_123',
              'referrerClickTimestampSeconds': 1700000000,
              'installBeginTimestampSeconds': 1700000050,
              'googlePlayInstantParam': false,
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
      const MethodChannel('com.trackora/google_play'),
      null,
    );
  });

  group('GooglePlayStoreAdapter', () {
    test('store property is googlePlay', () {
      expect(adapter.store, TrackoraStore.googlePlay);
    });

    test('isAvailable returns true when channel responds true', () async {
      final available = await adapter.isAvailable();
      expect(available, isTrue);
      expect(methodCalls.map((c) => c.method), contains('isAvailable'));
    });

    test(
        'fetchAttribution parses successful Google Play referrer with timestamps',
        () async {
      final data = await adapter.fetchAttribution();

      expect(data.status, AttributionStatus.available);
      expect(data.store, TrackoraStore.googlePlay);
      expect(data.source, 'play_promo');
      expect(data.campaign, 'summer_sale');
      expect(data.clickId, 'gclid_123');
      expect(data.metadata['referrer_click_timestamp_seconds'], 1700000000);
      expect(data.metadata['install_begin_timestamp_seconds'], 1700000050);
      expect(data.metadata['google_play_instant'], false);
    });

    test('maps feature_not_supported to AttributionStatus.unsupported',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/google_play'),
        (call) async => <String, dynamic>{
          'status': 'feature_not_supported',
          'message': 'Play store version too old',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.unsupported);
      expect(data.metadata['message'], contains('Play store version too old'));
    });

    test('maps service_unavailable to AttributionStatus.notAvailable',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/google_play'),
        (call) async => <String, dynamic>{
          'status': 'service_unavailable',
          'message': 'Play store service disconnected',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.notAvailable);
    });

    test('maps developer_error to AttributionStatus.failed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/google_play'),
        (call) async => <String, dynamic>{
          'status': 'developer_error',
          'message': 'Developer error occurred',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.failed);
      expect(data.metadata['error'], contains('Developer error'));
    });

    test('handles PlatformException safely without throwing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/google_play'),
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
