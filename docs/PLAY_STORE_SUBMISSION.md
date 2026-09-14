# Truth — Google Play submission checklist

## Build prerequisites

1. Install a current Flutter SDK and Android SDK with API 36.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Configure a real production keystore. Never commit `android/key.properties` or `*.jks`/`*.keystore`.
4. Choose the HTTPS production backend URL.

## Release build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=BACKEND_BASE_URL=https://YOUR-BACKEND.example
```

Upload:

`build/app/outputs/bundle/release/app-release.aab`

The app ID is `com.dhanush.truth`, target SDK is 36, and the current version is `1.0.0+1`.

## Play Console setup

### Store listing

- App name: **Truth**
- Short description: **Read real news, compare coverage, and save stories locally.**
- Category: **News & Magazine**
- App type: **App**
- Contact email: use the publisher's real support email.
- Privacy policy: publish the project's privacy policy at a public HTTPS URL and enter that URL in Play Console.

### App access

Truth does not require login, registration, a password, or authentication. Reviewer access should therefore be described as unrestricted/no special access required.

### Ads

Answer according to the actual production backend/app behavior. Do not claim “no ads” if ads are later added.

### Target audience and content

Choose the target audience that accurately describes the intended Truth audience. Complete the content rating questionnaire honestly.

### News declaration

Truth is a news application. Complete the Play Console News app declaration accurately and provide any publisher/source information requested by Play Console.

### Data safety

Review the production backend and every SDK actually shipped before submitting. The Flutter client stores bookmarks, rating state, and feedback locally. Feedback can be handed to the user's email application when the user chooses to send it. The backend receives news requests and may process article data. Data Safety answers must reflect the complete deployed system, including third-party SDK behavior.

## Testing

If the Play developer account is a new personal account subject to Google's testing requirement, run a closed test with at least 12 opted-in testers continuously for 14 days before applying for production access.

## Final checks before production

- No login/account/password UI.
- No fake current-news generation.
- No provider/API secrets in the APK/AAB.
- Backend URL is HTTPS.
- Release signing uses the production keystore.
- `targetSdk` is 36 or higher.
- Version code is increased for every Play upload after 1.
- Privacy policy is publicly reachable.
- Store screenshots and promotional assets are supplied.
- The production backend is live and returns real source metadata.
