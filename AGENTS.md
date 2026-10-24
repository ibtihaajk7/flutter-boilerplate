# Agent instructions

Rules for anyone changing this codebase, human or AI coding tool. Read this
before touching code. When a rule and a shortcut disagree, the rule wins.

## Definition of done

A change is done only when `make check` passes. It runs the same steps as CI:

1. `dart format` (no diff)
2. `flutter analyze --fatal-infos --fatal-warnings` (no issues, infos included)
3. ARB files in sync (`tool/check_l10n.dart`)
4. All tests pass, line coverage at least 80%, and no file under `lib/` is left untested (`tool/check_coverage.dart`)

Never weaken a gate to get green. Fix the code instead.

## Analysis is a floor, not a suggestion

- `analysis_options.yaml` can gain rules, never lose them.
- No `// ignore:` or `// ignore_for_file:` without a one-line reason next to it.
- Don't silence a lint by restructuring code into something worse. If a rule
  genuinely doesn't fit, raise it in the PR.

## Tests are part of the change

- Any new or changed logic (controllers, services, models, utils, tools) ships
  with unit tests **in the same change**.
- Bug fix: first write a test that fails because of the bug, then fix it.
- `test/` mirrors `lib/`: `lib/features/home/counter_controller.dart` →
  `test/features/home/counter_controller_test.dart`.
- Keep logic out of widgets so it can be unit tested: widgets render state,
  controllers own it.
- Screens get widget tests through `test/helpers/pump_app.dart`, including the
  no-overflow cases: small phone (320×568) with 2.0 text scale, and tablet.
- Tests are deterministic: no real network, clock, or randomness. Fake them
  with `mocktail` or inject them.
- Test behaviour, not implementation: assert what a user or caller sees.
- A file with nothing to execute (constants only) may opt out of the coverage
  check with `// coverage:ignore-file` on its first line. Anything with logic
  may not.

## Layout golden rules (responsive mobile)

1. **Rows and Columns before Stack.** Build layouts from `Row`, `Column`,
   `Expanded`, `Flexible` and `Wrap`. `Stack` is only for things that truly
   overlap (a badge on an avatar, a scrim over an image), never to position
   content on screen.
2. **No magic numbers from the design.** Sizes come from SafeScale
   (`16.sp`, `24.w`, `48.h`) or `AppSpacing`. Font sizes come from the theme's
   `textTheme`, never an inline `fontSize:`.
3. **Colors come from `Theme.of(context).colorScheme`.** Raw `Color(0x…)`
   values live only in `lib/core/theme/app_colors.dart`.
4. **Text never gets a fixed height or width.** In a `Row`, text sits inside
   `Expanded`/`Flexible` with `maxLines` and `overflow` set. Translations can
   be 40% longer than English.
5. **Never assume screen height.** Content that can grow scrolls
   (`SingleChildScrollView`, `ListView`). Account for the keyboard.
6. **Space with `spacing:`.** Use `Column(spacing:)` / `Row(spacing:)` with
   `AppSpacing` values instead of `SizedBox` between every child.
7. **Choose layouts from the space you get.** Use `LayoutBuilder` +
   `ScreenType.fromWidth`, not the device model.
8. **Read only the MediaQuery you need**: `MediaQuery.sizeOf(context)`,
   `paddingOf`, `textScalerOf`, never `MediaQuery.of(context)` in widgets
   (it rebuilds on every MediaQuery change).
9. **Images keep their shape**: `AspectRatio` + `BoxFit`, never a fixed width
   *and* height.
10. **Safe area is handled once**: every screen uses `AppScaffold`. Don't add
    `SafeArea` ad hoc.
11. **Widgets are classes, not methods.** Extract `const` widget classes
    instead of `_buildSomething()` helpers.
12. **`const` wherever possible**, and keep `build` methods free of work
    (no parsing, sorting, or I/O).
13. **Tap targets are at least 48×48** and every icon-only button has a
    `tooltip` (it doubles as the screen-reader label).
14. **System text scale is clamped to 1.3** in `app.dart`. Don't clamp it again
    per widget, and don't ignore it.

## SafeScale

