# iOS Setup & Attribution Guide — Trackora SDK

This guide details attribution capabilities, limitations, and setup on Apple iOS.

---

## The Reality of iOS Attribution

Unlike Android app stores (Google Play, CafeBazaar, Myket), **the Apple App Store does not provide a client-side install referrer API**. An iOS application cannot query the App Store post-installation to read arbitrary referrer parameters passed before install.

Attribution on iOS operates under two distinct mechanisms:

1. **Universal Links & Custom Deep Links (Supported by Trackora)**:
   Campaign links opened when the app is installed, or routed during initial launch. Trackora parses all UTM parameters (`utm_source`, `utm_campaign`, etc.) and ad click IDs (`gbraid`, `wbraid`, `gclid`, etc.) directly from the URL.

2. **Apple AdAttributionKit & SKAdNetwork (Server-to-Server)**:
   Apple's privacy-preserving advertising framework. Conversion postbacks are signed cryptographically by iOS and sent **directly to ad network and advertiser servers**, not exposed as readable strings inside the client app.

---

## Configuring Universal Links

To capture campaign clicks on iOS, configure Apple Universal Links for your domain:

### 1. Enable Associated Domains Capability
In Xcode:
1. Select your application target.
2. Go to **Signing & Capabilities**.
3. Click **+ Capability** and choose **Associated Domains**.
4. Add your domain prefix: `applinks:attribution.yourcompany.com`.

### 2. Host `apple-app-site-association` (AASA)
Host an `apple-app-site-association` file on your HTTPS server at:
`https://attribution.yourcompany.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.yourcompany.yourapp",
        "paths": ["*"]
      }
    ]
  }
}
```

---

## Handling Incoming Links in Flutter

When an iOS Universal Link opens your app, pass the [Uri] to Trackora:

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';

// Assuming you use a deep link listener like app_links or uni_links:
void handleIncomingUri(Uri uri) {
  final attribution = Trackora.instance.parseUrl(
    uri,
    method: AttributionMethod.universalLink,
  );

  if (attribution.status == AttributionStatus.available) {
    debugPrint('Attributed Campaign: ${attribution.campaign}');
    debugPrint('Click ID: ${attribution.clickId}');
  }
}
```

---

## Expected Behavior of `Trackora.instance.getAttribution()` on iOS

If `getAttribution()` is called on iOS without an incoming Universal Link:
- Returns `AttributionStatus.notAvailable`.
- `metadata['message']` explains that the iOS App Store does not expose client-side install referrers.
- Does not crash or invent fake attribution identifiers.
