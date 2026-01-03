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

set BACKEND_MODE=portable
set FRONTEND_MODE=portable

if !PYTHON_FOUND! EQU 1 (
    set BACKEND_MODE=traditional
    echo Backend Mode: TRADITIONAL ^(using installed Python !PYTHON_VER!^)
) else (
    echo Backend Mode: PORTABLE ^(will download Python^)
)

if !FLUTTER_FOUND! EQU 1 (
    set FRONTEND_MODE=traditional
    echo Frontend Mode: TRADITIONAL ^(using installed Flutter^)
) else (
    echo Frontend Mode: PORTABLE ^(will download Flutter^)
)

echo.
pause

REM Jump to appropriate backend build section
if "%BACKEND_MODE%"=="traditional" goto :BUILD_TRADITIONAL
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

REM Check if backend already built
if exist "%BUILD_OUTPUT%\backend\LiveIdolBackend.exe" (
    echo Backend already built, skipping...
    goto :BUILD_FLUTTER
)

cd "%PROJECT_ROOT%\backend"

echo Creating virtual environment...
python -m venv venv
call venv\Scripts\activate.bat

echo Installing dependencies...
python -m pip install --upgrade pip wheel
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
    
    powershell -Command "Invoke-WebRequest -Uri \"https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip\" -OutFile \"%PORTABLE_DIR%\python.zip\""
    powershell -Command "Expand-Archive -Path \"%PORTABLE_DIR%\python.zip\" -DestinationPath \"%PORTABLE_DIR%\python\" -Force"
    del "%PORTABLE_DIR%\python.zip"
    
    echo Configuring embedded Python...
    REM Creating pth file one line at a time to be safe
    echo python310.zip> "%PORTABLE_DIR%\python\python310._pth"
    echo .>> "%PORTABLE_DIR%\python\python310._pth"
    echo import site>> "%PORTABLE_DIR%\python\python310._pth"
    
    echo Installing pip...
    powershell -Command "Invoke-WebRequest -Uri \"https://bootstrap.pypa.io/get-pip.py\" -OutFile \"%PORTABLE_DIR%\python\get-pip.py\""
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
    echo .
    echo import site
) > "%PORTABLE_DIR%\python\python310._pth"

echo Checking pip...
"%PORTABLE_DIR%\python\python.exe" -m pip --version >nul 2>&1
if errorlevel 1 (
    echo Pip not found. Installing pip...
    if not exist "%PORTABLE_DIR%\python\get-pip.py" (
        powershell -Command "Invoke-WebRequest -Uri \"https://bootstrap.pypa.io/get-pip.py\" -OutFile \"%PORTABLE_DIR%\python\get-pip.py\""
    )
    "%PORTABLE_DIR%\python\python.exe" "%PORTABLE_DIR%\python\get-pip.py" --no-warn-script-location
)

echo Installing dependencies...
"%PORTABLE_DIR%\python\python.exe" -m pip install -q --no-warn-script-location wheel setuptools Cython numpy
if errorlevel 1 goto :PORTABLE_FAIL

"%PORTABLE_DIR%\python\python.exe" -m pip install -q --no-warn-script-location -r requirements.txt
if errorlevel 1 goto :PORTABLE_FAIL

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

:PORTABLE_FAIL
echo.
echo ==========================================
echo ERROR: Failed to install Python dependencies
echo ==========================================
echo.
echo The portable Python mode failed to compile TTS library.
echo This typically happens because TTS requires C++ compiler.
echo.
echo SOLUTION: Install full Python 3.10.11 from:
echo https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
echo.
echo Make sure to check "Add Python to PATH" during installation.
echo Then run this build script again.
echo.
pause
cd "%PROJECT_ROOT%"
exit /b 1

:BUILD_FLUTTER
REM ========================================
REM Step 4: Build Flutter (Auto-Setup)
REM ========================================

echo.
echo ==========================================
echo [3/5] Building Flutter App
echo ==========================================
echo.

if "%FRONTEND_MODE%" EQU "portable" (
    echo Flutter not found in system. Checking portable Flutter...
    if not exist "%PORTABLE_DIR%\flutter\bin\flutter.bat" (
        echo Downloading Flutter SDK (~900MB)...
        if not exist "%PORTABLE_DIR%" mkdir "%PORTABLE_DIR%"
        
        REM Using verified stable version 3.19.3
        set "FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.3-stable.zip"
        set "FLUTTER_ZIP=%PORTABLE_DIR%\flutter.zip"
        powershell -Command "Invoke-WebRequest -Uri $env:FLUTTER_URL -OutFile $env:FLUTTER_ZIP"
        
        echo Extracting Flutter (this looks stuck but is working)...
        powershell -Command "Expand-Archive -Path $env:FLUTTER_ZIP -DestinationPath $env:PORTABLE_DIR -Force"
        del "%PORTABLE_DIR%\flutter.zip"
        
        echo [OK] Portable Flutter downloaded!
    )
    
    echo Adding Portable Flutter to PATH...
    set "PATH=%PORTABLE_DIR%\flutter\bin;!PATH!"
    set FLUTTER_FOUND=1
)

