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

The prod flavor requires two Firebase client config files. They are **not
committed** (see `.gitignore`) — download them from
[Firebase Console](https://console.firebase.google.com/project/tekka-uganda-app/settings/general)
and place at:

- `android/app/src/prod/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files contain client API keys that are public-by-design per
[Firebase docs](https://firebase.google.com/docs/projects/api-keys) — they
ship inside the released APK/IPA — but they match GitHub's secret-scanning
regex and are therefore kept out of version control. Access control relies
on Google Cloud Console API key restrictions (bundle ID + SHA-256
fingerprint), Firebase Security Rules, and optionally Firebase App Check.

### CI

Release builds on `main` inject these files from repo secrets
`GOOGLE_SERVICES_JSON` and `GOOGLE_SERVICE_INFO_PLIST` (each a base64 of
the file). PR builds only use the dev flavor which needs no Firebase.
