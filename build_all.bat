@echo off
REM Master Build Script - Builds All Components
REM Run this from the project root directory

echo ==========================================
echo Live Idol Clone - Master Build Script
echo ==========================================
echo.
echo This script will build all components:
echo   1. Django Backend
echo   2. Flutter Windows App
echo   3. Unity VRM Renderer (manual - see instructions)
echo.
pause

REM Check we're in the right directory
if not exist "backend" (
    echo ERROR: backend directory not found!
    echo Please run this script from the live-idol-clone root directory.
    pause
    exit /b 1
)

if not exist "flutter_app" (
    echo ERROR: flutter_app directory not found!
    echo Please run this script from the live-idol-clone root directory.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Step 1: Building Django Backend
echo ==========================================
echo.
cd backend
call build.bat
if errorlevel 1 (
    echo ERROR: Backend build failed!
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo ==========================================
echo Step 2: Building Flutter App
echo ==========================================
echo.
cd flutter_app
call build.bat
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo ==========================================
echo Step 3: Unity VRM Renderer
echo ==========================================
echo.
echo Unity build must be done manually:
echo   1. Open Unity Hub
echo   2. Open project at: unity_vrm/
echo   3. Import UniVRM package
echo   4. Copy scripts from unity_vrm_scripts/ to Assets/Scripts/
echo   5. Add a VRM avatar to Assets/StreamingAssets/
echo   6. Create main scene with VRMLoader component
echo   7. Build Settings -^> Windows x64 -^> Build
echo   8. Output to: unity_vrm/Build/VRMRenderer.exe
echo.
echo Press any key when Unity build is complete...
pause

REM Check if Unity build exists
if not exist "unity_vrm\Build\VRMRenderer.exe" (
    echo WARNING: Unity build not found at unity_vrm\Build\VRMRenderer.exe
    echo You may need to complete the Unity build manually.
    echo.
)

echo.
echo ==========================================
echo Build Summary
echo ==========================================
echo.

if exist "backend\dist\LiveIdolBackend.exe" (
    echo [OK] Backend: backend\dist\LiveIdolBackend.exe
) else (
    echo [FAIL] Backend not found
)

if exist "flutter_app\build\windows\runner\Release\live_idol_clone.exe" (
    echo [OK] Flutter: flutter_app\build\windows\runner\Release\live_idol_clone.exe
) else (
    echo [FAIL] Flutter build not found
)

if exist "unity_vrm\Build\VRMRenderer.exe" (
    echo [OK] Unity: unity_vrm\Build\VRMRenderer.exe
) else (
    echo [PENDING] Unity: unity_vrm\Build\VRMRenderer.exe
)

echo.
echo ==========================================
echo Next Steps
echo ==========================================
echo.
echo 1. Test each component individually
echo 2. Prepare installer files (see installer\README.txt)
echo 3. Build installer with Inno Setup
echo 4. Test installer on clean Windows VM
echo.
pause
