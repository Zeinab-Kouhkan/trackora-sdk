import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_myket/trackora_myket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MyketStoreAdapter adapter;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    adapter = MyketStoreAdapter();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.trackora/myket'),
      (MethodCall call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'isAvailable':
            return true;
          case 'fetchReferrer':
            return <String, dynamic>{
              'status': 'ok',
              'rawReferrer':
                  'utm_source=myket_campaign&utm_campaign=spring_deals&utm_medium=banner',
              'referrerClickTimestampSeconds': 1700000000,
              'installBeginTimestampSeconds': 1700000060,
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
      const MethodChannel('com.trackora/myket'),
      null,
    );
  });

  group('MyketStoreAdapter', () {
    test('store property is myket', () {
      expect(adapter.store, TrackoraStore.myket);
    });

    test('isAvailable returns true when channel responds true', () async {
      final available = await adapter.isAvailable();
      expect(available, isTrue);
      expect(methodCalls.map((c) => c.method), contains('isAvailable'));
    });

    test('fetchAttribution parses successful Myket referrer with timestamps',
        () async {
      final data = await adapter.fetchAttribution();

      expect(data.status, AttributionStatus.available);
      expect(data.store, TrackoraStore.myket);
      expect(data.source, 'myket_campaign');
      expect(data.campaign, 'spring_deals');
      expect(data.medium, 'banner');
      expect(data.metadata['referrer_click_timestamp_seconds'], 1700000000);
      expect(data.metadata['install_begin_timestamp_seconds'], 1700000060);
    });

    test('maps not_found to AttributionStatus.notAvailable', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/myket'),
        (call) async => <String, dynamic>{
          'status': 'not_found',
          'message': 'No referrer record found in Myket',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.notAvailable);
    });

    test('maps service_unavailable to AttributionStatus.notAvailable',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/myket'),
        (call) async => <String, dynamic>{
          'status': 'service_unavailable',
          'message': 'Myket is not installed',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.notAvailable);
    });

    test('maps developer_error to AttributionStatus.failed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/myket'),
        (call) async => <String, dynamic>{
          'status': 'developer_error',
          'message': 'Not authorized',
        },
      );

      final data = await adapter.fetchAttribution();
      expect(data.status, AttributionStatus.failed);
    });

    test('handles PlatformException safely', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trackora/myket'),
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
