@echo off
REM ========================================
REM Live Idol Clone - Universal Build Script
REM ========================================
REM Auto-detects prerequisites and builds accordingly
REM Supports: Portable mode (no install) & Traditional mode

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo   Live Idol Clone - Smart Build System
echo ==========================================
echo.

set "PROJECT_ROOT=%CD%"
set "PORTABLE_DIR=%PROJECT_ROOT%\portable_tools"
set "BUILD_OUTPUT=%PROJECT_ROOT%\build_output"

REM ========================================
REM Step 1: Detect Prerequisites
REM ========================================

echo [1/5] Checking prerequisites...
echo.

set PYTHON_FOUND=0
set FLUTTER_FOUND=0
set BUILD_MODE=unknown

REM Check Python
python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VER=%%i
    echo   [OK] Python !PYTHON_VER!
    set PYTHON_FOUND=1
) else (
    echo   [X] Python not found
)

REM Check Flutter
flutter --version >nul 2>&1
if not errorlevel 1 (
    echo   [OK] Flutter installed
    set FLUTTER_FOUND=1
) else (
    echo   [!] Flutter not found
)

echo.

REM ========================================
REM Step 2: Choose Build Mode
REM ========================================

if !PYTHON_FOUND! EQU 1 if !FLUTTER_FOUND! EQU 1 (
    set BUILD_MODE=traditional
    echo Build Mode: TRADITIONAL ^(using installed tools^)
    echo.
) else (
    set BUILD_MODE=portable
    echo Build Mode: PORTABLE ^(auto-download tools^)
    echo.
    echo Prerequisites missing. Will download portable Python.
    echo.
)

pause

REM Jump to appropriate section to avoid nested block syntax errors
if "%BUILD_MODE%"=="traditional" goto :BUILD_TRADITIONAL
goto :BUILD_PORTABLE

:BUILD_TRADITIONAL
REM ========================================
REM Step 3: Build Backend (Traditional)
REM ========================================
echo.
echo ==========================================
echo [2/5] Building Django Backend (Traditional)
echo ==========================================
echo.

cd "%PROJECT_ROOT%\backend"

echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate.bat

echo Installing dependencies...
pip install -q -r requirements.txt
pip install -q pyinstaller

echo Downloading TTS models...
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')" 2>nul || echo Model download will retry during build

echo Building executable...
python build_backend.py

