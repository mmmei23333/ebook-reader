@echo off
echo Building Ebook Reader APK...
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Flutter is not installed or not in PATH.
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build APK
echo Building APK...
flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo Build successful!
    echo APK location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo You can now install this APK on your Android device.
) else (
    echo.
    echo Build failed. Please check the errors above.
)

pause
