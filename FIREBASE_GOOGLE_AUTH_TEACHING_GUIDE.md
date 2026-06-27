# Firebase and Google Auth Teaching Guide

This lesson is designed for the current Summon AI Flutter app after students have completed sessions 1-4 of the course. At this point they already know Flutter UI basics, state management, API calls, and project structure. Firebase is the next step because it turns the app from a local single-device app into a real user-based app.

## What Students Will Build

Students will add:

- Firebase initialization
- Google sign-in
- Firestore database storage
- User-specific app data
- A simple sign-out flow

After this lesson, each Google account has its own saved jokes and weather searches.

## Why Firebase Is Used

Firebase is a backend-as-a-service platform. It lets a Flutter app use backend features without writing a custom server.

Firebase Authentication is used because the app needs to know who the current user is. Without authentication, all saved data would belong to the device or to a shared database path.

Cloud Firestore is used because the app needs to save structured data online. Firestore stores data in collections and documents, which fits app features like users, jokes, and weather searches.

Google Sign-In is used because it gives students a practical real-world login method. Users do not need to create a new password, and Firebase can securely identify them with a unique `uid`.

## Final Data Structure

The app stores data like this:

```text
users
  userUid
    uid
    displayName
    email
    photoURL
    lastLoginAt
    jokes
      autoDocumentId
        setup
        punchline
        createdAt
    weatherSearches
      autoDocumentId
        location
        current
        createdAt
```

The important idea is `users/{uid}`. The `uid` comes from Firebase Authentication, so each user reads and writes only their own data.

## Step 1: Create a Firebase Project

1. Go to Firebase Console.
2. Click Add project.
3. Name the project, for example `summon-ai-class`.
4. Disable Google Analytics if you do not need it for class.
5. Create the project.

Explain to students: this project is the backend container for authentication, database, and app configuration.

CLI option on Windows:

```bat
set PATH=%APPDATA%\npm;%PATH%
firebase login
firebase projects:create summon-ai-class --display-name "Summon AI Class"
```

If `summon-ai-class` is already taken, choose a unique project id, for example `summon-ai-alfez-class`.

## Step 2: Enable Authentication

1. Open Firebase Console.
2. Go to Authentication.
3. Click Get started.
4. Open the Sign-in method tab.
5. Enable Google.
6. Add a support email.
7. Save.

Explain to students: enabling Google tells Firebase that users are allowed to log in with Google accounts.

## Step 3: Create Firestore Database

1. Go to Firestore Database.
2. Click Create database.
3. Start in test mode for class practice.
4. Choose the nearest region.
5. Create the database.

For production, do not leave Firestore in test mode. This repository includes `firestore.rules`, `firebase.json`, and `firestore.indexes.json`. The rules allow each signed-in user to access only their own document and subcollections:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Deploy the rules after selecting the Firebase project:

```bash
firebase use your-project-id
firebase deploy --only firestore:rules
```

Explain to students: these rules mean a user can access only the documents under their own UID.

## Step 4: Install Firebase Packages

The app uses these packages:

```yaml
firebase_core
firebase_auth
cloud_firestore
google_sign_in
```

Run:

```bash
flutter pub get
```

Explain to students:

- `firebase_core` starts Firebase in the app.
- `firebase_auth` gives access to the logged-in user.
- `cloud_firestore` reads and writes database documents.
- `google_sign_in` opens the Google account picker.

## Step 5: Configure FlutterFire

Install the Firebase CLI and FlutterFire CLI if needed.

On Windows:

```bat
npm install -g firebase-tools
set PATH=%APPDATA%\npm;%PATH%
firebase --version
firebase login
dart pub global activate flutterfire_cli
```

Then run this from the project root. Use your real Firebase project id:

```bat
flutterfire configure --project=your-project-id
```

Select the Firebase project and target platforms. This generates `lib/firebase_options.dart` with real project keys.

The current repository contains a placeholder `lib/firebase_options.dart`. Replace it by running `flutterfire configure`.

