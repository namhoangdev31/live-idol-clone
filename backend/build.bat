@echo off
REM Build Backend Script for Windows
REM This script automates the Django backend build process

echo ========================================
echo Live Idol Clone - Backend Build Script
echo ========================================
echo.

REM Check if we're in the backend directory
if not exist "requirements.txt" (
    echo ERROR: requirements.txt not found!
    echo Please run this script from the backend directory.
    pause
    exit /b 1
)

echo Step 1: Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

echo.
echo Step 2: Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Step 3: Installing dependencies...
pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller

if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Step 4: Downloading TTS models (this may take a while - ~2GB)...
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')"

if errorlevel 1 (
    echo WARNING: TTS model download failed - will try during build
)

echo.
echo Step 5: Building backend with PyInstaller...
python build_backend.py

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
echo Output: dist\LiveIdolBackend.exe
echo.
echo To test the backend, run:
echo   cd dist
echo   LiveIdolBackend.exe
echo.
pause