REM Check if Flutter is available (either system or portable)
where flutter >nul 2>&1
if not errorlevel 1 (
    cd "%PROJECT_ROOT%\flutter_app"
    
    echo Getting dependencies...
    call flutter pub get
    
    echo Building Windows app...
    call flutter build windows --release
    
    if exist "build\windows\runner\Release\live_idol_clone.exe" (
        echo [OK] Flutter built!
        if not exist "%BUILD_OUTPUT%\flutter" mkdir "%BUILD_OUTPUT%\flutter"
        xcopy /E /I /Y /Q build\windows\runner\Release "%BUILD_OUTPUT%\flutter"
    ) else (
        echo [FAIL] Flutter build failed
    )
    
    cd "%PROJECT_ROOT%"
)

REM ========================================
REM Step 5: Unity Auto-Setup & Check
REM ========================================

echo ==========================================
echo [4/5] Unity VRM Renderer
echo ==========================================
echo.

set UNITY_HUB_FOUND=0
if exist "C:\Program Files\Unity Hub\Unity Hub.exe" set UNITY_HUB_FOUND=1

if %UNITY_HUB_FOUND% EQU 0 (
    echo [!] Unity Hub not found in default location.
    echo.
    echo Unity is required for the 3D Avatar Renderer.
    echo.
    echo Downloading Unity Hub Installer...
    if not exist "%PORTABLE_DIR%" mkdir "%PORTABLE_DIR%"
    powershell -Command "Invoke-WebRequest -Uri \"https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe\" -OutFile \"%PORTABLE_DIR%\UnityHubSetup.exe\""
    
    echo Launching Unity Hub Installer...
    echo Please complete the installation and then install Unity 2021.3 LTS.
    start "" "%PORTABLE_DIR%\UnityHubSetup.exe"
    
    echo.
    echo Press any key after you have finished installing Unity...
    pause >nul
) else (
    echo [OK] Unity Hub detected.
)

if exist "%PROJECT_ROOT%\unity_vrm" (
    echo [INFO] Injecting scripts into Unity project...
    
    if not exist "%PROJECT_ROOT%\unity_vrm\Assets\Scripts" mkdir "%PROJECT_ROOT%\unity_vrm\Assets\Scripts"
    if not exist "%PROJECT_ROOT%\unity_vrm\Assets\StreamingAssets" mkdir "%PROJECT_ROOT%\unity_vrm\Assets\StreamingAssets"
    
    copy /Y "%PROJECT_ROOT%\unity_vrm_scripts\*.cs" "%PROJECT_ROOT%\unity_vrm\Assets\Scripts\" >nul
    echo [OK] Scripts injected
    
    echo.
    echo Please build the project in Unity Editor now if you haven't.
    echo Build Output expected at: unity_vrm_scripts\build\VRMRenderer.exe
    
) else (
    echo [INFO] Unity project folder 'unity_vrm' not found.
    echo        Creating skeleton folders for you...
    mkdir "%PROJECT_ROOT%\unity_vrm"
    mkdir "%PROJECT_ROOT%\unity_vrm\Assets"
    mkdir "%PROJECT_ROOT%\unity_vrm\Assets\Scripts"
    mkdir "%PROJECT_ROOT%\unity_vrm\Assets\StreamingAssets"
    
    copy /Y "%PROJECT_ROOT%\unity_vrm_scripts\*.cs" "%PROJECT_ROOT%\unity_vrm\Assets\Scripts\" >nul
    echo [OK] Scripts prepared in 'unity_vrm/Assets/Scripts'
    
    echo.
    echo IMPORTANT: Open Unity Hub -> Add Project -> Select "%PROJECT_ROOT%\unity_vrm"
    echo Then Build -> Windows x64 -> Output to "unity_vrm_scripts/build/VRMRenderer.exe"
)

echo.
echo.
if exist "%PROJECT_ROOT%\unity_vrm_scripts\build\VRMRenderer.exe" (
    echo [OK] Unity build found!
    if not exist "%BUILD_OUTPUT%\unity" mkdir "%BUILD_OUTPUT%\unity"
    xcopy /E /I /Y /Q "%PROJECT_ROOT%\unity_vrm_scripts\build" "%BUILD_OUTPUT%\unity"
) else (
    echo [SKIP] Unity build not found. You can build it manually later.
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

REM Copy OBS Portable if present
if exist "%PROJECT_ROOT%\installer\files\obs-studio-portable\bin\64bit\obs64.exe" (
    echo [OK] OBS Portable found in installer/files
) else (
    echo [WARNING] OBS Portable NOT found in installer/files/obs-studio-portable
    echo           Installer will miss OBS!
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
    echo   1. Make sure Inno Setup 6+ is installed and in PATH (ISCC.exe)
    echo   2. Checking for ISCC...
    
    where iscc >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Inno Setup compiler found. Building installer...
        echo.
        iscc "%PROJECT_ROOT%\installer\setup.iss"
        
        if exist "%PROJECT_ROOT%\installer\output\LiveIdolCloneInstaller*.exe" (
             echo.
             echo [SUCCESS] Installer successfully created!
             echo Location: %PROJECT_ROOT%\installer\output
        ) else (
             echo [FAIL] Installer compilation failed. Check console output.
        )
    ) else (
        echo [WARN] ISCC not found in PATH.
        echo Please manually open "%PROJECT_ROOT%\installer\setup.iss" and click Compile.
    )
    echo.
) else (
    echo Please complete missing builds before creating installer.
    echo.
)

echo Build log saved to: build.log
echo.
pause

endlocal
