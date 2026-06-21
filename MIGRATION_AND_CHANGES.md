# Migration And Changes

This project is a Flutter app, so the implementation was added to the existing Flutter/Firebase codebase instead of creating a separate React app.

## What Changed

- Added a floating Gemini chat button on the authenticated app shell.
- Added a Gemini chat panel with:
  - previous chat sessions sidebar,
  - new chat creation,
  - rename chat,
  - delete chat,
  - per-session message history,
  - loading and error states,
  - responsive desktop/mobile layout.
- Added image support in chat:
  - image picker button,
  - camera button,
  - drag-and-drop image attach support,
  - 2 MB maximum image size validation,
  - Base64 conversion before sending,
  - image bytes sent to Gemini vision-capable model,
  - image file uploaded to Firebase Storage,
  - image metadata and download URL stored in Firestore.
- Added Firestore chat data under each signed-in user.
- Added Firebase Storage rules so users can only access their own uploaded chat images and uploads are limited to images up to 2 MB.
- Added Android camera permission for the Gemini chat camera button.

## New Files

- `lib/model/chat_model.dart`
  - Defines chat sessions, chat messages, image attachment metadata, and pending image data.
- `lib/service/gemini_chat_service.dart`
  - Sends text and optional image bytes to Gemini.
  - Reads `GEMINI_API_KEY` or `VITE_GEMINI_API_KEY` from `.env`.
- `lib/service/chat_session_service.dart`
  - Handles Firestore chat session CRUD.
  - Handles message reads/writes.
  - Uploads images to Firebase Storage.
- `lib/view_model/chat_view_model.dart`
  - Coordinates chat UI state, selected session, sending, errors, and image limit validation.
- `lib/view/gemini_chat_view.dart`
  - Complete chat UI with sidebar, messages, image preview, upload, camera, and drag/drop.
- `storage.rules`
  - Firebase Storage access rules for per-user image files with server-side 2 MB image validation.
- `MIGRATION_AND_CHANGES.md`
  - This teaching and migration guide.

## Modified Files

- `pubspec.yaml`
  - Added:
    - `firebase_storage`
    - `image_picker`
    - `desktop_drop`
- `pubspec.lock`
  - Updated after dependency resolution.
- `lib/main.dart`
  - Added `ChatViewModel`.
  - Added floating chat button.
  - Added `GeminiChatPanel` overlay.
- `firebase.json`
  - Added Storage rules configuration.

## Firebase Data Structure

Firestore stores all app data below the signed-in user's document:

```text
users/{uid}
  displayName
  email
  photoURL
  lastLoginAt

users/{uid}/chatSessions/{sessionId}
  title
  createdAt
  updatedAt

users/{uid}/chatSessions/{sessionId}/messages/{messageId}
  role: "user" | "model"
  text
  createdAt
  attachment:
    fileName
    mimeType
    sizeBytes
    storagePath
    downloadUrl
```

Firebase Storage stores image files here:

```text
users/{uid}/chatSessions/{sessionId}/images/{timestamp}_{fileName}
```

## Why Storage Is Used For Images

Firestore has a document size limit of about 1 MiB. A 2 MB image becomes even larger when encoded as Base64, so storing the full Base64 string inside Firestore is not safe. The app still converts the selected image to Base64 for local processing, but it stores the actual image file in Firebase Storage and saves only metadata plus the download URL in Firestore.

This is the recommended production pattern:

- Firestore stores structured records and metadata.
- Firebase Storage stores binary files.
- Security rules keep both scoped to the signed-in user.

## Environment Variables

The app loads `.env` through `flutter_dotenv`.

Required:

```env
GEMINI_API_KEY=your_gemini_api_key_here
WEATHERSTACK_API_KEY=your_weatherstack_key_here
```

For students coming from a React/Vite lesson, this app also accepts:

```env
VITE_GEMINI_API_KEY=your_gemini_api_key_here
```

Do not commit real production API keys.

## Migrate To A Student Firebase Account

