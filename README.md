# Live Idol Clone

**Voice Cloning + 3D VRM Avatar cho Livestream**

Hệ thống PoC kết hợp Coqui TTS voice cloning và Unity VRM avatar, xuất real-time video + audio vào OBS. Chạy hoàn toàn offline trên Windows.

---

## 🎯 Tính Năng

- ✅ **Voice Cloning** - Clone giọng từ audio mẫu 5-10s
- ✅ **3D VRM Avatar** - Render avatar với lip-sync
- ✅ **OBS Integration** - Video + Audio real-time
- ✅ **Offline** - Chạy 100% local, không cần internet

---

## 📦 Build (Dành Cho Developer)

### Quick Start ⚡

```batch
build.bat
```

**Chỉ 1 lệnh!** Script tự động:
- ✅ Detect Python/Flutter có sẵn hay không
- ✅ **Portable mode**: Tự download Python nếu chưa có
- ✅ **Traditional mode**: Dùng Python/Flutter đã cài
- ✅ Build backend + Flutter + Unity (nếu có)
- ✅ Prepare installer files

### Build Modes

**Portable (Fully Automated Mode)**:
- 🐍 **Python**: Auto-download portable Python 3.10
- 🐦 **Flutter**: Auto-download portable Flutter SDK (~900MB) nếu thiếu
- 🎮 **Unity**: Auto-prepare project structure & scripts
- 📦 **Result**: Backend + Flutter built without installing ANYTHING!

**Traditional (Developer Mode)**:
- Dùng Python/Flutter đã cài sẵn
- Faster build (không cần download)
- Normal workflow for devs

### Unity Auto-Setup

Script sẽ tự động tạo folder structure tại `unity_vrm/`.
1. Chạy `build.bat` lần đầu → Script tạo skeleton folders & inject scripts.
2. Mở **Unity Hub** → Add Project → Chọn folder `unity_vrm`.
3. Unity sẽ load project. Import **UniVRM** package.
4. Build → `Build/VRMRenderer.exe`.
5. Chạy lại `build.bat` để package vào installer.

---

## 💿 Cài Đặt (End Users)

1. Tải `LiveIdolCloneInstaller.exe`
2. Chạy installer
3. Cài **VB-CABLE** (https://vb-audio.com/Cable/) - bắt buộc
4. Khởi động lại máy
5. Chạy "Live Idol Clone" từ Start Menu

---

## 🚀 Sử Dụng

### Khởi Động

1. Launch app - Đợi backend init (~10s)
2. Check status indicators màu xanh
3. Nhập text (max 1000 ký tự)
4. Click "Speak" → Audio generated (2-10s)

### Clone Giọng (Tùy Chọn)

1. Vào `C:\Program Files\LiveIdolClone\backend\voice_profiles\default\`
2. Thu âm 5-10s giọng rõ ràng (WAV 16-bit 22050Hz)
3. Lưu thành `reference.wav`
4. Restart app

---

## 🎬 Cấu Hình OBS

### Video

1. Add Source → **Window Capture**
2. Window: `[VRMRenderer.exe]: Unity`
3. Resize/position

### Audio

1. Add Source → **Audio Input Capture**
2. Device: `CABLE Output (VB-Audio Virtual Cable)`
3. Adjust volume

### Test

- Start Unity VRM Renderer
- Generate speech trong app
- Check OBS preview có video + audio sync

---

## 🛠️ Troubleshooting

| Vấn Đề | Giải Pháp |
|--------|-----------|
| Backend không chạy | Check port 8000, chạy với admin |
| TTS chậm | Dùng GPU (CUDA) hoặc giảm text |
| OBS không audio | Cài VB-CABLE, restart máy |
| Flutter build fail | `flutter doctor`, cài Visual Studio C++ |
| Voice không clone | Thêm reference.wav vào voice_profiles |

---

## 📁 Project Structure

```
live-idol-clone/
├── backend/             # Django + TTS engine
├── flutter_app/         # Windows UI
├── unity_vrm_scripts/   # Unity C# scripts
├── installer/           # Inno Setup
│
├── build_portable.bat   # Portable build (no install!)
├── build_all.bat        # Traditional build
├── check_setup.bat      # Prerequisites check
└── README.md            # This file
```

---

## 🔧 Build Script

**Chỉ cần 1 file**: `build.bat`

Tự động:
- ✅ Detect environment (Python/Flutter có hay không)
- ✅ Chọn build mode (Portable hoặc Traditional)
- ✅ Build tất cả components
- ✅ Prepare installer files

---

## API Reference

**Base URL**: `http://127.0.0.1:8000/api`

### Endpoints

```bash
# Health check
GET /api/health
→ {"status": "ok", "tts_ready": true}

# Generate speech
POST /api/speak
Body: {"text": "Hello", "voice_profile": "default", "language": "en"}
→ {"audio_path": "...", "duration_ms": 3500, "status": "success"}

# List profiles
GET /api/voice-profiles
→ {"profiles": ["default"], "count": 1}
```

---

## ⚙️ Configuration

### Backend

File: `backend/config/settings.py`

```python
TTS_DEVICE = 'cuda'  # hoặc 'cpu'
VOICE_PROFILES_DIR = 'voice_profiles/'
OUTPUT_DIR = 'output/'
```

### Flutter

File: `flutter_app/lib/services/api_client.dart`

```dart
baseUrl: 'http://127.0.0.1:8000/api'
```

### Unity

File: `Assets/Scripts/AudioReceiver.cs`

```csharp
watchDirectory = @"C:\path\to\backend\output";
```

---

## 📊 Build Times

| Component | Time | Size |
|-----------|------|------|
| Backend | 10-15 min | ~500MB |
| Flutter | 5-10 min | ~50MB |
| Unity | 5-10 min | ~100MB |
| Installer | 2 min | ~650MB |

---

## 🔒 Legal & Privacy

- ✅ 100% local processing
- ✅ Không upload data
- ✅ Chỉ clone giọng có consent
- ⚠️ Label output là AI-generated

---

## 🆘 Support

- Check Troubleshooting section
- Review terminal logs
- Verify VB-CABLE installed
- Ensure all prerequisites met

---

## 📚 Tech Stack

- **Backend**: Django 4.2 + Coqui TTS + PyTorch
- **Frontend**: Flutter 3.x (Windows)
- **Avatar**: Unity 2021.3+ + UniVRM
- **Audio**: VB-CABLE virtual device
- **Packaging**: PyInstaller + Inno Setup

---

## 🙏 Credits

- [Coqui TTS](https://github.com/coqui-ai/TTS) - Voice cloning
- [UniVRM](https://github.com/vrm-c/UniVRM) - VRM support
- [VB-CABLE](https://vb-audio.com/Cable/) - Virtual audio
- [Django](https://www.djangoproject.com/) - Backend framework
- [Flutter](https://flutter.dev/) - UI framework

---

**Ready for production! Build once, distribute forever.** 🚀

_Để build: Chạy `build_portable.bat` (zero install) hoặc `build_all.bat` (traditional)_
