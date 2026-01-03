@echo off
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%CD%"
set "PORTABLE_DIR=%PROJECT_ROOT%\portable_tools"
set "FRONTEND_MODE=portable"

echo Testing Flutter section...
echo.

if "%FRONTEND_MODE%" EQU "portable" (
    echo Flutter not found in system. Checking portable Flutter...
    if not exist "%PORTABLE_DIR%\flutter\bin\flutter.bat" (
        echo Downloading Flutter SDK (~900MB)...
        if not exist "%PORTABLE_DIR%" mkdir "%PORTABLE_DIR%"
        
        REM Using verified stable version 3.19.3
        set "FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.3-stable.zip"
        set "FLUTTER_ZIP=%PORTABLE_DIR%\flutter.zip"
        powershell -Command "& {Invoke-WebRequest -Uri $env:FLUTTER_URL -OutFile $env:FLUTTER_ZIP}"
        
        echo Extracting Flutter...
        powershell -Command "& {Expand-Archive -Path $env:FLUTTER_ZIP -DestinationPath $env:PORTABLE_DIR -Force}"
        del "%PORTABLE_DIR%\flutter.zip"
        
        echo [OK] Portable Flutter downloaded!
    )
    
    echo Adding Portable Flutter to PATH...
    set "PATH=%PORTABLE_DIR%\flutter\bin;!PATH!"
)

echo.
echo Test complete!
pause
