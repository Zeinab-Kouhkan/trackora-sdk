# Changelog

All notable changes to the Trackora SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-19

### Added
- Core package `trackora` (0.1.0):
  - Strongly typed `AttributionData` model with full serialization (`toJson`, `fromJson`, `copyWith`).
  - Supported statuses: `available`, `notAvailable`, `pending`, `unsupported`, `failed`.
  - Normalization engine supporting standard UTM parameters (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`, `utm_id`) and ad click identifiers (`gclid`, `fbclid`, `ttclid`, `msclkid`, `dclid`, `wbraid`, `gbraid`, `twclid`).
  - Safe URL decoding and parsing avoiding double-decoding and malformed input crashes.
  - Pluggable `TrackoraStoreAdapter` interface.
  - Public `Trackora` facade API with synchronous configuration and predictable asynchronous fetching.
  - Flutter Web query parameter parsing without breaking mobile/desktop builds.
  - Deep link and Universal Link processing support.
  - Local persistence of attribution state with backend independence (no mandatory server or telemetry).
- Google Play adapter `trackora_google_play` (0.1.0):
  - Android plugin integrating Google Play Install Referrer API (`com.android.installreferrer:installreferrer:2.2`).
  - Strict build-time isolation: included only when explicitly declared in `pubspec.yaml`.
- CafeBazaar adapter `trackora_cafebazaar` (0.1.0):
  - Android plugin integrating CafeBazaar Install Referrer IPC service (`com.farsitel.bazaar`).
  - Strict build-time isolation: included only when explicitly declared in `pubspec.yaml`.
- Myket adapter `trackora_myket` (0.1.0):
  - Android plugin integrating Myket Install Referrer service (`ir.mservices.market`).
  - Strict build-time isolation: included only when explicitly declared in `pubspec.yaml`.
- Example Application `trackora_example`:
  - Complete Flutter sample app demonstrating initialization, multi-store registration, attribution display, and custom backend forwarding.
- Comprehensive customer documentation in `docs/`.
