# NurseUp Real Backend Setup

NurseUp is now wired for real Firebase data, Firebase Auth, Firebase Storage uploads, Firestore reviewers, and local GLB 3D anatomy assets. Groq API is called directly from Flutter (no Cloud Functions).

## Local Flutter commands

Use the full Flutter path if `flutter` is not on PATH:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build apk --debug
```

If Windows shows plugin symlink errors, enable Developer Mode:

```powershell
start ms-settings:developers
```

## Firebase keys - where to put them

Do **not** manually paste Firebase API keys into random Dart files.

Run:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates:

```text
lib/firebase_options.dart
```

Then update `lib/main.dart` to initialize with `DefaultFirebaseOptions.currentPlatform` after the file exists.

## Firebase console setup

In Firebase Console:

1. Create/select your Firebase project.
2. Add an Android app with your package name from `android/app/build.gradle`.
3. Download `google-services.json`.
4. Put it here:

```text
android/app/google-services.json
```

5. Enable these Firebase products:
   - Authentication
   - Firestore Database
   - Storage

## Auth providers

Enable these in Firebase Authentication:

- Email/Password
- Google
- Facebook

### Google Sign-In

Where keys/config go:

- `android/app/google-services.json` from Firebase Console
- SHA-1 and SHA-256 fingerprints added in Firebase Console

Get SHA fingerprints with:

```powershell
cd android
.\gradlew signingReport
```

### Facebook Sign-In

Create a Facebook app at Meta for Developers, then put values here:

```text
android/app/src/main/res/values/strings.xml
```

Add:

```xml
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
<string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
<string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
```

Also add the Facebook app ID and client token to your Android manifest if the plugin instructions require it.

In Firebase Console > Authentication > Sign-in method > Facebook, paste:

- Facebook App ID
- Facebook App Secret

## Groq API key - where to put it

For this school demo, the Groq API key is hardcoded in:

```text
lib/features/ai_reviewer/data/datasources/groq_remote_datasource.dart
```

Replace:

```dart
static const String groqApiKey = 'gsk_xxxxxxxxxxxx';
```

with your actual Groq API key.

No Cloud Functions are used. Groq API is called directly from Flutter via the `http` package.

## Firestore and Storage rules

Deploy Firestore rules:

```powershell
firebase deploy --only firestore:rules
```

Deploy Storage rules:

```powershell
firebase deploy --only storage
```

Rules files:

- `firestore.rules`
- `storage.rules`

## Database collections used

- `users/{uid}`
- `study_files/{uid}/docs/{fileId}`
- `reviewers/{uid}/docs/{reviewerId}`
- `subscriptions/{uid}`

## File upload and AI reviewer flow

1. User signs in.
2. User uploads PDF, DOCX, or TXT.
3. App uploads file to Firebase Storage:

```text
users/{uid}/study_files/{fileId}_{fileName}
```

4. App writes file metadata to Firestore.
5. App calls Groq API directly from Flutter.
6. App writes generated reviewer to:

```text
reviewers/{uid}/docs/{reviewerId}
```

## 3D anatomy assets

Put your GLB files here:

```text
assets/models/anatomy/brain.glb
assets/models/anatomy/heart.glb
assets/models/anatomy/skull.glb
assets/models/anatomy/skeleton.glb
assets/models/anatomy/eye.glb
```

The app uses `model_viewer_plus`. If a GLB is missing, the viewer shows the exact missing path.

## Pro subscription flag

For now, Pro access is controlled by Firestore:

```text
subscriptions/{uid}
```

Set:

```json
{
  "isActive": true,
  "tier": "pro"
}
```

## GCash demo

The `Pay with GCash` button attempts to open `gcash://` and falls back to the Google Play listing. MacroDroid can automate the presentation-only GCash flow on the demo Android device.
