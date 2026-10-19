# Trackora SDK

[![CI](https://github.com/trackora/trackora-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/trackora/trackora-sdk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)

Trackora is an open-source, modular, cross-platform attribution SDK for Flutter applications.

It collects, normalizes, and exposes install attribution information from supported app stores (**Google Play**, **CafeBazaar**, and **Myket**) as well as campaign URLs on **iOS** and **Flutter Web**.

---

## Key Architectural Principles

- **Backend Independence:** Trackora does not require an external Trackora-owned backend, hardcoded server URL, mandatory API key, or telemetry. Your attribution data stays local on device. You can optionally forward the normalized JSON to your own backend.
- **Strict Build-Time Store Isolation:** Store integrations are packaged as independent Flutter plugins. An app distributing on CafeBazaar does not acquire Google Play or Myket SDKs.
- **Unified Attribution Model:** Normalizes standard UTM parameters (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`, `utm_id`) and ad click IDs (`gclid`, `fbclid`, `ttclid`, `msclkid`, etc.) into a strongly typed `AttributionData` model.
- **Resilient Parsing:** Safe URL decoding and parsing preventing double-decoding and malformed input crashes.

---

## Monorepo Layout

```text
trackora-sdk/
├── packages/
│   ├── trackora/                 # Core library: models, normalizer, web reader, facade API
│   ├── trackora_google_play/     # Google Play Install Referrer adapter plugin
│   ├── trackora_cafebazaar/      # CafeBazaar Install Referrer adapter plugin
│   └── trackora_myket/           # Myket Install Referrer adapter plugin
├── examples/
│   └── trackora_example/         # Complete Flutter example application
├── docs/                         # Detailed customer-facing guides & references
├── specs/                        # Architectural specifications and isolation reports
├── scripts/                      # Automation & verification scripts
└── melos.yaml                    # Monorepo workspace configuration
```

---

## Quick Example

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_google_play/trackora_google_play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Trackora with your desired store adapters
  await Trackora.initialize(
    adapters: [
      GooglePlayStoreAdapter(),
      // CafeBazaarStoreAdapter(),
      // MyketStoreAdapter(),
    ],
  );

  runApp(const MyApp());
}

Future<void> printAttribution() async {
  final attribution = await Trackora.instance.getAttribution();

  if (attribution.status == AttributionStatus.available) {
    debugPrint('Source:   ${attribution.source}');
    debugPrint('Campaign: ${attribution.campaign}');
    debugPrint('Click ID: ${attribution.clickId}');
  }
}
```

---

## Documentation Links

- [Installation Guide](docs/installation.md)
- [Quick Start Guide](docs/quick-start.md)
- [Android Setup Guide](docs/android-setup.md)
- [iOS Setup & Capabilities](docs/ios-setup.md)
- [Web Setup & URL Parsing](docs/web-setup.md)
- [API Reference](docs/api-reference.md)
- [Attribution Data Model](docs/attribution-model.md)
- [Store Integrations Details](docs/store-integrations.md)
- [Build-Time Store Isolation Verification Report](specs/store_isolation_report.md)
- [Troubleshooting & FAQ](docs/troubleshooting.md)
- [Privacy & Data Security](docs/privacy.md)
- [Code Examples](docs/examples.md)
- [Production Readiness Checklist](docs/production-checklist.md)
- [راهنمای فارسی (Persian Documentation)](docs/fa/README.md)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
