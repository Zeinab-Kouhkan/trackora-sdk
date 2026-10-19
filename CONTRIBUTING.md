# Contributing to Trackora SDK

Thank you for your interest in contributing to Trackora SDK! This document provides guidelines for contributing to the project.

## Monorepo Architecture

Trackora is organized as a modular monorepo:

- `packages/trackora`: The core attribution library, models, and public API. Has no native store dependencies.
- `packages/trackora_google_play`: Google Play Install Referrer adapter plugin.
- `packages/trackora_cafebazaar`: CafeBazaar Referrer adapter plugin.
- `packages/trackora_myket`: Myket Referrer adapter plugin.
- `examples/trackora_example`: Reference Flutter application demonstrating integration.

### Core Architectural Rule: Strict Store Isolation

The core `trackora` package **must never** depend on any store adapter package (`trackora_google_play`, `trackora_cafebazaar`, `trackora_myket`).
Store adapters depend on `trackora`, but never on each other.
Customers must be able to install only the adapters they need without acquiring unwanted transitive dependencies.

## Development Setup

1. Ensure Flutter 3.x and Dart 3.x are installed:
   ```bash
   flutter doctor
   ```

2. Optional: Activate Melos for managing the monorepo:
   ```bash
   dart pub global activate melos
   melos bootstrap
   ```

## Running Checks

Before submitting a Pull Request, run the following:

- Code Formatting:
  ```bash
  dart format --output=none --set-exit-if-changed .
  ```
- Static Analysis:
  ```bash
  flutter analyze .
  ```
- Unit & Adapter Tests:
  ```bash
  flutter test
  ```

## Commit Guidelines

Follow conventional commit formats:
- `feat: add support for ...`
- `fix: resolve issue in ...`
- `docs: update integration guide`
- `test: add unit tests for ...`
- `refactor: clean up ...`

## Code Standards

- Write clear, concise Dart code adhering to the standard lints (`flutter_lints`).
- All public APIs, classes, methods, and fields must have doc comments.
- Do not add automatic network telemetry or hardcoded Trackora server endpoints.
