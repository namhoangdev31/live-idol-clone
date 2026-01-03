@echo off
setlocal enabledelayedexpansion

set "PORTABLE_DIR=C:\temp\test"
set "FLUTTER_URL=https://example.com/flutter.zip"
set "FLUTTER_ZIP=%PORTABLE_DIR%\flutter.zip"

echo URL: !FLUTTER_URL!
echo ZIP: !FLUTTER_ZIP!

echo.
echo Testing PowerShell with env vars...
powershell -Command "Write-Host $env:FLUTTER_URL"
powershell -Command "Write-Host $env:FLUTTER_ZIP"

echo.
echo Done!
pause
