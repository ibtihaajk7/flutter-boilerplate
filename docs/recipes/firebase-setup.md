# Firebase setup

Needed once for Firebase Analytics, Crashlytics and push notifications.

## 1. Create the project and connect the app

Create a project in the [Firebase console](https://console.firebase.google.com),
then from the repo root:

```bash
dart pub global activate flutterfire_cli
```
```bash
flutter pub add firebase_core
```
```bash
flutterfire configure --platforms=android,ios
```

This writes `lib/firebase_options.dart`, `android/app/google-services.json`
and `ios/Runner/GoogleService-Info.plist`, and adds the Google services Gradle
plugin. `lib/firebase_options.dart` is already excluded from analysis and the
coverage gate.

Run `flutterfire configure` again whenever you add a Firebase package: it
also wires in the Crashlytics Gradle plugin and the iOS symbol upload step.

## 2. Initialize Firebase first

In `lib/main.dart`, right after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

with these imports:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_boilerplate/firebase_options.dart';
```

## Commit the config files?

The three generated files hold identifiers, not secrets, and most teams commit
them so CI can build. In a public repo, restrict the API keys in Google Cloud
Console to your app IDs, and consider
[App Check](https://firebase.google.com/docs/app-check).
