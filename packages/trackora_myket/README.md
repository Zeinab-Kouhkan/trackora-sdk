# Trackora Myket Adapter

Myket Install Referrer adapter plugin for the Trackora attribution SDK.

## Features

- Integrates with Myket Install Referrer Service (`ir.mservices.market`).
- Retrieves raw referrer URL, click timestamp, and install-begin timestamp.
- Strict build-time isolation: Included only when explicitly added to `pubspec.yaml`.

## Installation

Add this package alongside `trackora`:

```yaml
dependencies:
  trackora: ^0.1.0
  trackora_myket: ^0.1.0
```

## Usage

```dart
import 'package:trackora/trackora.dart';
import 'package:trackora_myket/trackora_myket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Trackora.initialize(
    adapters: [
      MyketStoreAdapter(),
    ],
  );

  final attribution = await Trackora.instance.getAttribution();
  debugPrint('Attribution status: ${attribution.status}');
}
```
