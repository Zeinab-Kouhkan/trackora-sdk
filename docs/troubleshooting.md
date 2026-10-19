# Troubleshooting & FAQ — Trackora SDK

Common issues, diagnosis steps, and solutions.

---

## 1. `StateError: Trackora has not been initialized`

**Cause:** Calling `Trackora.instance` before `Trackora.initialize()` has completed.

**Solution:**
Ensure you call `await Trackora.initialize(...)` inside `main()` after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Trackora.initialize(adapters: [GooglePlayStoreAdapter()]);
  runApp(const MyApp());
}
```

---

## 2. `AttributionStatus.notAvailable` on Android

**Possible Causes:**
1. **Organic Install:** The app was downloaded directly without a campaign link or referrer parameter.
2. **Sideloaded APK:** The app was installed via `adb install` or downloaded from a browser rather than installed through Google Play, CafeBazaar, or Myket.
3. **No store adapter installed:** No adapter was passed in `Trackora.initialize(adapters: [...])`. Check `attribution.metadata['message']`.

**Diagnosis:**
Enable debug logging in `TrackoraConfig`:
```dart
config: const TrackoraConfig(debugLogging: true)
```
Check logcat output for messages tagged with `[Trackora]`.

---

## 3. Package Visibility Queries on Android 11+ (API 30+)

**Symptom:** Store referrer service fails to bind or `isAvailable()` returns `false` despite the store app being installed.

**Solution:**
Ensure your build uses standard Android manifest merging. If you have custom manifest strip rules, ensure the `<queries>` tags from `trackora_*` plugins are preserved:
- Google Play: `<package android:name="com.android.vending" />`
- CafeBazaar: `<package android:name="com.farsitel.bazaar" />`
- Myket: `<package android:name="ir.mservices.market" />`

---

## 4. R8 / ProGuard Stripping AIDL Interfaces in Release Builds

**Symptom:** Install referrer works in debug mode but crashes or times out in release APK/AAB (`minifyEnabled true`).

**Solution:**
Ensure ProGuard keep rules are present in your `android/app/proguard-rules.pro`:
```proguard
-keep interface com.myket.installreferrer.** { *; }
-keep class com.myket.installreferrer.** { *; }
-keep interface com.farsitel.bazaar.referrerprovider.** { *; }
-keep class com.farsitel.bazaar.referrerprovider.** { *; }
-keep class com.android.installreferrer.** { *; }
```

---

## 5. Web URL Parameters are Missing

**Symptom:** `getAttribution()` on Web returns `notAvailable`.

**Solution:**
Check your URL format. If your web app uses hash routing (`/#/`), ensure campaign parameters are attached:
- Supported: `https://site.com/?utm_source=google#/page`
- Supported: `https://site.com/#/page?utm_source=google`
Trackora automatically handles both forms.
