# Privacy, Data Handling & Security — Trackora SDK

Privacy and data sovereignty are fundamental design principles of Trackora SDK.

---

## Zero Telemetry & Backend Independence

1. **No External Trackora Servers:** Trackora has no hosted backend servers, no analytics endpoints, and no telemetry services.
2. **No Automatic Network Uploads:** Trackora never makes outgoing HTTP/HTTPS calls on its own.
3. **No SDK Account or Mandatory API Key:** You do not need to register an account or pass an API key to use Trackora.
4. **Data Remains On Device:** All attribution data retrieved from store APIs, URL queries, or deep links remains strictly inside local app memory. Transmission to your own private backend occurs only if you explicitly implement the HTTP call in your code.

---

## Data Collected & Read

Trackora reads only the data strictly necessary for campaign attribution:

| Data Element | Source | Purpose | Leaves Device? |
|---|---|---|---|
| **Raw Referrer Query** | Store Referrer Service / Browser URL | Campaign attribution | No (unless sent by host app) |
| **UTM Parameters** | Raw Referrer | Campaign source, medium, campaign name | No (unless sent by host app) |
| **Click Identifiers (`gclid`, etc.)** | Raw Referrer | Ad conversion matching | No (unless sent by host app) |
| **Referrer Click Timestamp** | Store Referrer Service | Measuring click-to-install latency | No (unless sent by host app) |
| **Install Begin Timestamp** | Store Referrer Service | Measuring install duration | No (unless sent by host app) |
| **Store App Version** | Store Referrer Service | Store compatibility verification | No (unless sent by host app) |

### Information NOT Collected

Trackora explicitly **does NOT collect**:
- Advertising ID (GAID / IDFA)
- Device serial numbers or IMEI
- MAC addresses or IP addresses
- User contact info, email, or accounts
- Location or GPS data
- App usage logs or screen tracking

---

## Store Privacy Declarations

When declaring data safety in app stores:

### Google Play Data Safety
- Trackora does not collect personal data.
- If your app forwards attribution data to your backend, declare **"App info and performance > Other app performance data"** or **"Identifiers"** (if click IDs are tied to user profiles in your backend).

### Apple App Privacy (Privacy Nutrition Labels)
- Trackora core does not collect data on iOS.
- If you parse Universal Links carrying click IDs and link them to user profiles, declare this under your application's tracking policies.

### CafeBazaar & Myket
- No background telemetry permissions are requested.
- The only permission requested is `ir.mservices.market.INSTALL_REFERRER` for IPC binding with Myket.