For this app, the important package ids are:

```text
Android package name: com.example.summon_ai
iOS bundle id: com.example.summonAi
```

Explain to students: the options file tells the Flutter app which Firebase project it should connect to.

## What Was Done in This Repository

The app code was changed to use Firebase in these places:

- `pubspec.yaml` includes `firebase_core`, `firebase_auth`, `cloud_firestore`, and `google_sign_in`.
- `lib/main.dart` initializes Firebase before opening the app.
- `lib/service/auth_service.dart` signs users in and out with Google.
- `lib/service/user_data_service.dart` saves profiles, jokes, and weather searches under the signed-in user's UID.
- `lib/view_model/ai_view_model.dart` saves and loads jokes from Firestore.
- `lib/view_model/weather_view_model.dart` saves and loads weather searches from Firestore.
- `firestore.rules` protects each user's data.

The app shows `Firebase setup required` only when `lib/firebase_options.dart` is still the placeholder file. That screen is a safety message, not the final app. It prevents a crash and tells you that the real Firebase options have not been generated yet.

## Step 6: Initialize Firebase

Firebase is initialized in `main.dart` before `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await dotenv.load(fileName: '.env');
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const MyApp());
```

Explain to students: Firebase must be ready before the app uses authentication or Firestore.

## Step 7: Add Google Sign-In

The `AuthService` handles login:

```dart
final googleUser = await _googleSignIn.signIn();
final googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
return _firebaseAuth.signInWithCredential(credential);
```

Explain to students: Google proves the user identity, then Firebase creates a Firebase user session from that proof.

## Step 8: Protect the App With an Auth Gate

`AuthGate` listens to:

```dart
FirebaseAuth.instance.authStateChanges()
```

If there is no user, it shows the sign-in screen. If there is a user, it shows the app.

Explain to students: the UI reacts automatically when the user signs in or signs out.

## Step 9: Save Data by User

The app saves jokes here:

```text
users/{uid}/jokes
```

The app saves weather searches here:

```text
users/{uid}/weatherSearches
```

Explain to students: never save user data in a global collection unless everyone should see it. Use the authenticated user's `uid` to separate private data.

## Step 10: Test the Feature

1. Run `flutter pub get`.
2. Run `flutterfire configure --project=your-project-id`.
3. Run the app.
4. Sign in with Google.
5. Generate a joke.
6. Search for weather.
7. Open Firestore and check the `users` collection.
8. Sign out.
9. Sign in with a different Google account and confirm the history is different.

## Windows CLI Fix Used During Setup

If the terminal says:

```text
'firebase' is not recognized as an internal or external command
```

Install Firebase CLI and add npm global tools to the current terminal path:

```bat
npm install -g firebase-tools
set PATH=%APPDATA%\npm;%PATH%
firebase --version
```

If `flutterfire configure` says there are no authorized accounts, run:

```bat
firebase login
firebase projects:list
```

`firebase login` opens a browser. Complete the browser login, return to the terminal, and run `flutterfire configure --project=your-project-id` again.

## Teaching Checkpoints

Ask students:

- What is the difference between Authentication and Firestore?
- Why do we use `uid` in the database path?
- What happens if we save all jokes in one global `jokes` collection?
- Why should Firestore test mode not be used in production?
- Why do we initialize Firebase before `runApp`?

## Common Errors

If the app says Firebase options are missing, run:

```bat
set PATH=%APPDATA%\npm;%PATH%
firebase login
flutterfire configure --project=your-project-id
```

If Google sign-in fails on Android, check that the Firebase Android app uses the correct package name and SHA-1 fingerprint.

Get the Android SHA-1 fingerprint with:

```bat
cd android
gradlew signingReport
```

Add the SHA-1 value to the Android app in Firebase Console, then download or regenerate the Firebase config if needed.

If Firestore permission is denied, check the security rules and confirm the user is signed in.

If data appears under the wrong user, check that writes use `FirebaseAuth.instance.currentUser?.uid`.
