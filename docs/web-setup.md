# Web Setup & URL Parsing Guide — Trackora SDK

Trackora SDK includes built-in support for Flutter Web applications.

---

## How Web Attribution Works

When a user visits your Flutter Web application via an advertising or marketing link:

`https://app.example.com/#/dashboard?utm_source=twitter&utm_medium=cpc&utm_campaign=product_launch_2026&twclid=tw_12345`

Trackora automatically reads `window.location.href` via conditional web imports and parses:
- Campaign Source (`utm_source`)
- Medium (`utm_medium`)
- Campaign Name (`utm_campaign`)
- Campaign ID (`utm_id`)
- Term / Keyword (`utm_term`)
- Content / Creative (`utm_content`)
- Click Identifier (`gclid`, `fbclid`, `ttclid`, `twclid`, `msclkid`, etc.)

---

## Setup & Code Example

No additional store adapters or native configurations are needed on Web. Simply include `trackora` in `pubspec.yaml`:

```yaml
dependencies:
  trackora: ^0.1.0
```

In your Flutter Web application:

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Trackora.initialize();

  runApp(const MyWebApp());
}

class MyWebApp extends StatefulWidget {
  const MyWebApp({super.key});

  @override
  State<MyWebApp> createState() => _MyWebAppState();
}

class _MyWebAppState extends State<MyWebApp> {
  AttributionData? _attribution;

  @override
  void initState() {
    super.initState();
    _loadWebAttribution();
  }

  Future<void> _loadWebAttribution() async {
    final attribution = await Trackora.instance.getAttribution();
    setState(() {
      _attribution = attribution;
    });

    if (attribution.status == AttributionStatus.available) {
      debugPrint('Web user arrived via source: ${attribution.source}');
      debugPrint('Campaign: ${attribution.campaign}');
      debugPrint('Click ID: ${attribution.clickId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Trackora Web Attribution')),
        body: Center(
          child: Text(
            _attribution != null
                ? 'Source: ${_attribution!.source ?? "Organic"}\n'
                  'Campaign: ${_attribution!.campaign ?? "None"}'
                : 'Reading URL parameters...',
          ),
        ),
      ),
    );
  }
}
```

---

## Browser Query and Hash Routing Compatibility

Flutter Web apps frequently use hash-based routing (`/#/path?query`). Trackora's normalizer correctly isolates the query string regardless of whether it appears before or after the `#` fragment symbol.
