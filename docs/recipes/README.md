# Recipes

The template ships vendor-neutral interfaces with console-only defaults, so a
fresh copy builds and passes CI without any accounts. Each recipe plugs in a
real vendor behind the same interface: the rest of the app doesn't change.

| Recipe | Adds | Needs |
|---|---|---|
| [Firebase setup](firebase-setup.md) | `firebase_core`, `flutterfire configure` | A Firebase project. Do this first for the Firebase recipes |
| [Firebase Analytics](analytics-firebase.md) | `FirebaseAnalyticsProvider` | Firebase setup | <!-- slim:analytics -->
| [Mixpanel](analytics-mixpanel.md) | `MixpanelAnalyticsProvider` | A Mixpanel project token | <!-- slim:analytics -->
| [Crashlytics](crashlytics.md) | `CrashlyticsCrashReporter` | Firebase setup | <!-- slim:crash -->
| [Push notifications (FCM)](push-fcm.md) | `PushNotificationService` | Firebase setup, an Apple APNs key | <!-- slim:notifications -->

Every recipe comes with its unit tests. Copy them too: the coverage gate fails
on any file under `lib/` that no test loads.

## What's already in the template

| Interface | Default | Lives in |
|---|---|---|
| `AnalyticsService` + `AnalyticsProvider` | `DebugAnalyticsProvider` prints to the console | `lib/core/analytics/` | <!-- slim:analytics -->
| `AnalyticsRouteObserver` | Logs a screen view for every named route | `lib/core/analytics/` | <!-- slim:analytics -->
| `CrashReporter` + `installErrorHandlers` | `DebugCrashReporter` prints to the console | `lib/core/crash/` | <!-- slim:crash -->
| `LocalNotificationService` | Fully working, no server needed | `lib/core/notifications/` | <!-- slim:notifications -->

<!-- slim:analytics:start -->
Track events through `AnalyticsService` with names from `AnalyticsEvents`:

```dart
context.read<AnalyticsService>().track(AnalyticsEvents.buttonTap, {
  AnalyticsParams.buttonName: 'subscribe',
});
```
<!-- slim:analytics:end -->

## Don't need a module?

Remove it with its code, tests, packages, strings and native setup:

```bash
make slim WITHOUT=notifications
```

See [Slim down](../commands.md#slim-down).
