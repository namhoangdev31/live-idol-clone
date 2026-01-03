@echo off
REM Build Flutter App Script for Windows
REM This script automates the Flutter Windows build process

echo ========================================
echo Live Idol Clone - Flutter Build Script
echo ========================================
echo.

REM Check if we're in the flutter_app directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the flutter_app directory.
    pause
    exit /b 1
)

echo Step 1: Checking Flutter installation...
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter SDK.
    echo Download from: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo.
echo Step 2: Running flutter doctor...
flutter doctor

echo.
echo Step 3: Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Step 4: Building for Windows (Release mode)...
flutter build windows --release
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Output: build\windows\runner\Release\
echo Main executable: live_idol_clone.exe
echo.
echo To test the app, run:
echo   cd build\windows\runner\Release
echo   live_idol_clone.exe
echo.
pause