`lib/core/scale/app_scale.dart` initializes
[safe_scale](https://pub.dev/packages/safe_scale) against the design frame
(390×844) and clamps the scale for budget phones, low-density large phones,
and tablets. `initSafeScale` runs at the top of `App.build`, before the theme
is built.

- Copy sizes straight from the design file and add `.sp` (fonts), `.w`
  (widths, horizontal padding) or `.h` (heights, vertical padding).
- Never cache a scaled value in a `static final` field. It freezes at its
  first read and won't follow rotation or split screen. Use a getter or a
  method (see `AppTextStyles`, `AppSpacing`).
- Tune the clamps only in `computeSafeScale`, and update its tests.

## Localization

Strings live in `lib/l10n/app_*.arb`; `app_en.arb` is the template.
`lib/l10n/app_localizations*.dart` is generated. Never edit it by hand.

1. Every user-facing string goes through `context.l10n`. No raw string
   literals in `Text`, snackbars, dialogs, tooltips or semantics labels.
2. Before adding a key, search `app_en.arb` for the same text and reuse it.
   The l10n check fails on duplicate English copy.
3. Every ARB file has the same keys and placeholders. Add a key to all of
   them in the same change.
4. Developer-only text (logs, exceptions, debug screens) stays plain English.
   Don't translate it.
5. Plurals use ICU syntax: `{count, plural, =0{…} one{…} other{…}}`. Only the
   text inside the branches is translated.
6. After editing an ARB file: `make l10n` then `make check`. Commit the
   regenerated files. CI fails if they're stale.
7. Resolve device locales through `resolveLocale`; generated lookups throw on
   unsupported languages.

## Analytics, crash reporting and notifications

The app talks to interfaces in `lib/core/`, never to vendor SDKs. Vendors
plug in behind them (`docs/recipes/`).

<!-- slim:analytics:start -->
- Track through `AnalyticsService` only. Event and parameter names are
  constants in `AnalyticsEvents` / `AnalyticsParams`: `snake_case`, at most 40
  characters (asserted in debug). Track from controllers, not deep inside
  widgets.
- Give every page route a `RouteSettings(name: …)`: `AnalyticsRouteObserver`
  logs screen views from it.
<!-- slim:analytics:end -->
<!-- slim:crash:start -->
- Uncaught errors already reach `CrashReporter`. Report caught errors you
  swallow with `recordError(error, stack, reason: …)`. Never an empty `catch`.
<!-- slim:crash:end -->
- Never send personal data (emails, names, free text) as event parameters or
  user properties.
<!-- slim:notifications:start -->
- Ask for notification permission in context, when the user turns on
  something that needs it. Never on launch.
- Notification text is user-facing: it goes through l10n like everything else.
<!-- slim:notifications:end -->
- A new vendor is a new class implementing the interface, plus its unit tests
  against a mocked SDK. Vendor SDK types never leak outside that class.
- Code that belongs to an optional module carries a slim marker comment: a
  line ending in `// slim:<module>`, or a block between
  `// slim:<module>:start` and `// slim:<module>:end` (use the file's comment
  syntax). Keep markers intact when you edit marked code, and mark new code
  that only exists for a module, or `tool/slim.dart` will leave it behind and
  break the build. Wrap anything that may span several lines in a block. CI
  slims every combination on each push to prove it.

## Bulk renames

Don't blind-replace short identifiers across the codebase. Common names
collide with unrelated enum values, fields and methods. Confirm every match,
then run `make analyze` immediately and treat any new error as a sign you hit
unrelated code.

## Structure

```
lib/
  main.dart          bootstrap only; reach the first frame fast
  app.dart           MaterialApp, SafeScale init, theme, l10n, text scale clamp
  core/              shared, feature-agnostic code (analytics, crash, env, l10n,
                     layout, notifications, scale, theme, widgets)
  features/<name>/   one folder per feature: pages, widgets, controllers
  l10n/              ARB files + generated localizations
test/                mirrors lib/; helpers/ holds shared test utilities
tool/                Dart scripts used by make and CI (logic in tool/src/, tested in test/tool/)
docs/                plans/ (active work) and decisions/ (what shipped and why)
```

- Features don't import each other's internals; shared code moves to `core/`.
- Read secrets and config only through `AppEnv`. `.env` is never committed.

## Plans and decisions

- Before working on a feature, check `docs/plans/` for its plan and
  `docs/decisions/` for what's already settled. If the code needs to differ,
  update the plan in the same change.
- When a plan ships, replace it with a short decision record in
  `docs/decisions/` and delete the plan. Git history keeps the long version.

## General

- `debugPrint` or `dart:developer` `log`, never `print`.
- Keep `main()` minimal. Defer anything slow until after the first frame.
- Don't add a dependency for something a few lines of code can do. When you
  do add one, pin a caret version and say why in the PR.
- Format every file you touch: `make format`.