1. Install Firebase CLI and FlutterFire CLI.

```bat
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

2. Login to Firebase.

```bat
set PATH=%APPDATA%\npm;%PATH%
firebase login
```

3. Create or choose a Firebase project.

```bat
firebase projects:create student-summon-ai --display-name "Student Summon AI"
```

Or choose an existing project in Firebase Console.

4. Enable Authentication.

Firebase Console -> Authentication -> Get started -> Sign-in method -> Google -> Enable -> Save.

5. Enable Firestore.

Firebase Console -> Firestore Database -> Create database.

Use production mode, then deploy the rules from this repo.

6. Enable Firebase Storage.

Firebase Console -> Storage -> Get started.

7. Configure FlutterFire for the student's project.

Run from the project root:

```bat
flutterfire configure --project=student-summon-ai --platforms=android,web --android-package-name=com.example.summon_ai --yes --overwrite-firebase-options
```

This regenerates:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

8. Add Android debug SHA fingerprints for Google Sign-In.

```bat
cd android
gradlew signingReport
```

Copy the debug `SHA1` and `SHA-256`, then add them in:

Firebase Console -> Project settings -> Your apps -> Android app -> SHA certificate fingerprints.

Download or regenerate `google-services.json` after adding SHA values.

9. Deploy Firestore and Storage rules.

```bat
firebase use student-summon-ai
firebase deploy --only firestore:rules,storage
```

If Firebase asks for a Storage bucket, choose the default bucket for the student's Firebase project.

10. Install dependencies and run.

```bat
flutter pub get
flutter clean
flutter run
```

## Common Gotchas

- `ApiException: 10` during Google Sign-In usually means the Android package name or SHA fingerprints do not match the Firebase Android app.
- If the app says Firebase setup required, regenerate `lib/firebase_options.dart` with `flutterfire configure`.
- If chat image upload fails, make sure Firebase Storage is enabled and `storage.rules` is deployed.
- `firebase_storage/object-not-found` during image chat usually means Firebase Storage is not fully set up for the project/bucket, or the app is using Firebase config from one project while rules/storage were deployed to another. This app currently expects the bucket from `lib/firebase_options.dart`: `gs://summon-ai-class.firebasestorage.app`. Use the dot before `firebasestorage`, not a hyphen. Open Firebase Console -> Storage -> Get started, make sure the bucket is created for project `summon-ai-class`, then run:

```bat
set PATH=%APPDATA%\npm;%PATH%
firebase use summon-ai-class
firebase deploy --only firestore:rules,storage --project=summon-ai-class
```

After this, stop the app completely and run it again so it reloads the Firebase configuration.
- If a file larger than 2 MB is uploaded, the app blocks it before upload and Storage rules reject it on the server.
- If Gemini replies fail, check that `.env` contains a valid Gemini key and that `.env` is listed under `assets` in `pubspec.yaml`.
- Do not store large Base64 images directly in Firestore. Use Storage and keep metadata in Firestore.
- Keep the image limit at 2 MB or smaller for faster uploads and lower Firebase/Gemini usage.

## Teaching Flow For Students

1. Explain authentication first: every user signs in and gets a unique Firebase UID.
2. Show the Firestore path `users/{uid}` so students understand per-user data isolation.
3. Create one chat session and inspect the Firestore document.
4. Send a text message and inspect the `messages` subcollection.
5. Upload an image and inspect both:
   - the Storage file,
   - the Firestore message metadata.
6. Explain why rules matter: users must not read or write another user's data.
7. Demonstrate the 2 MB validation by trying a larger image.
8. Rename and delete a chat so students see CRUD operations in action.

## Best Practices

- Keep API keys out of source code.
- Use Firestore for structured queryable data.
- Use Storage for binary files.
- Store all user-owned data under `users/{uid}`.
- Deploy security rules before giving the app to students.
- Validate file type and size before upload.
- Keep Gemini prompts and responses in the session history so each chat has context.
