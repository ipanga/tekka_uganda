# tekka

Tekka Uganda Flutter app.

## Flavors

- `dev` — local API (`10.0.2.2:4000` Android, `127.0.0.1:4000` iOS). No Firebase.
- `staging` — staging API. No Firebase.
- `prod` — production API (`api.tekka.ug`). Firebase enabled.

Run with:

```bash
flutter run --flavor prod -t lib/main.dart
flutter run --flavor dev -t lib/main_dev.dart
```

## Firebase configuration (prod only)

### Android (`google-services.json`)

Not committed. Dev/staging Android builds skip the google-services plugin
(see `android/app/build.gradle.kts`), so no file is needed. For prod:
download from [Firebase Console](https://console.firebase.google.com/project/tekka-uganda-app/settings/general)
and place at `android/app/src/prod/google-services.json`.

### iOS (`GoogleService-Info.plist`)

A **placeholder** with obviously-fake values is committed so Xcode's
Resources build phase succeeds. Firebase init at runtime will fail with
this placeholder, but dev/staging flavors don't depend on Firebase. For
local prod-flavor builds: download the real plist from Firebase Console
and overwrite `ios/Runner/GoogleService-Info.plist` locally. **Do not
commit the real file** — CI injects it at release build time.

### Why these aren't "secrets"

Firebase client API keys are [public by design](https://firebase.google.com/docs/projects/api-keys):
they ship inside every released APK/IPA and anyone can unpack them with
`unzip`. Access control lives in **Google Cloud Console API key
restrictions** (bundle ID + SHA-256 fingerprint matching), **Firebase
Security Rules**, and optionally **Firebase App Check** — not in secrecy
of these files. We keep them out of git only because GitHub's secret
scanner regex-matches the `AIza…` pattern and flags them.

### CI injection

Release builds on `main` inject the real files from repo secrets
`GOOGLE_SERVICES_JSON` and `GOOGLE_SERVICE_INFO_PLIST` (each the base64
of the file). PR builds use the dev flavor which doesn't need the real
values.
