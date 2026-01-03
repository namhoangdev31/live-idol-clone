@echo off
echo Compressing build artifacts...

if not exist "build_output" (
    echo [ERROR] build_output folder not found!
    pause
    exit /b 1
)

:: Use PowerShell to zip the folder
powershell -Command "Compress-Archive -Path build_output -DestinationPath LiveIdolClone_Builds.zip -Force"

if exist "LiveIdolClone_Builds.zip" (
    echo.
    echo [SUCCESS] Created LiveIdolClone_Builds.zip
    echo.
    echo You can now upload this file to GitHub Releases or Google Drive.
) else (
    echo.
    echo [FAIL] Failed to create zip file.
)

pause
