# Migration & Upgrade Guide — Trackora SDK

Version migration paths, compatibility guarantees, and upgrade steps.

---

## Semantic Versioning Policy

Trackora SDK follows [Semantic Versioning 2.0.0](https://semver.org/):
- **Major versions (`X.0.0`):** Breaking changes to public Dart APIs or minimum platform requirements.
- **Minor versions (`0.X.0` or `1.X.0`):** Backwards-compatible new features, newly supported stores, or parameter normalizers.
- **Patch versions (`0.1.X`):** Backwards-compatible bug fixes and performance improvements.

---

## Upgrading to `0.1.0` (Initial Release)

When adopting Trackora in an existing Flutter application:

1. Replace legacy or ad-hoc referrer retrieval code with Trackora adapters:
   ```yaml
   dependencies:
     trackora: ^0.1.0
     trackora_google_play: ^0.1.0 # If distributing on Google Play
     trackora_cafebazaar: ^0.1.0  # If distributing on CafeBazaar
     trackora_myket: ^0.1.0       # If distributing on Myket
   ```

2. Remove duplicate dependencies:
   - If your app was previously including `com.android.installreferrer:installreferrer` directly in your app's `build.gradle`, remove that dependency to avoid version conflicts; `trackora_google_play` manages it automatically.
   - If your app had manual AIDL implementations for Bazaar or Myket, remove them from `android/app/src/main/aidl/`.

3. Replace custom parameter parsing regexes with `AttributionNormalizer`:
   - `AttributionNormalizer` correctly handles multi-click IDs, URL percent decoding without crashing, and prevents double decoding.
