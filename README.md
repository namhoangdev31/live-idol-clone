# Live Idol Clone - Voice Clone + VRM Avatar PoC

A proof-of-concept system for consent-based voice cloning with 3D VRM avatar, outputting real-time video and audio to OBS for livestreaming.

## 🎯 Features

- **Voice Cloning**: Text-to-Speech with voice cloning using Coqui TTS XTTS-v2
- **3D VRM Avatar**: Real-time avatar rendering and lip-sync animation using Unity + UniVRM
- **OBS Integration**: Video capture via Window Capture, audio via VB-CABLE virtual audio device
- **Local Processing**: Everything runs locally on Windows (no cloud dependencies)
- **Single Installer**: One-click installation with all components

## 📋 System Requirements

- **OS**: Windows 10 or Windows 11 (64-bit)
- **RAM**: 8GB minimum (16GB recommended)
- **GPU**: Optional but recommended (4GB+ VRAM for faster TTS generation)
- **Storage**: ~5GB for installation
- **Additional Software**:
  - [VB-CABLE Virtual Audio Device](https://vb-audio.com/Cable/) (free download)
  - OBS Studio (for capturing output)

## 📦 Installation

### Option 1: Install from Installer (Recommended for End Users)

1. Download `LiveIdolCloneInstaller.exe`
2. Run the installer and follow the prompts
3. Install VB-CABLE if you don't have it already:
   - Download from: https://vb-audio.com/Cable/
   - Install and restart your computer
4. Launch "Live Idol Clone" from Start Menu or Desktop

### Option 2: Build from Source (For Developers)

See [BUILD.md](BUILD.md) for detailed build instructions.

## 🚀 Usage

### 1. Launch the Application

- Open **Live Idol Clone** from the Start Menu or Desktop shortcut
- Wait for the splash screen to initialize the backend (10-15 seconds on first run)
- The main window will appear when ready

### 2. Generate Speech

1. **Check Status**: Ensure "Backend" and "TTS Engine" indicators are green
2. **Enter Text**: Type or paste text in the text field (max 1000 characters)
3. **Click "Speak"**: The system will generate audio with your cloned voice
4. **Wait**: Generation takes 2-10 seconds depending on text length and hardware

### 3. Configure OBS for Livestreaming

#### Video Capture (Unity VRM Avatar)

1. Open **OBS Studio**
2. Add a new **Window Capture** source:
   - **Window**: Select "Unity - VRM Renderer" (or similar)
   - **Capture Method**: Auto-detect (recommended)
3. Position and resize the source in your scene

#### Audio Capture (Virtual Audio)

1. Add a new **Audio Input Capture** source:
   - **Device**: Select "CABLE Output (VB-Audio Virtual Cable)"
2. Adjust audio levels in the mixer

> **Note**: If you don't see the Unity window yet, you need to launch the VRM Renderer component separately (included in installation).

### 4. Configure Voice Profile (Optional)

For better voice cloning quality:

1. Navigate to installation directory (default: `C:\Program Files\LiveIdolClone`)
2. Open `voice_profiles\default\` folder
3. Record a 5-10 second audio sample of your voice:
   - Format: WAV, 16-bit, 22050 Hz
   - Content: Clear speech, no background noise
   - Example: "Hello, my name is [Your Name]. This is a sample of my voice for voice cloning."
4. Save as `reference.wav` in the `voice_profiles\default\` folder
5. Restart the Live Idol Clone app

## 🎬 OBS Scene Setup (Complete Example)

```
Scene: "Live Stream with Avatar"
├── Video Source 1: Window Capture (Unity VRM Renderer)
├── Video Source 2: Your webcam (optional)
├── Audio Input 1: CABLE Output (VB-Audio Virtual Cable)
└── Audio Input 2: Your microphone (optional)
```

## 🛠️ Troubleshooting

### Backend Not Starting

**Problem**: Red "Backend" status indicator

**Solutions**:
1. Check if port 8000 is already in use by another application
2. Run as Administrator
3. Check Windows Firewall settings
4. Reinstall the application

### TTS Engine Not Ready

**Problem**: Red "TTS Engine" status indicator

**Solutions**:
1. Wait 30-60 seconds (TTS model loading can be slow on first run)
2. Check if you have enough RAM available
3. For GPU errors, switch to CPU mode (see Configuration)

### No Voice Cloning (Default Voice)

**Problem**: Using default TTS voice instead of cloned voice

**Solutions**:
1. Add a voice profile (see "Configure Voice Profile" above)
2. Ensure `reference.wav` exists in `voice_profiles\default\`
3. Check audio file format (must be WAV)

### OBS Not Capturing Audio

**Problem**: No audio in OBS from the avatar

**Solutions**:
1. Ensure VB-CABLE is installed and working
2. In OBS, select "CABLE Output" as audio input device
3. Check Windows Sound Settings → Recording → ensure CABLE is enabled
4. Restart OBS after installing VB-CABLE

### Unity Window Not Appearing

**Problem**: Can't find Unity VRM Renderer window to capture

**Solutions**:
1. Launch `VRMRenderer.exe` manually from installation directory
2. Check if the window is minimized or on another monitor
3. In OBS, refresh the window list when adding Window Capture

## ⚙️ Configuration

### Use CPU Instead of GPU for TTS

If you're experiencing GPU errors or don't have a dedicated GPU:

1. Navigate to installation directory
2. Open `config\settings.py` in a text editor
3. Change `TTS_DEVICE = 'cuda'` to `TTS_DEVICE = 'cpu'`
4. Restart the application

**Note**: CPU mode is slower (5-15 seconds per generation) but works on all systems.

### Change Backend Port

If port 8000 is already in use:

1. Open `config\settings.py`
2. Change port in the startup script
3. Update `lib\services\api_client.dart` in Flutter app to match

## 📝 Technical Details

### Architecture

```
┌─────────────────┐
│  Flutter App    │  ← User Interface (Windows Desktop)
│   (Port 8080)   │
└────────┬────────┘
         │ HTTP REST API
         ▼
┌─────────────────┐
│  Django Backend │  ← TTS Orchestration
│   (Port 8000)   │
└────────┬────────┘
         │
         ├─── Coqui TTS XTTS-v2 (Voice Cloning)
         └─── Audio Output → VB-CABLE
         
┌─────────────────┐
│  Unity + UniVRM │  ← 3D Avatar Rendering + Lip Sync
│      Renderer   │
└────────┬────────┘
         │
         └─── Window Output → OBS Window Capture

┌─────────────────┐
│   OBS Studio    │  ← Stream/Record Composition
└─────────────────┘
```

### API Endpoints

- `GET /api/health` - Health check
- `GET /api/status` - System status and voice profiles
- `POST /api/speak` - Generate speech from text
- `GET /api/voice-profiles` - List available voice profiles

## 🔒 Privacy & Consent

- All processing is done locally on your machine
- No data is sent to external servers
- Voice profiles are stored locally and never uploaded
- Only use voice recordings you have explicit consent to clone

## 📄 License

This is a proof-of-concept project. For production use, ensure compliance with voice cloning and AI-generated content regulations in your jurisdiction.

## 🆘 Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review the logs in `logs\` directory (if available)
3. Create an issue in the project repository

## 🙏 Credits

- **Coqui TTS**: https://github.com/coqui-ai/TTS
- **UniVRM**: https://github.com/vrm-c/UniVRM
- **VB-CABLE**: https://vb-audio.com/Cable/
- **Django**: https://www.djangoproject.com/
- **Flutter**: https://flutter.dev/
