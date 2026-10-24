# Commands

`make` is optional. Every target is a thin wrapper around a regular Flutter or
Dart command, so use whichever you prefer. On Windows, where `make` isn't
installed by default, use the plain commands.

<!-- template:start -->
## Rename the template

Run once, from the repo root, on a fresh copy.

```bash
make rename NAME=my_app ORG=com.acme DISPLAY="My App"
```

Without `make`:

```bash
dart run tool/rename.dart --name my_app --org com.acme --display "My App"
```

Both rename the project, run `flutter pub get`, sort imports and format.
`make rename` also creates `.env`.
<!-- template:end -->

## First run

| `make` | Plain command |
|---|---|
| `make setup` | `cp .env.example .env` (Windows: `copy .env.example .env`), then `flutter pub get` |
| `make run` | `flutter run` |

`.env` is gitignored but bundled as an asset, so it must exist before the
first `flutter run`. Create it once from `.env.example` and fill in your
values.

## Everyday

| `make` | Plain command |
|---|---|
| `make test` | `flutter test` |
| `make format` | `dart format lib test tool` |
| `make analyze` | `flutter analyze --fatal-infos --fatal-warnings` |
| `make l10n` | `flutter gen-l10n` (after editing an `.arb` file) |
| `make fix` | `dart fix --apply`, then `dart format lib test tool` |
| `make clean` | `flutter clean` |

## Before you push

`make check` runs exactly what CI runs. Without `make`, run these in order:

```bash
dart format --output=none --set-exit-if-changed lib test tool
```
```bash
flutter analyze --fatal-infos --fatal-warnings
```
```bash
dart run tool/check_l10n.dart
```
```bash
flutter test --coverage
```
```bash
dart run tool/check_coverage.dart --min 80
```

`make hooks` installs a git pre-push hook that runs `make check` for you.

## What the checks enforce

- **Format:** no file would change under `dart format`.
- **Analyze:** zero issues, infos included.
- **l10n:** every ARB file has the template's keys and placeholders, and no
  two keys hold the same English text.
- **Coverage:** at least 80% line coverage of `lib/` (excluding `main.dart`
  and generated l10n), and every file under `lib/` is loaded by a test.
