# Integration Examples — Trackora SDK

Copy-paste-ready code recipes for common integration patterns.

---

## 1. Google Play Only Integration

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_google_play/trackora_google_play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Trackora.initialize(
    adapters: [GooglePlayStoreAdapter()],
  );

  runApp(const MyApp());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AttributionData? _attribution;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Trackora.instance.getAttribution();
    setState(() => _attribution = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Play Attribution')),
      body: Center(
        child: Text(
          _attribution != null
              ? 'Status: ${_attribution!.status.name}\nSource: ${_attribution!.source}'
              : 'Fetching...',
        ),
      ),
    );
  }
}
```

---

## 2. Multi-Store Integration (Google Play + CafeBazaar + Myket)

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_cafebazaar/trackora_cafebazaar.dart';
import 'package:trackora_google_play/trackora_google_play.dart';
import 'package:trackora_myket/trackora_myket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Evaluated sequentially: checks Play first, then Bazaar, then Myket
  await Trackora.initialize(
    adapters: [
      GooglePlayStoreAdapter(),
      CafeBazaarStoreAdapter(),
      MyketStoreAdapter(),
    ],
  );

  runApp(const MyApp());
}
```

---

## 3. Forwarding Attribution to Your Private Backend

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trackora/trackora.dart';

Future<void> syncAttributionWithBackend(String userToken) async {
  final attribution = await Trackora.instance.getAttribution();

  // Only forward if meaningful attribution was resolved
  if (attribution.status != AttributionStatus.available) {
    return;
  }

  final payload = {
    'user_token': userToken,
    'attribution': attribution.toJson(),
  };

  try {
    final response = await http.post(
      Uri.parse('https://api.yourcompany.com/v1/user/attribution'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      debugPrint('Attribution synced successfully.');
    }
  } catch (e) {
    debugPrint('Failed to sync attribution: $e');
  }
}
```

---

## 4. Deep Link & Universal Link Listener

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';

class LinkRouter {
  static void onIncomingUrl(Uri uri) {
    // Normalizes UTMs and click IDs from incoming link
    final attribution = Trackora.instance.parseUrl(
      uri,
      method: AttributionMethod.universalLink,
    );

    if (attribution.status == AttributionStatus.available) {
      debugPrint('Incoming link campaign: ${attribution.campaign}');
      debugPrint('Incoming click ID: ${attribution.clickId}');
    }
  }
}
```

---

## 5. Unit Testing Your App with Mock Attribution

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';

void main() {
  setUp(() async {
    Trackora.resetForTesting();
    final trackora = await Trackora.initialize();

    // Inject simulated attribution data directly
    trackora.setAttribution(
      const AttributionData(
        platform: TrackoraPlatform.android,
        store: TrackoraStore.googlePlay,
        source: 'test_ad_source',
        campaign: 'test_campaign',
        clickId: 'gclid_test_999',
        status: AttributionStatus.available,
      ),
    );
  });

  tearDown(() {
    Trackora.resetForTesting();
  });

  test('app correctly reads injected attribution', () async {
    final attribution = await Trackora.instance.getAttribution();
    expect(attribution.source, 'test_ad_source');
    expect(attribution.campaign, 'test_campaign');
    expect(attribution.clickId, 'gclid_test_999');
  });
}
```
