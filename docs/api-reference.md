# API Reference — Trackora SDK

Full Dart API documentation for `trackora`.

---

## 1. Class: `Trackora`

The primary singleton facade for the Trackora attribution SDK.

### Methods

#### `static Future<Trackora> initialize({List<TrackoraStoreAdapter> adapters = const [], TrackoraConfig config = const TrackoraConfig()})`
Initializes the singleton instance with the specified store adapters and configuration options.
- **`adapters`**: List of store adapters to query on Android (e.g. `GooglePlayStoreAdapter`, `CafeBazaarStoreAdapter`, `MyketStoreAdapter`).
- **`config`**: Configuration options for timeout, caching, and debug logging.

#### `static Trackora get instance`
Returns the active singleton instance.
- **Throws**: `StateError` if `Trackora.initialize()` was not called.

#### `Future<AttributionData> getAttribution({Duration? timeout, bool forceRefresh = false})`
Retrieves attribution data for the current install/session.
- If cached data exists and `forceRefresh` is `false`, returns the cached result immediately.
- On Android, queries registered adapters in order until one returns `AttributionStatus.available`.
- On Web, parses `window.location.href`.
- On iOS, returns `AttributionStatus.notAvailable` unless a deep link has been processed.

#### `AttributionData parseUrl(Uri uri, {AttributionMethod method = AttributionMethod.universalLink})`
Synchronously normalizes and extracts campaign parameters from an incoming [Uri]. Updates the current cached attribution and emits on `onAttributionChanged`.

#### `void registerAdapter(TrackoraStoreAdapter adapter)`
Registers an additional store adapter dynamically.

#### `void setAttribution(AttributionData data)`
Manually sets the attribution data (useful for test harnesses or custom attribution sources).

#### `Future<void> dispose()`
Cleans up resources, closes streams, and disposes registered adapters.

### Properties

- **`AttributionData? get currentAttribution`**: The last resolved attribution data, or `null`.
- **`Stream<AttributionData> get onAttributionChanged`**: Broadcast stream of attribution updates.
- **`TrackoraPlatform get currentPlatform`**: Current platform (`android`, `ios`, `web`, `windows`, etc.).
- **`List<TrackoraStoreAdapter> get registeredAdapters`**: Unmodifiable list of registered adapters.

---

## 2. Class: `AttributionData`

Immutable data class representing normalized attribution info.

### Fields

| Field | Type | Description |
|---|---|---|
| `platform` | `TrackoraPlatform` | Operating platform (`android`, `ios`, `web`, etc.). |
| `store` | `TrackoraStore` | Origin store (`googlePlay`, `cafebazaar`, `myket`, `web`, etc.). |
| `source` | `String?` | Campaign source (`utm_source`). |
| `medium` | `String?` | Campaign medium (`utm_medium`). |
| `campaign` | `String?` | Campaign name (`utm_campaign`). |
| `campaignId` | `String?` | Campaign identifier (`utm_id`). |
| `adGroup` | `String?` | Ad group or keyword term (`utm_term`). |
| `creative` | `String?` | Ad creative or content description (`utm_content`). |
| `clickId` | `String?` | Primary click ID (`gclid`, `fbclid`, `ttclid`, `msclkid`, etc.). |
| `rawReferrer` | `String?` | Original unparsed referrer or query string. |
| `landingUrl` | `String?` | Landing page or deep link URL if applicable. |
| `attributionMethod` | `AttributionMethod` | Method (`storeReferrer`, `universalLink`, `deepLink`, `webQueryParam`). |
| `timestamp` | `DateTime?` | Timestamp when attribution occurred. |
| `status` | `AttributionStatus` | Resolution status (`available`, `notAvailable`, `pending`, `unsupported`, `failed`). |
| `metadata` | `Map<String, dynamic>` | Additional parameters (click time, install time, app version, error). |

### Methods

- **`Map<String, dynamic> toJson()`**: Serializes the model into a standard JSON map.
- **`factory AttributionData.fromJson(Map<String, dynamic> json)`**: Deserializes from a JSON map with graceful handling of missing/unexpected fields.
- **`AttributionData copyWith(...)`**: Returns a shallow copy with replaced fields.

---

## 3. Enum: `AttributionStatus`

- **`available`**: Attribution data successfully resolved and non-empty.
- **`notAvailable`**: Check completed normally, but no referrer record exists (e.g. organic install).
- **`pending`**: Attribution retrieval is in progress.
- **`unsupported`**: Platform or store does not support install referrer.
- **`failed`**: An error or exception occurred during retrieval.

---

## 4. Class: `AttributionNormalizer`

Utility class providing safe, idempotent parsing:
- **`static Map<String, String> parseQueryString(String? raw)`**: Parses query string with safe percent decoding and `+` handling.
- **`static AttributionData fromReferrerString(...)`**: Normalizes store referrer string into `AttributionData`.
- **`static AttributionData fromUri(...)`**: Normalizes a URI into `AttributionData`.
