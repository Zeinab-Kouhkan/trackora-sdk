# Trackora Google Play Adapter

Google Play Install Referrer adapter plugin for the Trackora attribution SDK.

## Features

- Communicates with Google Play Store Install Referrer API (`com.android.installreferrer:installreferrer`).
- Retrieves raw referrer URL, click timestamp, and install-begin timestamp.
- Strict build-time isolation: Included only when explicitly added to `pubspec.yaml`.

## Installation

Add this package alongside `trackora`:

```yaml
dependencies:
  trackora: ^0.1.0
  trackora_google_play: ^0.1.0
```

## Usage

```dart
import 'package:trackora/trackora.dart';
import 'package:trackora_google_play/trackora_google_play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Trackora.initialize(
    adapters: [
      GooglePlayStoreAdapter(),
    ],
  );

  final attribution = await Trackora.instance.getAttribution();
  debugPrint('Attribution status: ${attribution.status}');
}
```
