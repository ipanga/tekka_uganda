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

### Local setup (one-time)

Download both files from [Firebase Console → Project Settings](https://console.firebase.google.com/project/tekka-uganda-app/settings/general)
and place them at:

- `android/app/src/prod/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Both paths are gitignored — **do not commit real values**.

### What happens per build

- **Android dev / staging**: the google-services plugin is skipped entirely
  (`android/app/build.gradle.kts` :: `tasks.matching { ... GoogleServices ... }.configureEach { enabled = false }`), so no file is needed.
- **Android prod**: plugin reads `android/app/src/prod/google-services.json`.
  Build fails if missing — download it or expect CI to inject.
- **iOS dev / staging**: Xcode's Resources phase needs the plist to exist,
  but the `Strip Firebase plist` Run Script phase removes it from the
  final `.app` so Firebase never initializes. Having your real prod plist
  sitting locally is fine — it's stripped from dev/staging builds.
- **iOS prod**: plist stays in the bundle; `FLTFirebaseCorePlugin` reads it
  and initializes FIRApp with the real API key.

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
