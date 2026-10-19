# Quick Start — Trackora SDK

Get attribution data running in your Flutter application in under 5 minutes.

## 1. Add Dependencies

Add `trackora` and your target store adapter (e.g. `trackora_google_play`) to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_google_play: ^0.1.0 # Or trackora_cafebazaar / trackora_myket
```

Run:
```bash
flutter pub get
```

## 2. Initialize in `main()`

Initialize Trackora inside your `main()` before calling `runApp()`:

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_google_play/trackora_google_play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Trackora with your configured adapters
  await Trackora.initialize(
    adapters: [
      GooglePlayStoreAdapter(),
      // CafeBazaarStoreAdapter(),
      // MyketStoreAdapter(),
    ],
    config: const TrackoraConfig(
      enableCache: true, // Cache attribution once retrieved
      debugLogging: true, // Output debug logs in development
    ),
  );

  runApp(const MyApp());
}
```

## 3. Retrieve Attribution Data

Call `Trackora.instance.getAttribution()` anywhere in your app:

```dart
Future<void> checkAttribution() async {
  final attribution = await Trackora.instance.getAttribution();

  switch (attribution.status) {
    case AttributionStatus.available:
      debugPrint('Campaign source: ${attribution.source}');
      debugPrint('Campaign name:   ${attribution.campaign}');
      debugPrint('Click ID:        ${attribution.clickId}');
      debugPrint('Medium:          ${attribution.medium}');
      break;

    case AttributionStatus.notAvailable:
      debugPrint('Organic install (no campaign referrer found).');
      break;

    case AttributionStatus.unsupported:
      debugPrint('Platform does not support install referrer.');
      break;

    case AttributionStatus.failed:
      debugPrint('Failed to retrieve attribution: ${attribution.metadata['error']}');
      break;

    case AttributionStatus.pending:
      debugPrint('Attribution check pending...');
      break;
  }
}
```

## 4. Handle Incoming Deep Links & Universal Links

When an existing user or newly opened app is launched via a campaign URL:

```dart
void onDeepLinkReceived(Uri uri) {
  final attribution = Trackora.instance.parseUrl(
    uri,
    method: AttributionMethod.universalLink,
  );

  if (attribution.status == AttributionStatus.available) {
    debugPrint('Received campaign link: ${attribution.campaign}');
  }
}
```

## 5. Send to Your Own Backend (Optional)

Trackora never automatically transmits data to external servers. You can serialize the result to JSON and send it to your own API:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendToMyBackend(AttributionData data) async {
  if (data.status != AttributionStatus.available) return;

  final response = await http.post(
    Uri.parse('https://api.yourcompany.com/v1/attribution'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data.toJson()),
  );

  if (response.statusCode == 200) {
    debugPrint('Attribution successfully synced with backend.');
  }
}
```
