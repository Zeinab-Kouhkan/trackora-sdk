# Attribution Data Model — Trackora SDK

Trackora normalizes disparate attribution sources into a unified, strongly typed data model: `AttributionData`.

---

## JSON Structure Specification

```json
{
  "platform": "android",
  "store": "google_play",
  "source": "google",
  "medium": "cpc",
  "campaign": "spring_promotion_2026",
  "campaignId": "camp_54321",
  "adGroup": "running_shoes",
  "creative": "hero_banner_v2",
  "clickId": "Cj0KCQjwmOm3BhDhARIsAPggTva...",
  "rawReferrer": "utm_source=google&utm_medium=cpc&utm_campaign=spring_promotion_2026&utm_id=camp_54321&utm_term=running_shoes&utm_content=hero_banner_v2&gclid=Cj0KCQjwmOm3BhDhARIsAPggTva...",
  "landingUrl": null,
  "attributionMethod": "store_referrer",
  "timestamp": "2026-10-19T14:30:00.000Z",
  "status": "available",
  "metadata": {
    "referrer_click_timestamp_seconds": 1700000000,
    "install_begin_timestamp_seconds": 1700000050,
    "google_play_instant": false,
    "click_ids": {
      "gclid": "Cj0KCQjwmOm3BhDhARIsAPggTva..."
    }
  }
}
```

---

## Field Definitions and Precedence

### 1. `source`
- **Extracted from:** `utm_source`, `source`.
- **Description:** Identifies the advertiser, site, or publication originating traffic (e.g. `google`, `facebook`, `newsletter`).

### 2. `medium`
- **Extracted from:** `utm_medium`, `medium`.
- **Description:** Advertising medium (e.g. `cpc`, `banner`, `email`, `social`).

### 3. `campaign`
- **Extracted from:** `utm_campaign`, `campaign`.
- **Description:** Specific campaign name or promotional slogan.

### 4. `campaignId`
- **Extracted from:** `utm_id`, `campaign_id`, `campaignid`.
- **Description:** Unique internal identifier for the ad campaign.

### 5. `adGroup`
- **Extracted from:** `utm_term`, `adgroup`, `term`.
- **Description:** Search keywords, audience segments, or ad group labels.

### 6. `creative`
- **Extracted from:** `utm_content`, `creative`, `content`.
- **Description:** Differentiates ads or links pointing to the same URL (e.g. `logolink`, `textlink`, `v1`).

### 7. `clickId`
- **Extracted from:** `gclid`, `fbclid`, `ttclid`, `msclkid`, `twclid`, `wbraid`, `gbraid`, `dclid`, `click_id`.
- **Precedence:** Trackora assigns the primary click ID based on standard advertising priority. If multiple click IDs exist in a single URL, **all** detected IDs are preserved in `metadata['click_ids']`.

### 8. `rawReferrer`
- Stores the exact unparsed string returned by the store API or URL query, ensuring that no custom or proprietary parameters are lost.

### 9. `status`
- Guarantees explicit state handling. If no campaign parameters exist, `status` is `notAvailable`. Trackora never invents artificial values for absent fields.
