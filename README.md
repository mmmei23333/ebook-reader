# Ebook Reader

A simple ebook reader app for Android.

## Features

- Import EPUB, PDF, and TXT files
- Book library management
- Reading progress tracking
- Bookmarks and notes
- Dark mode support
- Font size adjustment

## Building the APK

### Option 1: Using GitHub Actions (Recommended)

1. Create a new GitHub repository
2. Push this code to the repository
3. Go to Actions tab
4. The workflow will automatically build the APK
5. Download the APK from the Artifacts section

### Option 2: Local Build

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Install Android Studio
3. Run:
   ```bash
   flutter pub get
   flutter build apk --release
   ```
4. Find the APK at: `build/app/outputs/flutter-apk/app-release.apk`

## Usage

1. Install the APK on your Android device
2. Tap the + button to import ebooks
3. Tap a book to start reading
4. Use the controls to adjust settings

## Supported Formats

- EPUB (electronic publication)
- PDF (portable document format)
- TXT (plain text)

## Dependencies

- flutter
- provider
- file_picker
- pdfrx
- shared_preferences
- uuid

## License

MIT License
# Updated
