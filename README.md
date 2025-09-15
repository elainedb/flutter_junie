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
The app now imports lib/config/authorized_emails.dart. This file is ignored by Git (see .gitignore), so you can keep your real allowlist locally without committing it.

Quick start locally:
- Copy the sample to the real config path:
  cp lib/config/authorized_emails.sample.dart lib/config/authorized_emails.dart
- Edit lib/config/authorized_emails.dart and put your actual emails.

CI notes:
- The GitHub Actions workflow automatically copies lib/config/authorized_emails.sample.dart to lib/config/authorized_emails.dart before analyze/build, so CI always has a file to import.


## Firebase config files are not committed
This repo’s .gitignore excludes the platform config files that contain project IDs and API keys. Add them locally as follows:

- Android: place google-services.json at android/app/google-services.json (Flutter tooling also looks for a root-level google-services.json during some tasks, but the canonical location is android/app/).
- iOS: place GoogleService-Info.plist at ios/Runner/GoogleService-Info.plist.
- macOS (if applicable): place GoogleService-Info.plist at macos/Runner/GoogleService-Info.plist.

These files should come from your Firebase project settings. They must exist locally to build and run, but should not be committed to version control.
