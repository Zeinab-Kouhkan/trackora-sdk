# Production Readiness Checklist — Trackora SDK

Complete this checklist prior to publishing your app to production.

---

## 1. Dependencies & Store Isolation Check

- [ ] **Package Selection:** Does your `pubspec.yaml` contain *only* the store adapters you distribute through?
  - E.g., for Google Play releases, ensure `trackora_cafebazaar` and `trackora_myket` are absent.
- [ ] **Verify Plugin Registration:** Run `flutter pub get` and verify that `.flutter-plugins-dependencies` contains only the intended store adapters.
- [ ] **Dependency Overrides:** If using published packages from pub.dev, ensure all development `dependency_overrides:` have been removed.

---

## 2. Android Configuration

- [ ] **Compile SDK:** Ensure `compileSdk` is set to API 34 or higher in `android/app/build.gradle`.
- [ ] **Package Visibility Queries:** Verify that manifest merger retains `<queries>` for `com.android.vending`, `com.farsitel.bazaar`, or `ir.mservices.market`.
- [ ] **R8 / ProGuard Keep Rules:** If code shrinking is enabled (`minifyEnabled true`), confirm that the keep rules for AIDL interfaces are included in `android/app/proguard-rules.pro`.
- [ ] **Release Signing:** Ensure release build is signed with production keystore.

---

## 3. iOS Configuration

- [ ] **Associated Domains:** If capturing campaign links via Universal Links, ensure `applinks:yourdomain.com` is added under Signing & Capabilities.
- [ ] **AASA File:** Ensure `apple-app-site-association` is served over HTTPS with valid JSON and correct `appID`.
- [ ] **Deep Link Routing:** Ensure `Trackora.instance.parseUrl(uri)` is called when your app receives incoming links.

---

## 4. Web Configuration

- [ ] **URL Formatting:** Test that campaign links preserve query parameters across web routing.
- [ ] **CORS & Hosting:** Ensure your web app hosting supports deep URLs and preserves search queries.

---

## 5. Security & Privacy

- [ ] **Private Backend:** Ensure your own backend endpoint receiving attribution payloads uses HTTPS (`https://`).
- [ ] **No Hardcoded Secrets:** Verify that no private API keys or database tokens are included in client code.
- [ ] **Data Safety Forms:** Fill out Google Play Data Safety and Apple Privacy Nutrition labels accurately according to what your backend does with the attribution data.

---

## 6. Functional Testing

- [ ] **Campaign Install Test:** Test with a simulated campaign referrer link. Verify that `source`, `campaign`, and `clickId` are parsed correctly.
- [ ] **Organic Install Test:** Test launching without any referrer. Verify that the SDK reports `AttributionStatus.notAvailable` gracefully without crashing.
- [ ] **Timeout / Offline Test:** Test launching in airplane mode. Verify that the SDK does not block the UI or hang app startup.
