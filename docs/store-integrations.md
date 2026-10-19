# Store Integrations Architecture — Trackora SDK

Trackora supports three major Android app stores: **Google Play**, **CafeBazaar**, and **Myket**.

Each integration is implemented as an isolated, standalone Flutter plugin.

---

## Comparison Table

| Attribute | Google Play (`trackora_google_play`) | CafeBazaar (`trackora_cafebazaar`) | Myket (`trackora_myket`) |
|---|---|---|---|
| **Mechanism** | Play Install Referrer Library | Bound IPC Service (AIDL) | Bound IPC Service (AIDL) |
| **Package ID** | `com.android.vending` | `com.farsitel.bazaar` | `ir.mservices.market` |
| **Action** | Native SDK internally managed | `com.cafebazaar.referrer.BIND` | `ir.mservices.market.InstallReferrerService.BIND` |
| **Timestamps** | Click seconds & Install seconds | Click milliseconds & Install milliseconds | Click seconds & Install seconds |
| **Special Fields** | `google_play_instant` flag | `app_version` | Caller UID validation |
| **Store Scope** | Global Android devices | Iranian & regional Android users | Iranian & regional Android users |

---

## 1. Google Play Integration

- **Underlying SDK:** `com.android.installreferrer:installreferrer:2.2`
- **Lifecycle:** Trackora establishes connection via `InstallReferrerClient`, reads the referrer bundle asynchronously on background threads, and automatically ends the connection in a `finally` block to prevent service leaks.
- **Response mapping:**
  - `OK (0)`: Parsed into `AttributionStatus.available`.
  - `FEATURE_NOT_SUPPORTED (1)`: Mapped to `AttributionStatus.unsupported`.
  - `SERVICE_UNAVAILABLE (2)`: Mapped to `AttributionStatus.notAvailable`.
  - `DEVELOPER_ERROR (3)`: Mapped to `AttributionStatus.failed`.

---

## 2. CafeBazaar Integration

- **Underlying Protocol:** Direct AIDL Service binding (`com.farsitel.bazaar.referrerprovider.ReferrerProviderService`).
- **Zero Third-Party Maven Dependencies:** Compiles clean AIDL directly within `trackora_cafebazaar`, eliminating brittle JitPack network failures during customer builds.
- **Lifecycle:** Connects via `context.bindService(..., Context.BIND_AUTO_CREATE)`, queries the package referrer, unbinds immediately, and features a built-in 5-second connection watchdog timeout.
- **Timestamps:** Millisecond timestamps are mapped directly to UTC `DateTime` and preserved in metadata.

---

## 3. Myket Integration

- **Underlying Protocol:** Direct AIDL Service binding (`com.myket.installreferrer.IGetInstallReferrerService`).
- **Caller UID Security:** Myket verifies that the requesting application owns the `package_name` passed in the request bundle. If mismatched, response code `5` is returned.
- **Response mapping:**
  - `response_code == 0`: OK, referrer extracted.
  - `response_code == 5`: Not authorized (`AttributionStatus.failed`).
  - `response_code == 6`: No record found (`AttributionStatus.notAvailable`).
- **Permission:** Includes `<uses-permission android:name="ir.mservices.market.INSTALL_REFERRER" />` merged automatically into the host application.

---

## Multi-Store Evaluation Order

When multiple store adapters are passed to `Trackora.initialize(adapters: [...])`:
```dart
await Trackora.initialize(
  adapters: [
    GooglePlayStoreAdapter(),
    CafeBazaarStoreAdapter(),
    MyketStoreAdapter(),
  ],
);
```
Trackora queries them **sequentially in the order provided**:
1. Checks if the adapter's store service is available on the current device (`isAvailable()`).
2. If available, queries `fetchAttribution()`.
3. If valid attribution is returned (`AttributionStatus.available`), evaluation halts and the result is cached and returned.
4. If no referrer is found, evaluation continues to the next registered adapter.
