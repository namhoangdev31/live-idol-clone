# Live Idol Clone - Complete Documentation

**Comprehensive guide for building and deploying the Voice Clone + VRM Avatar PoC**

---

# Table of Contents

1. [Overview & Quick Start](#overview--quick-start)
2. [System Requirements](#system-requirements)
3. [Installation & Usage](#installation--usage)
4. [Build Instructions](#build-instructions)
5. [Unity Setup Guide](#unity-setup-guide)
6. [Installer Creation](#installer-creation)
7. [OBS Configuration](#obs-configuration)
8. [Project Structure](#project-structure)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

# Overview & Quick Start

## What is Live Idol Clone?

A proof-of-concept system combining:
- **Consent-based voice cloning** using Coqui TTS XTTS-v2
- **3D VRM avatar rendering** with Unity + UniVRM
- **Real-time OBS integration** for livestreaming

All processing happens **locally on Windows** with no cloud dependencies.

## Quick Start (Production Build)

### Automated Build (Recommended)

**On Windows**:
```batch
build_all.bat
```

**On macOS/Linux** (prepare files only):
```bash
chmod +x build_production.sh
./build_production.sh
```

Then transfer to Windows and run final build.

## Components

```
┌─────────────┐    ┌──────────────┐    ┌────────────┐    ┌───────┐
│ Flutter UI  │───▶│ Django API   │───▶│ Unity VRM  │───▶│  OBS  │
│ (Windows)   │    │ (TTS Engine) │    │ (Avatar)   │    │       │
└─────────────┘    └──────────────┘    └────────────┘    └───────┘
```

---

# System Requirements

## Minimum Requirements

- **OS**: Windows 10/11 (64-bit)
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **GPU**: Optional (4GB+ VRAM recommended for faster TTS)

## Required Software (For Building)

1. **Python 3.10 or 3.11**
   - Download: https://www.python.org/downloads/
   - Add to PATH during installation

2. **Flutter SDK**
   - Download: https://flutter.dev/docs/get-started/install/windows
   - Run `flutter doctor` to verify

3. **Unity 2021.3 LTS or newer**
   - Download: https://unity.com/download
   - Install with Windows Build Support

4. **Inno Setup 6+** (for installer)
   - Download: https://jrsoftware.org/isdl.php

5. **Visual Studio 2019/2022**
   - Desktop development with C++ workload

6. **VB-CABLE** (for audio routing)
   - Download: https://vb-audio.com/Cable/

---

# Installation & Usage

## For End Users

### Install from Installer

1. Download `LiveIdolCloneInstaller.exe`
2. Run installer and follow prompts
3. Install VB-CABLE when prompted
4. Restart computer
5. Launch "Live Idol Clone" from Start Menu

### Using the App

1. **Launch app** - Wait for backend to initialize (~10-15s)
2. **Check status** - Ensure "Backend" and "TTS Engine" indicators are green
3. **Enter text** - Type your message (max 1000 characters)
4. **Click "Speak"** - Audio generates in 2-10 seconds
5. **View in OBS** - Avatar animates with your voice

### Voice Profile Setup (Optional)

For better voice cloning:

1. Navigate to: `C:\Program Files\LiveIdolClone\backend\voice_profiles\default\`
2. Record 5-10 second audio sample (WAV, 16-bit, 22050 Hz)
3. Save as `reference.wav`
4. Restart app

---

# Build Instructions

## Prerequisites Setup

### 1. Install Python

```bash
# Download Python 3.10 or 3.11
# On Windows:
python --version  # Verify installation
```

### 2. Install Flutter

```bash
# Download and extract Flutter SDK
# Add to PATH
flutter doctor  # Fix any issues
```

### 3. Install Unity

- Download Unity Hub
- Install Unity 2021.3 LTS
- Add Windows Build Support module

### 4. Install Build Tools

- Visual Studio with C++ tools
- Inno Setup compiler

## Building Components

### Backend (Django + TTS)

**Windows**:
```batch
cd backend
build.bat
```

**Manual steps**:
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # macOS/Linux

pip install -r requirements.txt
pip install pyinstaller

# Download TTS models (~2GB)
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')"

# Build executable
python build_backend.py
```

**Output**: `backend/dist/LiveIdolBackend.exe`

### Flutter Windows App

**Windows**:
```batch
cd flutter_app
build.bat
```

**Manual steps**:
```bash
cd flutter_app
flutter pub get
flutter build windows --release
```

**Output**: `flutter_app/build/windows/runner/Release/live_idol_clone.exe`

### Testing Individual Components

**Test Backend**:
```bash
cd backend/dist
./LiveIdolBackend.exe  # Windows
# OR
python ../run_server.py  # Development

# Test health endpoint
curl http://127.0.0.1:8000/api/health

# Test TTS
curl -X POST http://127.0.0.1:8000/api/speak \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello world"}'
```

**Test Flutter**:
```bash
cd flutter_app
flutter run -d windows  # Development
# OR
cd build/windows/runner/Release
./live_idol_clone.exe  # Production
```

---

# Unity Setup Guide

## Step 1: Create Project

1. Open Unity Hub
2. New Project → 3D Core template
3. Name: `UnityVRMRenderer`
4. Location: `live-idol-clone/unity_vrm/`

## Step 2: Import UniVRM

1. Download from: https://github.com/vrm-c/UniVRM/releases
2. Assets → Import Package → Custom Package
3. Select `.unitypackage` → Import All

## Step 3: Add Scripts

1. Create folder: `Assets/Scripts/`
2. Copy all `.cs` files from `unity_vrm_scripts/` to `Assets/Scripts/`

### Scripts to Add:
- `VRMLoader.cs` - Loads VRM avatar
- `LipSync.cs` - Audio-driven mouth animation
- `AudioReceiver.cs` - Watches for new audio files
- `IdleAnimation.cs` - Blinking and head movement

## Step 4: Get VRM Avatar

**Option A**: Download from VRoid Hub
- Visit: https://hub.vroid.com/
- Download free VRM avatar

**Option B**: Create in VRoid Studio
- Download VRoid Studio
- Create custom avatar
- Export as VRM

## Step 5: Setup Scene

1. **Create StreamingAssets**:
   - Right-click Assets → Create → Folder
   - Name: `StreamingAssets`
   - Copy `avatar.vrm` here

2. **Create VRMController GameObject**:
   - GameObject → Create Empty
   - Rename: `VRMController`

3. **Add Components to VRMController**:
   - Add Component → `VRMLoader`
   - Add Component → `LipSync`  
   - Add Component → `AudioReceiver`
   - Add Component → `IdleAnimation`
   - Add Component → `Audio Source`

4. **Configure VRMLoader**:
   - VRM File Path: `avatar.vrm`

5. **Configure AudioReceiver**:
   - Watch Directory: `C:\path\to\backend\output`
   - Update to match your installation path

6. **Save Scene**:
   - File → Save As → `MainScene`

## Step 6: Build Unity Executable

1. File → Build Settings
2. Add Open Scenes
3. Platform: PC, Mac & Linux Standalone
4. Target: Windows x86_64
5. Click Build
6. Output: `unity_vrm/Build/VRMRenderer.exe`

---

# Installer Creation

## Prepare Files

### 1. Create Directory Structure

```bash
cd installer
mkdir -p files/backend files/flutter files/unity files/assets
```

### 2. Copy Built Files

```batch
# Backend
copy ..\backend\dist\LiveIdolBackend.exe files\backend\

# Flutter
xcopy /E /I ..\flutter_app\build\windows\runner\Release\* files\flutter\

# Unity
xcopy /E /I ..\unity_vrm\Build\* files\unity\

# Assets
copy ..\backend\voice_profiles\default\README.md files\assets\voice_profiles\default\
```

### 3. Verify Files

Check that `installer/files/` contains:
- `backend/LiveIdolBackend.exe` (~500MB)
- `flutter/live_idol_clone.exe` + runtime files
- `unity/VRMRenderer.exe` + data folders
- `assets/` with voice profile README

## Build Installer

### Using Inno Setup GUI

1. Open `installer/setup.iss` in Inno Setup Compiler
2. Build → Compile (Ctrl+F9)
3. Output: `installer/output/LiveIdolCloneInstaller_1.0.0.exe`

### Using Command Line

```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

## Test Installer

1. Create clean Windows 10/11 VM
2. Copy installer to VM
3. Run installer
4. Test full workflow
5. Test uninstaller

---

# OBS Configuration

## Setup VB-CABLE

1. Download: https://vb-audio.com/Cable/
2. Install and **restart computer**
3. Verify in Windows Sound Settings:
   - Playback: CABLE Input
   - Recording: CABLE Output

## Configure OBS

### Video Capture (Unity Window)

1. Add Source → Window Capture
2. Window: `[VRMRenderer.exe]: Unity`
3. Capture Method: Auto-detect
4. Position and resize as needed

### Audio Capture (Virtual Audio)

1. Add Source → Audio Input Capture
2. Device: `CABLE Output (VB-Audio Virtual Cable)`
3. Adjust volume in mixer

### Test Setup

1. Start Unity VRM Renderer
2. Start Live Idol Clone app
3. Generate speech
4. Check OBS preview:
   - ✅ Avatar visible and animating
   - ✅ Audio playing in sync

---

# Project Structure

## Directory Layout

```
live-idol-clone/
├── backend/                 # Django backend (TTS API)
│   ├── api/                 # REST API endpoints
│   │   ├── tts_engine.py   # Coqui TTS wrapper
│   │   └── views.py        # API views
│   ├── config/              # Django settings
│   ├── voice_profiles/      # Voice samples
│   ├── output/              # Generated audio
│   ├── requirements.txt
│   ├── run_server.py       # Entry point
│   └── build_backend.py    # PyInstaller script
│
├── flutter_app/            # Flutter Windows UI
│   ├── lib/
│   │   ├── main.dart       # App entry + splash
│   │   ├── screens/        # UI screens
│   │   ├── services/       # Backend/API services
│   │   ├── models/         # Data models
│   │   └── widgets/        # UI components
│   └── pubspec.yaml
│
├── unity_vrm_scripts/      # Unity C# scripts
│   ├── VRMLoader.cs
│   ├── LipSync.cs
│   ├── AudioReceiver.cs
│   └── IdleAnimation.cs
│
├── unity_vrm/              # Unity project (manual setup)
│   ├── Assets/
│   │   ├── Scripts/
│   │   └── StreamingAssets/
│   └── Build/
│
├── installer/              # Inno Setup installer
│   ├── setup.iss
│   └── files/             # Files to package
│
├── build_all.bat          # Windows build script
├── build_production.sh    # Unix build script
└── COMPLETE_GUIDE.md      # This file
```

## Key Files

| Component | Entry Point | Config |
|-----------|-------------|--------|
| Backend | `run_server.py` | `config/settings.py` |
| Flutter | `lib/main.dart` | `pubspec.yaml` |
| Unity | `VRMLoader.cs` | Inspector settings |

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/status` - System status
- `POST /api/speak` - Generate speech
  ```json
  {
    "text": "Hello world",
    "voice_profile": "default",
    "language": "en"
  }
  ```
- `GET /api/voice-profiles` - List profiles

---

# Troubleshooting

## Backend Issues

### Backend Won't Start

```bash
# Check Python version
python --version  # Should be 3.10+

# Check port availability
netstat -ano | findstr :8000

# Kill process on port 8000
taskkill /PID <PID> /F
```

### TTS Model Download Fails

```bash
# Manual download
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')"

# Check disk space (needs ~2GB)
```

### TTS Generation Slow

**Solution**: Use GPU
```python
# Edit config/settings.py
TTS_DEVICE = 'cuda'  # Requires CUDA toolkit
```

## Flutter Issues

### Flutter Build Fails

```bash
# Run flutter doctor
flutter doctor -v

# Clean and rebuild
flutter clean
flutter pub get
flutter build windows --release
```

### App Can't Find Backend

Check path in `lib/services/backend_service.dart`:
```dart
final candidates = [
  path.join(executableDir, 'LiveIdolBackend.exe'),
  // Add your path here
];
```

## Unity Issues

### VRM Won't Load

- Verify VRM file in `Assets/StreamingAssets/`
- Check filename matches `VRMLoader.cs` setting
- Ensure UniVRM package imported correctly

### No Lip Sync

- Verify `AudioSource` component attached
- Check audio files generating in backend output
- Verify `AudioReceiver` watch directory path

### Unity Build Errors

- Check Unity version (2021.3 LTS+)
- Reimport UniVRM package
- Check for script compilation errors

## OBS Issues

### No Audio in OBS

1. Install VB-CABLE
2. Restart computer
3. Set default playback to CABLE Input
4. In OBS: select CABLE Output
5. Restart OBS

### Unity Window Not Capturing

- Ensure Unity app is running
- Refresh window list in OBS
- Try "Game Capture" as alternative

## General Issues

| Issue | Solution |
|-------|----------|
| Port 8000 in use | Kill process or change port |
| Python not found | Add to PATH, restart terminal |
| Out of memory | Close other apps, use CPU instead of GPU |
| Files not found | Check absolute paths |

---

# Performance Optimization

## TTS Speed

**Use GPU** (if available):
```python
# config/settings.py
TTS_DEVICE = 'cuda'
```

Install PyTorch with CUDA:
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

## Reduce Latency

1. Keep backend running (don't restart)
2. Use Unity build (not editor)
3. Reduce text length
4. Pre-warm TTS on startup

---

# Development Tips

## Quick Iteration

**Backend**: Just restart server
```bash
python run_server.py
```

**Flutter**: Hot reload (press 'r' in terminal)
```bash
flutter run -d windows
```

**Unity**: Press Play in editor

## Debugging

**Backend logs**: Check terminal output

**Flutter logs**: Use `print()` statements
```dart
print('Debug: $variableName');
```

**Unity logs**: Check Console window
```csharp
Debug.Log("Message");
```

---

# Production Checklist

## Before Distribution

- [ ] All components built successfully
- [ ] Tested on clean Windows VM
- [ ] VB-CABLE installation documented
- [ ] OBS setup guide included
- [ ] Voice profile instructions clear
- [ ] Uninstaller tested
- [ ] Performance acceptable (< 10s TTS)
- [ ] Error handling robust
- [ ] Logs/console output cleaned

## Installer Checklist

- [ ] All files included
- [ ] File paths correct
- [ ] Desktop shortcut works
- [ ] Start Menu entry works
- [ ] Uninstaller removes all files
- [ ] VB-CABLE check functions
- [ ] Installer size reasonable (~650MB)

---

# Estimated Times

| Task | Duration |
|------|----------|
| Install prerequisites | 30-60 min |
| Build backend | 10-20 min |
| Build Flutter | 5-10 min |
| Setup Unity | 20-30 min |
| Build Unity | 5-10 min |
| Create installer | 5 min |
| Test installation | 10-15 min |
| **Total (first time)** | **~2-3 hours** |

---

# Next Steps

1. **On Windows**: Run `build_all.bat`
2. **Setup Unity** following guide above
3. **Create installer** with Inno Setup
4. **Test** on clean VM
5. **Configure OBS** for capture
6. **Go live!** 🎉

---

# Support & Resources

- **Coqui TTS**: https://github.com/coqui-ai/TTS
- **UniVRM**: https://github.com/vrm-c/UniVRM
- **VB-CABLE**: https://vb-audio.com/Cable/
- **Flutter**: https://flutter.dev/
- **Unity**: https://unity.com/

---

**Project Complete and Ready for Production Build!** 🚀
