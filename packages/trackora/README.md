# Trackora Core Flutter SDK

The core library for Trackora, a cross-platform attribution SDK for Flutter applications.

## Features

- **Standardized Attribution Model**: Unified model (`AttributionData`) across Android, iOS, and Web.
- **Strict Build-Time Store Isolation**: Zero native store dependencies in core. Store adapters (`trackora_google_play`, `trackora_cafebazaar`, `trackora_myket`) are independently installable.
- **Comprehensive Parameter Extraction**: Normalizes UTM parameters (`utm_source`, `utm_medium`, `utm_campaign`, etc.) and ad click identifiers (`gclid`, `fbclid`, `ttclid`, `msclkid`, etc.).
- **URL & Deep Link Support**: Easily parse campaign landing URLs and deep links.
- **Web Support**: Seamlessly captures web campaign parameters from browser URL.
- **Backend Independence**: Trackora does not require an external Trackora server, mandatory API key, or telemetry. Your attribution data stays local on device unless you send it to your own backend.

## Installation

Add `trackora` to your `pubspec.yaml`:

```yaml
dependencies:
  trackora: ^0.1.0
```

To enable store referrer retrieval on Android, also add the relevant store adapter:

```yaml
dependencies:
  trackora: ^0.1.0
  # Add only the stores you support:
  trackora_google_play: ^0.1.0
  # trackora_cafebazaar: ^0.1.0
  # trackora_myket: ^0.1.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
// import 'package:trackora_google_play/trackora_google_play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Trackora with your desired store adapters
  await Trackora.initialize(
    adapters: [
      // GooglePlayStoreAdapter(),
    ],
  );

  runApp(const MyApp());
}

class AttributionScreen extends StatefulWidget {
  const AttributionScreen({super.key});

  @override
  State<AttributionScreen> createState() => _AttributionScreenState();
}

class _AttributionScreenState extends State<AttributionScreen> {
  AttributionData? _attribution;

  @override
  void initState() {
    super.initState();
    _fetchAttribution();
  }

  Future<void> _fetchAttribution() async {
    final result = await Trackora.instance.getAttribution();
    setState(() {
      _attribution = result;
    });

    if (result.status == AttributionStatus.available) {
      debugPrint('Attribution source: ${result.source}');
      debugPrint('Attribution campaign: ${result.campaign}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trackora Attribution')),
      body: Center(
        child: Text(_attribution?.toJson().toString() ?? 'Loading...'),
      ),
    );
  }
}
```
