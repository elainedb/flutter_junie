# flutter_junie

Minimal demo app with Google Sign-In and an allowlist of authorized emails.

## Android setup (required for Google Sign-In)
If you see PlatformException(sign_in_failed, status=10), it usually means the Android OAuth setup is incomplete. Do these steps:

1) Confirm package name
- Current Android package/applicationId: com.example.flutter_junie (see android/app/build.gradle.kts)
- This must exist as an Android app in your Firebase project.

2) Add SHA-1 and SHA-256 fingerprints (both Debug and Release) to Firebase → Project settings → Android app (matching package above).
- Debug (Mac/Linux):
  keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
- Debug (Windows PowerShell):
  keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
- Release: use your release keystore.

3) Re-download google-services.json from Firebase and replace the file at android/app/google-services.json.
- Ensure the JSON has an oauth_client block for your package with your certificate hash.

4) Clean and rebuild
- flutter clean
- flutter pub get
- flutter run

Notes
- Google provider must be enabled in Firebase Authentication.
- This project already applies the Google Services Gradle plugin and includes INTERNET permission for release builds.

## iOS/macOS setup
Already configured in this repo: URL scheme with the REVERSED_CLIENT_ID from iOS GoogleService-Info.plist in Info.plist files.

## App behavior
- Title: "Login with Google"
- Button: "Sign in with Google"
- If the signed-in email is allowed, you navigate to a placeholder screen.
- Otherwise, an error is shown below the button.

Authorized emails (example):
- elaine.batista1105@gmail.com
- paulamcunha31@gmail.com
- edbpmc@gmail.com


## Authorized emails configuration
By default, the app uses the sample allowlist committed in lib/config/authorized_emails.sample.dart. This ensures local builds (including release) work out of the box.

If you need to customize the allowlist locally without committing changes:
- Option A: Edit lib/config/authorized_emails.sample.dart directly (simple for local experiments).
- Option B (advanced): Create lib/config/authorized_emails.dart and change the import in lib/login_screen.dart to point to it locally. Note: lib/config/authorized_emails.dart is ignored by Git via .gitignore, so it won’t be committed.

CI notes:
- The GitHub Actions workflow still copies the sample to lib/config/authorized_emails.dart for backward compatibility; this step is harmless now that the app imports the sample directly.


## Firebase config files are not committed
This repo’s .gitignore excludes the platform config files that contain project IDs and API keys. Add them locally as follows:

- Android: place google-services.json at android/app/google-services.json (Flutter tooling also looks for a root-level google-services.json during some tasks, but the canonical location is android/app/).
- iOS: place GoogleService-Info.plist at ios/Runner/GoogleService-Info.plist.
- macOS (if applicable): place GoogleService-Info.plist at macos/Runner/GoogleService-Info.plist.

These files should come from your Firebase project settings. They must exist locally to build and run, but should not be committed to version control.
