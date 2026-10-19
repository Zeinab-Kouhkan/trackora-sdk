# Installation Guide — Trackora SDK

Trackora SDK is designed as a modular monorepo. You install the core library (`trackora`) and **only** the store adapters you actually distribute through.

## Supported Platforms & Versions

| Target | Min Version | Recommended Toolchain |
|---|---|---|
| **Flutter** | 3.0.0+ | Flutter 3.22+ or 3.44+ |
| **Dart** | 3.0.0+ | Dart 3.4+ or 3.12+ |
| **Android** | API 19+ (Android 4.4+) | Compile SDK 34+, Java 17 |
| **iOS** | iOS 12.0+ | Xcode 14+ |
| **Web** | Modern browsers (Chrome, Safari, Firefox, Edge) | CanvasKit / HTML renderer |

---

## Package Selection Matrix

Choose only the packages your app targets. Unselected store packages will **not** be included in your build or APK.

| App Distribution Channel | Required Dependencies |
|---|---|
| **Google Play Only** | `trackora`, `trackora_google_play` |
| **CafeBazaar Only** | `trackora`, `trackora_cafebazaar` |
| **Myket Only** | `trackora`, `trackora_myket` |
| **Multi-Store (Play + Bazaar + Myket)** | `trackora`, `trackora_google_play`, `trackora_cafebazaar`, `trackora_myket` |
| **iOS App Store / Web Only** | `trackora` only (no store adapters required) |

---

## 1. Google Play Only Setup

In your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_google_play: ^0.1.0
```

*(Note: During local development in this repository, use path overrides if not referencing pub.dev):*
```yaml
dependency_overrides:
  trackora:
    path: /path/to/packages/trackora
  trackora_google_play:
    path: /path/to/packages/trackora_google_play
```

---

## 2. CafeBazaar Only Setup

In your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_cafebazaar: ^0.1.0
```

---

## 3. Myket Only Setup

In your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_myket: ^0.1.0
```

---

## 4. Multi-Store Setup

If you distribute a single APK/AAB across multiple stores or use product flavors:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_google_play: ^0.1.0
  trackora_cafebazaar: ^0.1.0
  trackora_myket: ^0.1.0
```

---

## 5. Web or iOS Only Setup

If your application only runs on iOS or Web:

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
```

Store adapters are exclusively for Android install referrer APIs and are unnecessary on iOS or Web.
