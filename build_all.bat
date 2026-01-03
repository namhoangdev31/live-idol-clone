@echo off
REM Live Idol Clone - Master Build Script
REM Run from project root directory

setlocal enabledelayedexpansion

echo ==========================================
echo Live Idol Clone - Master Build Script
echo ==========================================
echo.
echo This script will build all components:
echo   1. Django Backend
echo   2. Flutter Windows App
echo   3. Unity VRM Renderer (manual)
echo.
pause

REM Check we're in the right directory
if not exist "backend\" (
    echo ERROR: backend directory not found!
    echo Please run this script from the live-idol-clone root directory.
    pause
    exit /b 1
)

if not exist "flutter_app\" (
    echo ERROR: flutter_app directory not found!
    echo Please run this script from the live-idol-clone root directory.
    pause
    exit /b 1
)

REM Store original directory
set "PROJECT_ROOT=%CD%"

echo.
echo ==========================================
echo Step 1: Building Django Backend
echo ==========================================
echo.

cd "%PROJECT_ROOT%\backend"
if not exist "build.bat" (
    echo ERROR: backend\build.bat not found!
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

call build.bat
if errorlevel 1 (
    echo.
    echo ERROR: Backend build failed!
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

cd "%PROJECT_ROOT%"
echo.
echo Backend build completed successfully!

echo.
echo ==========================================
echo Step 2: Building Flutter App
echo ==========================================
echo.

cd "%PROJECT_ROOT%\flutter_app"
if not exist "build.bat" (
    echo ERROR: flutter_app\build.bat not found!
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

call build.bat
if errorlevel 1 (
    echo.
    echo ERROR: Flutter build failed!
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

cd "%PROJECT_ROOT%"
echo.
echo Flutter build completed successfully!

echo.
echo ==========================================
echo Step 3: Unity VRM Renderer
echo ==========================================
echo.
echo Unity build must be done manually:
echo.
echo   1. Open Unity Hub
echo   2. Create/Open project at: %PROJECT_ROOT%\unity_vrm\
echo   3. Import UniVRM package from:
echo      https://github.com/vrm-c/UniVRM/releases
echo   4. Create folder: Assets\Scripts\
echo   5. Copy all .cs files from:
echo      %PROJECT_ROOT%\unity_vrm_scripts\
echo      to Assets\Scripts\
echo   6. Create folder: Assets\StreamingAssets\
echo   7. Add VRM avatar file to Assets\StreamingAssets\
echo   8. Create main scene:
echo      - Create Empty GameObject named "VRMController"
echo      - Add scripts: VRMLoader, LipSync, AudioReceiver, IdleAnimation
echo      - Add component: Audio Source
echo   9. File ^> Build Settings
echo      - Platform: Windows x86_64
echo      - Build to: %PROJECT_ROOT%\unity_vrm\Build\
echo.
echo Press any key when Unity build is complete...
pause

REM Check if Unity build exists
if exist "%PROJECT_ROOT%\unity_vrm\Build\VRMRenderer.exe" (
    echo.
    echo Unity build found!
) else (
    echo.
    echo WARNING: Unity build not found at:
    echo   %PROJECT_ROOT%\unity_vrm\Build\VRMRenderer.exe
    echo.
    echo You may need to complete the Unity build manually.
)

echo.
echo ==========================================
echo Build Summary
echo ==========================================
echo.

set BUILD_SUCCESS=0

if exist "%PROJECT_ROOT%\backend\dist\LiveIdolBackend.exe" (
    echo [OK] Backend: backend\dist\LiveIdolBackend.exe
    set /a BUILD_SUCCESS+=1
) else (
    echo [FAIL] Backend executable not found
)

if exist "%PROJECT_ROOT%\flutter_app\build\windows\runner\Release\live_idol_clone.exe" (
    echo [OK] Flutter: flutter_app\build\windows\runner\Release\live_idol_clone.exe
    set /a BUILD_SUCCESS+=1
) else (
    echo [FAIL] Flutter executable not found
)

if exist "%PROJECT_ROOT%\unity_vrm\Build\VRMRenderer.exe" (
    echo [OK] Unity: unity_vrm\Build\VRMRenderer.exe
    set /a BUILD_SUCCESS+=1
) else (
    echo [PENDING] Unity: unity_vrm\Build\VRMRenderer.exe (manual step)
)

echo.
echo Built: !BUILD_SUCCESS! of 3 components

echo.
echo ==========================================
echo Next Steps
echo ==========================================
echo.

if !BUILD_SUCCESS! GEQ 2 (
    echo Your builds are ready! Next steps:
    echo.
    echo 1. Test each component individually
    echo 2. Complete Unity build if not done
    echo 3. Prepare installer files:
    echo    cd installer
    echo    mkdir files\backend files\flutter files\unity files\assets
    echo    copy ..\backend\dist\LiveIdolBackend.exe files\backend\
    echo    xcopy /E /I ..\flutter_app\build\windows\runner\Release\* files\flutter\
    echo    xcopy /E /I ..\unity_vrm\Build\* files\unity\
    echo 4. Build installer with Inno Setup
    echo 5. Test on clean Windows VM
) else (
    echo Please fix failed builds before proceeding.
)

echo.
pause

endlocal
