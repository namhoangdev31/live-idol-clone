# Live Idol Clone - Project Structure

Complete directory structure of the implemented PoC.

```
live-idol-clone/
│
├── README.md                    # User documentation
├── BUILD.md                     # Build instructions
├── QUICKSTART.md                # Quick start guide
│
├── backend/                     # Django Backend (TTS API)
│   ├── manage.py                # Django management script
│   ├── run_server.py            # Server entry point (for PyInstaller)
│   ├── build_backend.py         # PyInstaller build script
│   ├── requirements.txt         # Python dependencies
│   │
│   ├── config/                  # Django configuration
│   │   ├── __init__.py
│   │   ├── settings.py          # Settings with TTS config
│   │   ├── urls.py              # Main URL routing
│   │   └── wsgi.py              # WSGI application
│   │
│   ├── api/                     # REST API app
│   │   ├── __init__.py
│   │   ├── apps.py              # App config with TTS init
│   │   ├── views.py             # API endpoints
│   │   ├── urls.py              # API URL routing
│   │   └── tts_engine.py        # Coqui TTS wrapper
│   │
│   ├── voice_profiles/          # Voice profiles for cloning
│   │   └── default/
│   │       └── README.md        # Instructions for voice setup
│   │
│   ├── output/                  # Generated audio files (created at runtime)
│   └── dist/                    # PyInstaller output (after build)
│       └── LiveIdolBackend.exe  # Standalone backend
│
├── flutter_app/                 # Flutter Windows App
│   ├── pubspec.yaml             # Flutter dependencies
│   │
│   ├── lib/
│   │   ├── main.dart            # App entry point + splash screen
│   │   │
│   │   ├── screens/
│   │   │   └── home_screen.dart # Main UI screen
│   │   │
│   │   ├── services/
│   │   │   ├── backend_service.dart  # Backend lifecycle management
│   │   │   └── api_client.dart       # HTTP client for API
│   │   │
│   │   ├── models/
│   │   │   └── api_models.dart       # Data models
│   │   │
│   │   └── widgets/
│   │       └── status_indicator.dart # Status UI component
│   │
│   └── build/windows/runner/Release/  # Flutter build output
│       ├── live_idol_clone.exe        # Main executable
│       └── ... (other Flutter runtime files)
│
├── unity_vrm_scripts/           # Unity C# Scripts (ready to use)
│   ├── VRMLoader.cs             # Load VRM avatar + camera setup
│   ├── LipSync.cs               # RMS-based lip sync
│   ├── AudioReceiver.cs         # Watch and play audio files
│   └── IdleAnimation.cs         # Blinking and head movement
│
├── unity_vrm/                   # Unity Project (to be created)
│   │                            # NOTE: Create manually in Unity
│   ├── Assets/
│   │   ├── Scenes/
│   │   │   └── MainScene.unity
│   │   │
│   │   ├── Scripts/             # Copy .cs files here
│   │   │   ├── VRMLoader.cs
│   │   │   ├── LipSync.cs
│   │   │   ├── AudioReceiver.cs
│   │   │   └── IdleAnimation.cs
│   │   │
│   │   ├── StreamingAssets/     # Place VRM avatar here
│   │   │   └── avatar.vrm
│   │   │
│   │   └── UniVRM/              # Import UniVRM package
│   │
│   └── Build/                   # Unity build output
│       ├── VRMRenderer.exe
│       └── ... (Unity runtime files)
│
└── installer/                   # Windows Installer
    ├── setup.iss                # Inno Setup script
    │
    ├── files/                   # Files to include in installer
    │   ├── backend/
    │   │   └── LiveIdolBackend.exe
    │   │
    │   ├── flutter/             # Flutter build output
    │   │   └── ...
    │   │
    │   ├── unity/               # Unity build output
    │   │   └── ...
    │   │
    │   └── assets/              # Sample assets
    │       ├── avatar.vrm
    │       └── voice_profiles/
    │
    └── output/                  # Installer output
        └── LiveIdolCloneInstaller_1.0.0.exe
```

## Key Files by Component

### Django Backend
- **Entry Point**: `backend/run_server.py`
- **TTS Engine**: `backend/api/tts_engine.py`
- **API Views**: `backend/api/views.py`
- **Build Script**: `backend/build_backend.py`

### Flutter App
- **Entry Point**: `flutter_app/lib/main.dart`
- **Main Screen**: `flutter_app/lib/screens/home_screen.dart`
- **Backend Service**: `flutter_app/lib/services/backend_service.dart`
- **API Client**: `flutter_app/lib/services/api_client.dart`

