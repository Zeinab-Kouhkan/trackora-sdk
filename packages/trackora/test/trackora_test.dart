import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';

class _MockStoreAdapter extends TrackoraStoreAdapter {
  final TrackoraStore _store;
  final bool _available;
  final AttributionData Function()? _onFetch;
  int fetchCallCount = 0;

  _MockStoreAdapter({
    required TrackoraStore store,
    bool available = true,
    AttributionData Function()? onFetch,
  })  : _store = store,
        _available = available,
        _onFetch = onFetch;

  @override
  TrackoraStore get store => _store;

  @override
  Future<bool> isAvailable() async => _available;

  @override
  Future<AttributionData> fetchAttribution() async {
    fetchCallCount++;
    if (_onFetch != null) return _onFetch!();
    return AttributionData(
      platform: TrackoraPlatform.android,
      store: _store,
      source: 'mock_source',
      campaign: 'mock_campaign',
      status: AttributionStatus.available,
    );
  }
}

void main() {
  setUp(() {
    Trackora.resetForTesting();
  });

  tearDown(() {
    Trackora.resetForTesting();
  });

  group('Trackora Public API', () {
    test('calling Trackora.instance before initialize throws StateError', () {
      expect(Trackora.isInitialized, isFalse);
      expect(() => Trackora.instance, throwsStateError);
    });

    test('initialize creates singleton instance', () async {
      final trackora = await Trackora.initialize();
      expect(Trackora.isInitialized, isTrue);
      expect(identical(Trackora.instance, trackora), isTrue);
    });

    test('registerAdapter dynamically adds store adapter', () async {
      final trackora = await Trackora.initialize();
      expect(trackora.registeredAdapters, isEmpty);

      final adapter = _MockStoreAdapter(store: TrackoraStore.googlePlay);
      trackora.registerAdapter(adapter);

      expect(trackora.registeredAdapters.length, 1);
      expect(trackora.registeredAdapters.first.store, TrackoraStore.googlePlay);
    });

    test('sequential evaluation stops at first available adapter', () async {
      final adapter1 = _MockStoreAdapter(
        store: TrackoraStore.googlePlay,
        available: false,
      );
      final adapter2 = _MockStoreAdapter(
        store: TrackoraStore.cafebazaar,
        available: true,
        onFetch: () => const AttributionData(
          platform: TrackoraPlatform.android,
          store: TrackoraStore.cafebazaar,
          source: 'bazaar_source',
          status: AttributionStatus.available,
        ),
      );
      final adapter3 = _MockStoreAdapter(
        store: TrackoraStore.myket,
        available: true,
      );

      final trackora = await Trackora.initialize(
        adapters: [adapter1, adapter2, adapter3],
      );

      final attribution = await trackora.getAttribution();
      expect(attribution.status, AttributionStatus.available);
      expect(attribution.store, TrackoraStore.cafebazaar);
      expect(attribution.source, 'bazaar_source');

      expect(adapter1.fetchCallCount, 0); // was not available
      expect(adapter2.fetchCallCount, 1); // was called and succeeded
      expect(adapter3.fetchCallCount, 0); // stopped at adapter 2
    });

    test('caches attribution by default unless forceRefresh is true', () async {
      final adapter = _MockStoreAdapter(store: TrackoraStore.googlePlay);
      final trackora = await Trackora.initialize(adapters: [adapter]);

      final first = await trackora.getAttribution();
      expect(adapter.fetchCallCount, 1);
      expect(first.status, AttributionStatus.available);

      final second = await trackora.getAttribution();
      expect(adapter.fetchCallCount, 1); // cached!
      expect(identical(first, second), isTrue);

      final refreshed = await trackora.getAttribution(forceRefresh: true);
      expect(adapter.fetchCallCount, 2); // refetched!
      expect(refreshed.status, AttributionStatus.available);
    });

    test('parseUrl normalizes incoming deep link and emits on stream',
        () async {
      final trackora = await Trackora.initialize();
      final emitted = <AttributionData>[];
      final subscription = trackora.onAttributionChanged.listen(emitted.add);

      final uri =
          Uri.parse('myapp://promo?utm_source=instagram&utm_campaign=story_ad');
      final result = trackora.parseUrl(uri, method: AttributionMethod.deepLink);

      expect(result.status, AttributionStatus.available);
      expect(result.source, 'instagram');
      expect(result.campaign, 'story_ad');
      expect(result.attributionMethod, AttributionMethod.deepLink);
      expect(trackora.currentAttribution, equals(result));

      await pumpEventQueue();
      expect(emitted.length, 1);
      expect(emitted.first, equals(result));

      await subscription.cancel();
    });

    test('returns notAvailable if Android has no adapters configured',
        () async {
      final trackora = await Trackora.initialize(adapters: []);
      final result = await trackora.getAttribution();

      expect(result.status, AttributionStatus.notAvailable);
      expect(result.metadata['message'],
          contains('No Android store adapters registered'));
    });
  });
}
