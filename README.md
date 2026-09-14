# Truth

A source-first Flutter news reader. The Android application requires no account, sign-up, password, or authentication.

## News backend

The mobile client does not contain NewsAPI, OpenAI, or other provider credentials. Configure the backend with:

`flutter build appbundle --release --dart-define=BACKEND_BASE_URL=https://your-backend.example`

The backend should expose `GET /news` and return `{ "articles": [...] }`. Each article must include a stable `id`, `headline`, valid `articleUrl`, `sourceName`, and publication information when available. AI processing, if used by the backend, must operate only on retrieved source material and must never invent current events or source metadata.

## Android release signing

Copy `android/key.properties.example` to `android/key.properties` and replace its placeholders with the production upload-keystore values. Keep both `key.properties` and keystore files out of source control. The release build intentionally has no debug-signing fallback.

## Release checks

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=BACKEND_BASE_URL=https://your-backend.example
```

The resulting artifact is an Android App Bundle (`.aab`) suitable for Google Play upload.
