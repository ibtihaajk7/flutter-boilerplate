# Recipes

The template ships vendor-neutral interfaces with console-only defaults, so a
fresh copy builds and passes CI without any accounts. Each recipe plugs in a
real vendor behind the same interface: the rest of the app doesn't change.

| Recipe | Adds | Needs |
|---|---|---|
| [Firebase setup](firebase-setup.md) | `firebase_core`, `flutterfire configure` | A Firebase project. Do this first for the three below |
| [Firebase Analytics](analytics-firebase.md) | `FirebaseAnalyticsProvider` | Firebase setup |
| [Mixpanel](analytics-mixpanel.md) | `MixpanelAnalyticsProvider` | A Mixpanel project token |
| [Crashlytics](crashlytics.md) | `CrashlyticsCrashReporter` | Firebase setup |
| [Push notifications (FCM)](push-fcm.md) | `PushNotificationService` | Firebase setup, an Apple APNs key |

Every recipe comes with its unit tests. Copy them too: the coverage gate fails
on any file under `lib/` that no test loads.

## What's already in the template

| Interface | Default | Lives in |
|---|---|---|
| `AnalyticsService` + `AnalyticsProvider` | `DebugAnalyticsProvider` prints to the console | `lib/core/analytics/` |
| `AnalyticsRouteObserver` | Logs a screen view for every named route | `lib/core/analytics/` |
| `CrashReporter` + `installErrorHandlers` | `DebugCrashReporter` prints to the console | `lib/core/crash/` |
| `LocalNotificationService` | Fully working, no server needed | `lib/core/notifications/` |

Track events through `AnalyticsService` with names from `AnalyticsEvents`:

```dart
context.read<AnalyticsService>().track(AnalyticsEvents.buttonTap, {
  AnalyticsParams.buttonName: 'subscribe',
});
```

## Don't need local notifications?

1. Delete `lib/core/notifications/`, `lib/features/home/notification_card.dart`
   and their tests.
2. Remove the notification lines from `lib/main.dart` and `home_page.dart`, and
   the `notification*` keys from every ARB file.
3. `flutter pub remove flutter_local_notifications timezone flutter_timezone`
4. Remove the desugaring lines from `android/app/build.gradle.kts`, the
   notification permissions and receivers from `AndroidManifest.xml`, and the
   `UNUserNotificationCenter` line from `ios/Runner/AppDelegate.swift`.
5. `make check`
