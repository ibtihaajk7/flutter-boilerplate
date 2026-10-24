# Releasing

## Versioning

`pubspec.yaml` holds the version for local builds. The Release workflow
overrides it: the tag sets the version name (`v1.4.0` → `1.4.0`) and the
workflow run number sets the build number, so every upload gets a higher
build number automatically.

```bash
git tag v1.0.0 && git push origin v1.0.0
```

## Secrets

Add these under **Settings → Secrets and variables → Actions**. All are
optional: without them the workflow still builds, just unsigned or
debug-signed.

| Secret | Used for |
|---|---|
| `ENV_FILE` | Full contents of your production `.env` |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias, e.g. `upload` |
| `ANDROID_KEY_PASSWORD` | Key password |

## Android signing

Create an upload key once and keep it out of the repo:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

For local release builds, create `android/key.properties` (gitignored):

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

`android/app/build.gradle.kts` picks it up automatically and falls back to
debug keys when it's missing.

## iOS signing

CI proves the iOS app builds (`--no-codesign`). To ship to TestFlight, either
archive locally (`flutter build ipa`, then upload with Xcode or Transporter),
or add signing to the workflow with an App Store Connect API key and
[fastlane match](https://docs.fastlane.tools/actions/match/).

Apps using FFI plugins: if a native library works on device but crashes from
TestFlight, Archive stripped its symbols. Set `STRIP_STYLE = non-global` on
the Runner target.
