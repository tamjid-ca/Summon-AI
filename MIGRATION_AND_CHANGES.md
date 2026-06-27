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
  - image converted to Base64,
  - Base64 image data saved in Firestore chunks,
  - Base64 decoded back to image bytes before sending to Gemini.
- Added Firestore chat data under each signed-in user.
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
  - Saves and loads Base64 image chunks in Firestore.
- `lib/view_model/chat_view_model.dart`
  - Coordinates chat UI state, selected session, sending, errors, and image limit validation.
- `lib/view/gemini_chat_view.dart`
  - Complete chat UI with sidebar, messages, image preview, upload, camera, and drag/drop.
- `MIGRATION_AND_CHANGES.md`
  - This teaching and migration guide.

## Modified Files

- `pubspec.yaml`
  - Added:
    - `image_picker`
    - `desktop_drop`
- `pubspec.lock`
  - Updated after dependency resolution.
- `lib/main.dart`
  - Added `ChatViewModel`.
  - Added floating chat button.
  - Added `GeminiChatPanel` overlay.

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
    base64ChunkCount

users/{uid}/chatSessions/{sessionId}/messages/{messageId}/imageBase64Chunks/{chunkId}
  index
  data
  createdAt
```

## Why Base64 Is Chunked

Firestore has a document size limit of about 1 MiB. A 2 MB image becomes larger when encoded as Base64, so storing the full Base64 string inside one message document will fail.

To keep the requested Base64 database approach working, the app stores the image like this:

- The message document stores image metadata and `base64ChunkCount`.
- The Base64 string is split into smaller documents in `imageBase64Chunks`.
- When the image is shown again, the app loads chunks ordered by `index`, joins them, and decodes the Base64 back into image bytes.
- When sending to Gemini, the selected image is encoded to Base64, then decoded back into bytes and sent with the prompt.

This keeps each Firestore document below the document size limit while still storing the image data in the database.

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

6. Configure FlutterFire for the student's project.

Run from the project root:

```bat
flutterfire configure --project=student-summon-ai --platforms=android,web --android-package-name=com.example.summon_ai --yes --overwrite-firebase-options
```

This regenerates:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

7. Add Android debug SHA fingerprints for Google Sign-In.

```bat
cd android
gradlew signingReport
```

Copy the debug `SHA1` and `SHA-256`, then add them in:

Firebase Console -> Project settings -> Your apps -> Android app -> SHA certificate fingerprints.

Download or regenerate `google-services.json` after adding SHA values.

8. Deploy Firestore rules.

```bat
firebase use student-summon-ai
firebase deploy --only firestore:rules
```

9. Install dependencies and run.

```bat
flutter pub get
flutter clean
flutter run
```

## Common Gotchas

- `ApiException: 10` during Google Sign-In usually means the Android package name or SHA fingerprints do not match the Firebase Android app.
- If the app says Firebase setup required, regenerate `lib/firebase_options.dart` with `flutterfire configure`.
- If chat image saving fails, make sure Firestore is enabled and `firestore.rules` is deployed.
- If a file larger than 2 MB is uploaded, the app blocks it before saving.
- Firestore Base64 image storage is simple for teaching, but it increases database reads and writes because one image may use multiple chunk documents.
- If Gemini replies fail, check that `.env` contains a valid Gemini key and that `.env` is listed under `assets` in `pubspec.yaml`.
- Keep the image limit at 2 MB or smaller for faster uploads and lower Firebase/Gemini usage.

## Teaching Flow For Students

1. Explain authentication first: every user signs in and gets a unique Firebase UID.
2. Show the Firestore path `users/{uid}` so students understand per-user data isolation.
3. Create one chat session and inspect the Firestore document.
4. Send a text message and inspect the `messages` subcollection.
5. Upload an image and inspect:
   - the Firestore message metadata,
   - the `imageBase64Chunks` subcollection under that message.
6. Explain why rules matter: users must not read or write another user's data.
7. Demonstrate the 2 MB validation by trying a larger image.
8. Rename and delete a chat so students see CRUD operations in action.

## Best Practices

- Keep API keys out of source code.
- Use Firestore for structured queryable data.
- For production apps, prefer Firebase Storage for large binary files. For this lesson, Base64 chunks are used because the requirement is to store image data in the database.
- Store all user-owned data under `users/{uid}`.
- Deploy security rules before giving the app to students.
- Validate file type and size before upload.
- Keep Gemini prompts and responses in the session history so each chat has context.