if exist "dist\LiveIdolBackend.exe" (
    echo [OK] Backend built successfully!
    if not exist "%BUILD_OUTPUT%\backend" mkdir "%BUILD_OUTPUT%\backend"
    xcopy /E /I /Y /Q dist "%BUILD_OUTPUT%\backend"
) else (
    echo [FAIL] Backend build failed
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

deactivate
cd "%PROJECT_ROOT%"
goto :BUILD_FLUTTER

:BUILD_PORTABLE
REM ========================================
REM Step 3: Build Backend (Portable)
REM ========================================
echo.
echo ==========================================
echo [2/5] Building Django Backend (Portable)
echo ==========================================
echo.

REM Portable mode - download Python
if not exist "%PORTABLE_DIR%\python\python.exe" (
    echo Downloading portable Python ^(~30MB^)...
    if not exist "%PORTABLE_DIR%" mkdir "%PORTABLE_DIR%"
    
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip' -OutFile '%PORTABLE_DIR%\python.zip'"
    powershell -Command "Expand-Archive -Path '%PORTABLE_DIR%\python.zip' -DestinationPath '%PORTABLE_DIR%\python' -Force"
    del "%PORTABLE_DIR%\python.zip"
    
    echo Configuring embedded Python...
    REM Creating pth file one line at a time to be safe
    echo python310.zip> "%PORTABLE_DIR%\python\python310._pth"
    echo .>> "%PORTABLE_DIR%\python\python310._pth"
    echo import site>> "%PORTABLE_DIR%\python\python310._pth"
    
    echo Installing pip...
    powershell -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '%PORTABLE_DIR%\python\get-pip.py'"
    "%PORTABLE_DIR%\python\python.exe" "%PORTABLE_DIR%\python\get-pip.py" --no-warn-script-location
    
    echo [OK] Portable Python ready!
) else (
    echo [OK] Portable Python already exists
)

cd "%PROJECT_ROOT%\backend"

REM Fix .pth file (Force recreate every time to fix broken configs)
echo Configuring embedded Python...
(
    echo python310.zip
    echo .
    echo import site
) > "%PORTABLE_DIR%\python\python310._pth"

echo Installing dependencies...
"%PORTABLE_DIR%\python\python.exe" -m pip install -q --no-warn-script-location -r requirements.txt
"%PORTABLE_DIR%\python\python.exe" -m pip install -q --no-warn-script-location pyinstaller

echo Downloading TTS models...
"%PORTABLE_DIR%\python\python.exe" -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')" 2>nul || echo Will retry during build

echo Building executable...
"%PORTABLE_DIR%\python\python.exe" build_backend.py

if exist "dist\LiveIdolBackend.exe" (
    echo [OK] Backend built!
    if not exist "%BUILD_OUTPUT%\backend" mkdir "%BUILD_OUTPUT%\backend"
    xcopy /E /I /Y /Q dist "%BUILD_OUTPUT%\backend"
) else (
    echo [FAIL] Backend build failed
    cd "%PROJECT_ROOT%"
    pause
    exit /b 1
)

cd "%PROJECT_ROOT%"
goto :BUILD_FLUTTER

:BUILD_FLUTTER
REM ========================================
REM Step 4: Build Flutter (if available)
REM ========================================

echo.
echo ==========================================
echo [3/5] Building Flutter App
echo ==========================================
echo.

if !FLUTTER_FOUND! EQU 1 (
    cd "%PROJECT_ROOT%\flutter_app"
    
    echo Getting dependencies...
    flutter pub get
    
    echo Building Windows app...
    flutter build windows --release
    
    if exist "build\windows\runner\Release\live_idol_clone.exe" (
        echo [OK] Flutter built!
        if not exist "%BUILD_OUTPUT%\flutter" mkdir "%BUILD_OUTPUT%\flutter"
        xcopy /E /I /Y /Q build\windows\runner\Release "%BUILD_OUTPUT%\flutter"
    ) else (
        echo [FAIL] Flutter build failed
    )
    
    cd "%PROJECT_ROOT%"
) else (
    echo Flutter not available. Skipping...
    echo.
    echo To build Flutter later:
    echo   1. Install Flutter SDK
    echo   2. cd flutter_app
    echo   3. flutter build windows --release
)

REM ========================================
REM Step 5: Unity Instructions
REM ========================================

echo.
echo ==========================================
echo [4/5] Unity VRM Renderer
echo ==========================================
echo.
echo Unity requires manual setup:
echo.
echo   1. Download Unity Hub + Unity 2021.3 LTS
echo   2. Create project at: %PROJECT_ROOT%\unity_vrm
echo   3. Import UniVRM package
echo   4. Copy scripts from unity_vrm_scripts\ to Assets\Scripts\
echo   5. Add VRM avatar to Assets\StreamingAssets\
echo   6. Build to: unity_vrm\Build\VRMRenderer.exe
echo.
echo Press any key when Unity build is complete (or skip)...
pause >nul

if exist "%PROJECT_ROOT%\unity_vrm\Build\VRMRenderer.exe" (
    echo [OK] Unity build found!
    if not exist "%BUILD_OUTPUT%\unity" mkdir "%BUILD_OUTPUT%\unity"
    xcopy /E /I /Y /Q "%PROJECT_ROOT%\unity_vrm\Build" "%BUILD_OUTPUT%\unity"
) else (
    echo [SKIP] Unity not built yet
)

REM ========================================
REM Step 6: Prepare Installer
REM ========================================

echo.
echo ==========================================
echo [5/5] Preparing Installer Files
echo ==========================================
echo.

set "INSTALLER_FILES=%PROJECT_ROOT%\installer\files"

if exist "%INSTALLER_FILES%" rmdir /S /Q "%INSTALLER_FILES%"
mkdir "%INSTALLER_FILES%\backend"
mkdir "%INSTALLER_FILES%\flutter"
mkdir "%INSTALLER_FILES%\unity"
mkdir "%INSTALLER_FILES%\assets\voice_profiles\default"

REM Copy builds
if exist "%BUILD_OUTPUT%\backend\LiveIdolBackend.exe" (
    xcopy /E /I /Y /Q "%BUILD_OUTPUT%\backend" "%INSTALLER_FILES%\backend"
    echo [OK] Backend copied
)

if exist "%BUILD_OUTPUT%\flutter\live_idol_clone.exe" (
    xcopy /E /I /Y /Q "%BUILD_OUTPUT%\flutter" "%INSTALLER_FILES%\flutter"
    echo [OK] Flutter copied
)

if exist "%BUILD_OUTPUT%\unity\VRMRenderer.exe" (
    xcopy /E /I /Y /Q "%BUILD_OUTPUT%\unity" "%INSTALLER_FILES%\unity"
    echo [OK] Unity copied
)

if exist "%PROJECT_ROOT%\backend\voice_profiles\default\README.md" (
    copy /Y "%PROJECT_ROOT%\backend\voice_profiles\default\README.md" "%INSTALLER_FILES%\assets\voice_profiles\default\" >nul
)

REM ========================================
REM Summary
REM ========================================

echo.
echo ==========================================
echo Build Summary
echo ==========================================
echo.
echo Build Mode: %BUILD_MODE%
echo Output: %BUILD_OUTPUT%
echo.

set COMPONENTS=0

if exist "%BUILD_OUTPUT%\backend\LiveIdolBackend.exe" (
    echo [OK] Backend
    set /a COMPONENTS+=1
) else (
    echo [X] Backend
)

if exist "%BUILD_OUTPUT%\flutter\live_idol_clone.exe" (
    echo [OK] Flutter
    set /a COMPONENTS+=1
) else (
    echo [X] Flutter
)

if exist "%BUILD_OUTPUT%\unity\VRMRenderer.exe" (
    echo [OK] Unity
    set /a COMPONENTS+=1
) else (
    echo [X] Unity
)

echo.
echo Components built: !COMPONENTS! of 3
echo.

REM ========================================
REM Next Steps
REM ========================================

if !COMPONENTS! GEQ 2 (
    echo ==========================================
    echo Next Steps
    echo ==========================================
    echo.
    echo Your builds are ready!
    echo.
    echo To create installer:
    echo   1. Open Inno Setup
    echo   2. Open: %PROJECT_ROOT%\installer\setup.iss
    echo   3. Click "Compile"
    echo   4. Output: installer\output\LiveIdolCloneInstaller.exe
    echo.
) else (
    echo Please complete missing builds before creating installer.
    echo.
)

echo Build log saved to: build.log
echo.
pause

endlocal
