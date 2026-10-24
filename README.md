# Flutter Boilerplate

<!-- template:start -->
[![CI](https://github.com/ibtihaajk7/flutter-boilerplate/actions/workflows/ci.yml/badge.svg)](https://github.com/ibtihaajk7/flutter-boilerplate/actions/workflows/ci.yml)
[![safe_scale](https://img.shields.io/pub/v/safe_scale?label=safe_scale)](https://pub.dev/packages/safe_scale)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A production-grade starting point for Flutter apps: the same setup, rules and
quality gates used to ship a real app to the App Store and Google Play.

- **Strict analysis**: strict casts, inference and raw types, plus ~95 lint rules; infos fail the build
- **Tests that count**: unit and widget tests from day one, an 80% coverage gate, and no untested file under `lib/`
- **Responsive by default** with [SafeScale](#safescale), clamped system text scale, and phone/tablet layouts
- **Localization** with an ARB checker that catches missing keys, lost placeholders and duplicate copy
- **CI/CD**: GitHub Actions for checks and a debug build on every PR, plus signed releases from a tag
- **AGENTS.md**: layout, testing and l10n rules that both people and AI coding tools follow
- **One-command rename** to your app name, package and bundle IDs

## Start a new app

With the GitHub CLI:

```bash
gh repo create my_app --template ibtihaajk7/flutter-boilerplate --private --clone
```
```bash
cd my_app && make rename NAME=my_app ORG=com.acme DISPLAY="My App"
```
```bash
make check
```

Or click **Use this template** on GitHub, clone your new repo, and run the
same `make rename` line. No `make`? Run
`dart run tool/rename.dart --name my_app --org com.acme --display "My App"`,
then `flutter pub get`.

The rename updates the Dart package and every import, the Android application
ID, namespace and Kotlin package, the iOS bundle ID, and the display name on
both platforms. It also removes this section of the README and then deletes
itself.

## SafeScale

Responsive sizing here is powered by
[**safe_scale**](https://pub.dev/packages/safe_scale), a small package that
scales your design-file sizes to the device *without* the usual "UI bloat" on
problem devices: large-but-low-density phones (iPhone 7 Plus, HD+ Android)
where plain width-based scaling makes everything look oversized.

```dart
Text('Hello', style: TextStyle(fontSize: 18.sp)); // font size from Figma
SizedBox(width: 120.w, height: 48.h);             // sizes from Figma
```

This template wires it in for you: `initSafeScale` runs in `App.build`
against a 390×844 design frame, with tuned clamps for small phones,
low-density large phones and tablets (`lib/core/scale/app_scale.dart`, fully
unit tested). Use it in your own apps:

```bash
flutter pub add safe_scale
```
<!-- template:end -->

## Getting started

Requires Flutter 3.44.1 or newer.

```bash
make setup
```
```bash
make run
```

`make setup` creates `.env` from `.env.example` and gets packages. No `make`?
Run `cp .env.example .env`, `flutter pub get` and `flutter run`.

## Commands

`make` is optional: each target wraps a regular Flutter or Dart command.

| `make` | Plain command | What it does |
|---|---|---|
| `make check` | [5 steps](docs/commands.md#before-you-push) | Everything CI runs |
| `make test` | `flutter test` | Run all tests |
| `make analyze` | `flutter analyze --fatal-infos --fatal-warnings` | Strict analysis |
| `make format` | `dart format lib test tool` | Format code |
| `make l10n` | `flutter gen-l10n` | Regenerate localizations |
| `make hooks` | | Run `make check` before every `git push` |

All commands and what each check enforces: [docs/commands.md](docs/commands.md).

## Project structure

```
lib/
  main.dart          bootstrap only
  app.dart           MaterialApp, SafeScale, theme, l10n, text scale clamp
  core/              env, l10n, layout, scale, theme, shared widgets
  features/<name>/   one folder per feature
  l10n/              ARB files (+ generated code)
test/                mirrors lib/
tool/                scripts used by make and CI
docs/                plans/ and decisions/
```

## Rules

[AGENTS.md](AGENTS.md) holds the rules for this codebase: layout, testing,
analysis, localization and structure. Point your AI coding tool at it, and
read it yourself before your first PR.

## Releasing

Push a tag like `v1.0.0`. The Release workflow builds an Android App Bundle
and an unsigned iOS build. Signing setup is in [docs/release.md](docs/release.md).

---

Responsive sizing by [safe_scale](https://pub.dev/packages/safe_scale).
Started from [flutter-boilerplate](https://github.com/ibtihaajk7/flutter-boilerplate).
