# Quick Start Guide

Get Live Idol Clone up and running quickly for testing and development.

## For Developers (Testing Without Building)

### 1. Backend Setup

```bash
# Install Python dependencies
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Run backend
python run_server.py
```

Backend will start on `http://127.0.0.1:8000`

**Test it:**
```bash
curl http://127.0.0.1:8000/api/health
```

Expected response:
```json
{
  "status": "ok",
  "tts_ready": true,
  "device": "cpu"
}
```

### 2. Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutter run -d windows
```

The app should:
1. Show splash screen
2. Auto-start backend (if built) or connect to running backend
3. Display main UI with status indicators

### 3. Unity VRM Renderer Setup

1. Open Unity Hub
2. Open project at `unity_vrm/`
3. Install UniVRM package:
   - Download from https://github.com/vrm-c/UniVRM/releases
   - Import via Assets → Import Package → Custom Package

4. Add a sample VRM:
   - Download a sample from https://hub.vroid.com/
   - Place in `Assets/StreamingAssets/`
   - Update `VRMLoader.cs` to reference your VRM file

5. Create Main Scene:
   - Add an empty GameObject named "VRMController"
   - Attach `VRMLoader.cs` script
   - Attach other scripts (`LipSync.cs`, `AudioReceiver.cs`, `IdleAnimation.cs`)

6. Press Play to test

## Quick Test Workflow

### Test TTS Generation

Using curl or Postman:

```bash
curl -X POST http://127.0.0.1:8000/api/speak \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test of the voice cloning system."}'
```

Expected response:
```json
{
  "audio_path": "C:\\path\\to\\backend\\output\\speech_1234567890.wav",
  "duration_ms": 3500,
  "generation_time_ms": 2100,
  "voice_profile": "default",
  "status": "success"
}
```

Audio file will be created in `backend/output/`

### Test Flutter → Backend

1. Run backend (`python run_server.py`)
2. Run Flutter app (`flutter run -d windows`)
3. Enter text: "Hello world"
4. Click "Speak"
5. Check status message for success/error

### Test Unity → Audio Sync

1. Run backend
2. Generate audio via Flutter or curl
3. Unity should detect new audio file in `backend/output/`
4. Audio plays automatically
5. Avatar mouth should animate

## Test OBS Integration

### Video Capture

1. Open OBS
2. Add Source → Window Capture
3. Select Unity window
4. Position and resize as needed

### Audio Capture

1. Install VB-CABLE (https://vb-audio.com/Cable/)
2. In Windows Sound Settings:
   - Set default playback device to "CABLE Input"
3. In OBS:
   - Add Source → Audio Input Capture
   - Select "CABLE Output"

### Full Test

1. Start all components (Backend, Flutter, Unity)
2. Configure OBS as above
3. Start OBS recording
4. Generate speech via Flutter app
5. Watch OBS preview - you should see:
   - Unity avatar visible
   - Avatar mouth moving
   - Audio playing in sync

## Troubleshooting Quick Fixes

### Backend won't start
```bash
# Check Python version
python --version  # Should be 3.10+

# Check port availability
netstat -ano | findstr :8000

# Kill process using port 8000 (if needed)
taskkill /PID <PID> /F
```

### TTS takes forever
```python
# Edit backend/config/settings.py
TTS_DEVICE = 'cpu'  # Force CPU mode

# Or download models manually first:
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')"
```

### Flutter can't find backend
```dart
// Edit flutter_app/lib/services/api_client.dart
ApiClient({
  this.baseUrl = 'http://127.0.0.1:8000/api',  // Ensure correct URL
})
```

### Unity can't find audio files
```csharp
// Edit AudioReceiver.cs in Unity
public string watchDirectory = @"C:\full\path\to\backend\output";
```

### OBS no audio
1. Check VB-CABLE is installed
2. Check default playback device in Windows
3. Restart OBS after installing VB-CABLE
4. Check audio source is "CABLE Output" not input

## Development Tips

### Fast Iteration

**Backend changes:**
```bash
# Just restart the server
python run_server.py
```

**Flutter changes:**
```bash
# Hot reload with 'r' or hot restart with 'R' in terminal
# Or rebuild:
flutter run -d windows
```

**Unity changes:**
- Just press Play again in Unity Editor

### Voice Profile Setup

For better voice cloning:

1. Record 5-10 seconds of clear speech
2. Save as WAV (16-bit, 22050 Hz)
3. Place in `backend/voice_profiles/default/reference.wav`
4. Restart backend
5. Test with `/api/speak`

### Debugging

**Backend logs:**
```bash
# Run with verbose logging
python run_server.py
# Check terminal output
```

**Flutter logs:**
```bash
flutter run -d windows --verbose
# Or use print() statements
```

**Unity logs:**
- Check Unity Console window
- Use Debug.Log() in scripts

## Performance Optimization

### TTS Speed

**Use GPU** (if available):
```python
# backend/config/settings.py
TTS_DEVICE = 'cuda'
```

Install PyTorch with CUDA:
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

### Reduce Latency

1. **Backend**: Keep it running (don't restart)
2. **Unity**: Build to executable (faster than editor)
3. **Audio**: Use smaller text chunks

## Next Steps

Once comfortable with the above:

1. Build standalone executables (see BUILD.md)
2. Test installer on clean VM
3. Add custom VRM avatars
4. Record custom voice profiles
5. Configure OBS scenes for your stream

## Quick Reference

| Component | Port/Path | Command |
|-----------|-----------|---------|
| Backend | http://127.0.0.1:8000 | `python run_server.py` |
| Flutter | - | `flutter run -d windows` |
| Unity | - | Open in Unity Editor |
| Audio Output | `backend/output/` | Auto-generated |
| Voice Profiles | `backend/voice_profiles/default/` | Place reference.wav here |

## Support

- Check README.md for detailed documentation
- Check BUILD.md for build instructions
- Review logs in console/terminal
- Check GitHub Issues for common problems