### Unity VRM Renderer
- **VRM Loader**: `unity_vrm_scripts/VRMLoader.cs`
- **Lip Sync**: `unity_vrm_scripts/LipSync.cs`
- **Audio Receiver**: `unity_vrm_scripts/AudioReceiver.cs`
- **Idle Animation**: `unity_vrm_scripts/IdleAnimation.cs`

### Installer
- **Inno Setup Script**: `installer/setup.iss`

### Documentation
- **User Guide**: `README.md`
- **Build Instructions**: `BUILD.md`
- **Quick Start**: `QUICKSTART.md`
- **Walkthrough**: (in brain directory)

## Data Flow

```
User Input (Flutter)
    ↓
POST /api/speak (Django)
    ↓
Coqui TTS (Voice Cloning)
    ↓
audio.wav → backend/output/
    ↓
Unity AudioReceiver detects file
    ↓
Unity plays audio + LipSync animates mouth
    ↓
OBS captures Unity window + VB-CABLE audio
    ↓
Stream Output
```

## Build Outputs

After building all components:

1. **Backend**: `backend/dist/LiveIdolBackend.exe` (~500MB)
2. **Flutter**: `flutter_app/build/windows/runner/Release/` (~50MB)
3. **Unity**: `unity_vrm/Build/VRMRenderer.exe` (~100MB)
4. **Installer**: `installer/output/LiveIdolCloneInstaller_1.0.0.exe` (~650MB)

## Runtime Directories

When the app is running:

- **Backend Output**: `backend/output/*.wav` (generated audio)
- **Backend Logs**: Console output
- **Flutter Logs**: Console output
- **Unity Logs**: Unity console / log files

## Installation Directories

After installation via installer:

```
C:\Program Files\LiveIdolClone\
├── live_idol_clone.exe         # Flutter app
├── flutter_windows.dll
├── data/                        # Flutter assets
│
├── backend/
│   ├── LiveIdolBackend.exe
│   ├── output/                  # Generated audio
│   └── voice_profiles/          # Voice samples
│       └── default/
│           └── reference.wav
│
├── unity/
│   ├── VRMRenderer.exe
│   └── ... (Unity data files)
│
├── assets/
│   └── avatar.vrm
│
├── README.md
└── BUILD.md
```

## Development vs Production Paths

### Development

- Backend: Run with `python run_server.py`
- Flutter: Run with `flutter run -d windows`
- Unity: Run in Unity Editor

### Production (Installed)

- Backend: Auto-started by Flutter app
- Flutter: Launched by user (`live_idol_clone.exe`)
- Unity: Launched separately or auto-launched

## File Size Estimates

| Component | Development | Production | Notes |
|-----------|-------------|------------|-------|
| Backend | ~2GB | ~500MB | PyInstaller compression |
| Flutter | ~100MB | ~50MB | Release build |
| Unity | ~500MB | ~100MB | Depends on VRM size |
| Installer | - | ~650MB | All components |
| TTS Models | ~2GB | Shared | Downloaded on first run |

## Configuration Files

- **Django Settings**: `backend/config/settings.py`
  - TTS_DEVICE (cpu/cuda)
  - VOICE_PROFILES_DIR
  - OUTPUT_DIR

- **Flutter API**: `flutter_app/lib/services/api_client.dart`
  - baseUrl (default: http://127.0.0.1:8000/api)

- **Unity Audio**: `unity_vrm_scripts/AudioReceiver.cs`
  - watchDirectory (backend output path)

## Environment Variables

Not required for basic operation, but can be set:

- `DJANGO_SETTINGS_MODULE=config.settings`
- `TTS_HOME` (for Coqui TTS cache)

## Dependencies Summary

### Backend (Python)
- Django 4.2
- Django REST Framework
- Coqui TTS (with XTTS-v2)
- PyTorch
- soundfile, pydub

### Flutter (Dart)
- http (HTTP client)
- path (Path utilities)
- Material Design

### Unity (C#)
- UniVRM (VRM support)
- Unity 2021.3 LTS+

### System
- VB-CABLE (Virtual audio device)
- OBS Studio (For capturing)

## Port Usage

- **8000**: Django backend (local only)
- No other ports required

## File Extensions

- `.vrm` - VRM avatar model
- `.wav` - Audio files (input/output)
- `.exe` - Executables (Windows)
- `.dll` - Dynamic libraries

---

This structure is designed for:
- ✅ Modularity (each component independent)
- ✅ Clarity (clear separation of concerns)
- ✅ Maintainability (easy to update individual parts)
- ✅ Deployability (all packaged into single installer)
