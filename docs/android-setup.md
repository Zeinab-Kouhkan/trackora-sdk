# Android Setup Guide — Trackora SDK

This guide covers the native Android requirements and configurations for each store adapter.

## Android Requirements

- **Minimum SDK:** API 19 (Android 4.4 KitKat) or higher (API 21+ recommended).
- **Compile SDK:** API 34 or higher.
- **Java:** JDK 17.

## Store-Specific Android Permissions & Queries

Modern Android (API 30+) requires explicit `<queries>` declarations in `AndroidManifest.xml` so that the app can interact with store services across package boundaries.

Each Trackora store plugin automatically bundles its required manifest queries through Android Gradle manifest merger. **In most cases, you do not need to add anything to your app's `AndroidManifest.xml` manually.**

However, for reference or custom build setups:

### 1. Google Play (`trackora_google_play`)
- **Package targeted:** `com.android.vending`
- **Native Library:** `com.android.installreferrer:installreferrer:2.2`
- Merged Manifest:
  ```xml
  <queries>
      <package android:name="com.android.vending" />
  </queries>
  ```

### 2. CafeBazaar (`trackora_cafebazaar`)
- **Package targeted:** `com.farsitel.bazaar`
- **Service Action:** `com.cafebazaar.referrer.BIND`
- Merged Manifest:
  ```xml
  <queries>
      <package android:name="com.farsitel.bazaar" />
      <intent>
          <action android:name="com.cafebazaar.referrer.BIND" />
      </intent>
  </queries>
  ```

### 3. Myket (`trackora_myket`)
- **Package targeted:** `ir.mservices.market`
- **Service Action:** `ir.mservices.market.InstallReferrerService.BIND`
- **Permission:** `ir.mservices.market.INSTALL_REFERRER`
- Merged Manifest:
  ```xml
  <uses-permission android:name="ir.mservices.market.INSTALL_REFERRER" />

  <queries>
      <package android:name="ir.mservices.market" />
      <intent>
          <action android:name="ir.mservices.market.InstallReferrerService.BIND" />
      </intent>
  </queries>
  ```

---

## ProGuard / R8 Rules

If your application enables code shrinking (`minifyEnabled true`), ProGuard rules ensure that AIDL interfaces and binder proxies are not stripped or obfuscated during release builds.

`trackora_myket` automatically supplies consumer ProGuard rules:
```proguard
-keep interface com.myket.installreferrer.** { *; }
-keep class com.myket.installreferrer.** { *; }
```

And for CafeBazaar AIDL:
```proguard
-keep interface com.farsitel.bazaar.referrerprovider.** { *; }
-keep class com.farsitel.bazaar.referrerprovider.** { *; }
```

---

## Testing Install Referrer on Android Devices via ADB

To test referrer attribution locally without publishing:

### Google Play
Google Play Install Referrer requires the app to be installed from Google Play or testing via the Google Play Internal App Sharing track.

### Myket
You can test Myket referrer locally on an emulator or device with Myket installed:
```bash
adb shell am start -a android.intent.action.VIEW -d "myket://details?id=YOUR_PACKAGE_NAME&referrer=utm_source%3Dtest_source%26utm_campaign%3Dtest_campaign"
```

### CafeBazaar
Launch Bazaar detail page with a campaign referrer:
```bash
adb shell am start -a android.intent.action.VIEW -d "bazaar://details?id=YOUR_PACKAGE_NAME&referrer=utm_source%3Dtest_source%26utm_campaign%3Dtest_campaign"
```
