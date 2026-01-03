# Windows Build & Deployment Guide

**Platform Required**: Windows 10/11 (64-bit)

This guide walks you through building and deploying the Live Idol Clone PoC on Windows.

---

## 🚀 Quick Start (On Windows)

### Method 1: Automated Build (Recommended)

1. **Clone/Copy Project** to Windows machine
2. **Open Command Prompt** in project root
3. **Run**: `build_all.bat`
4. **Follow prompts** for each component

### Method 2: Manual Build

Follow the detailed steps below.

---

## 📋 Prerequisites (Install First)

### Required Software

1. **Python 3.10 or 3.11**
   - Download: https://www.python.org/downloads/
   - ✅ Add to PATH during installation
   - Verify: `python --version`

2. **Flutter SDK**
   - Download: https://flutter.dev/docs/get-started/install/windows
   - Extract and add to PATH
   - Run: `flutter doctor` and fix any issues
   - Verify: `flutter --version`

3. **Unity 2021.3 LTS or newer**
   - Download: https://unity.com/download
   - Install with Windows Build Support
   - Verify: Open Unity Hub

4. **Inno Setup 6+** (for installer)
   - Download: https://jrsoftware.org/isdl.php
   - Install with default options

5. **Visual Studio 2019/2022** (for Flutter)
   - Download: https://visualstudio.microsoft.com/
   - Install "Desktop development with C++" workload
   - Required by Flutter for Windows builds

6. **Git** (optional, for version control)
   - Download: https://git-scm.com/download/win

---

## 🔨 Build Process

### Step 1: Build Django Backend

```batch
cd backend
build.bat
```

**What this does**:
- Creates Python virtual environment
- Installs dependencies (Django, Coqui TTS, etc.)
- Downloads TTS models (~2GB, first time only)
- Builds `LiveIdolBackend.exe` with PyInstaller

**Output**: `backend\dist\LiveIdolBackend.exe`

**Time**: ~10-20 minutes (first time, includes model download)

**Troubleshooting**:
- If PyTorch fails: Install manually with `pip install torch==2.1.0`
- If port 8000 busy: `netstat -ano | findstr :8000` and kill process
- For GPU: Install CUDA toolkit first

---

### Step 2: Build Flutter Windows App

```batch
cd flutter_app
build.bat
```

**What this does**:
- Gets Flutter dependencies
- Builds Windows release executable
- Compiles Dart to native code

**Output**: `flutter_app\build\windows\runner\Release\live_idol_clone.exe`

**Time**: ~5-10 minutes

**Troubleshooting**:
- If `flutter` not found: Add Flutter to PATH
- If build fails: Run `flutter doctor` and fix issues
- If Visual Studio error: Install C++ desktop development tools

---

### Step 3: Build Unity VRM Renderer

**Manual steps required** (no automated script):

#### 3.1 Create Unity Project

1. Open **Unity Hub**
2. Click **New Project**
3. Select **3D Core** or **3D URP** template
4. Name: `UnityVRMRenderer`
5. Location: `live-idol-clone\unity_vrm\`
6. Click **Create Project**

#### 3.2 Import UniVRM Package

1. Download UniVRM:
   - Go to: https://github.com/vrm-c/UniVRM/releases
   - Download latest `.unitypackage` (e.g., `UniVRM-0.115.0.unitypackage`)

2. In Unity:
   - **Assets** → **Import Package** → **Custom Package**
   - Select downloaded `.unitypackage`
   - Click **Import** (import all)

#### 3.3 Add Scripts

1. In Unity Project window:
   - Right-click **Assets**
   - **Create** → **Folder** → Name it `Scripts`

2. Copy C# scripts:
   - Copy all `.cs` files from `unity_vrm_scripts\` to `Assets\Scripts\`
   - Or drag and drop in Unity

#### 3.4 Get Sample VRM Avatar

Option A: Download from VRoid Hub
- Go to: https://hub.vroid.com/
- Download a free VRM avatar
- Save as `avatar.vrm`

Option B: Create in VRoid Studio
- Download VRoid Studio: https://vroid.com/en/studio
- Create custom avatar
- Export as VRM

#### 3.5 Add VRM to Project

1. In Unity Project window:
   - Right-click **Assets**
   - **Create** → **Folder** → Name it `StreamingAssets`

2. Copy VRM file:
   - Copy `avatar.vrm` to `Assets\StreamingAssets\`

#### 3.6 Create Main Scene

1. **Create Empty GameObject**:
   - **GameObject** → **Create Empty**
   - Rename to `VRMController`

2. **Add Scripts to VRMController**:
   - Select `VRMController`
   - In Inspector, click **Add Component**
   - Add these scripts in order:
     1. `VRMLoader`
     2. `LipSync`
     3. `AudioReceiver`
     4. `IdleAnimation`
     5. `AudioSource` (from Unity components)

3. **Configure VRMLoader**:
   - In Inspector, set:
   - **VRM File Path**: `avatar.vrm` (just filename)

4. **Configure AudioReceiver**:
   - Set **Watch Directory** to backend output path
   - Example: `C:\Users\YourName\live-idol-clone\backend\output`
   - (Update this path to match your setup)

5. **Save Scene**:
   - **File** → **Save As**
   - Name: `MainScene`
   - Save in `Assets/Scenes/`

#### 3.7 Build Unity Executable

1. **Open Build Settings**:
   - **File** → **Build Settings**

2. **Add Scene**:
   - Click **Add Open Scenes**
   - Verify `MainScene` is in the list

3. **Configure Platform**:
   - Select **PC, Mac & Linux Standalone**
   - **Target Platform**: Windows
   - **Architecture**: x86_64

4. **Build**:
   - Click **Build**
   - Choose location: `live-idol-clone\unity_vrm\Build\`
   - Filename: `VRMRenderer.exe`
   - Wait for build to complete (~5-10 minutes)

**Output**: `unity_vrm\Build\VRMRenderer.exe` + data files

---

## ✅ Test Individual Components

### Test Backend

```batch
cd backend\dist
LiveIdolBackend.exe
```

- Should start Django server on port 8000
- Open browser: http://127.0.0.1:8000/api/health
- Should see: `{"status": "ok", "tts_ready": true, ...}`

**Test TTS**:
```batch
curl -X POST http://127.0.0.1:8000/api/speak -H "Content-Type: application/json" -d "{\"text\":\"Hello world\"}"
```

- Should create audio file in `backend\output\`

### Test Flutter App

```batch
cd flutter_app\build\windows\runner\Release
live_idol_clone.exe
```

- App should launch
- Backend indicator should turn green (if backend running)
- Enter text and click "Speak"
- Should see success message

### Test Unity VRM

```batch
cd unity_vrm\Build
VRMRenderer.exe
```

- Unity window should open
- VRM avatar should load
- Avatar should blink periodically
- If backend generates audio, avatar should speak

---

## 📦 Create Installer

### 1. Prepare Files

```batch
cd installer
```

Follow `PREPARE_INSTALLER.md`:

1. Create directory structure:
   ```batch
   mkdir files\backend files\flutter files\unity files\assets
   ```

2. Copy built files:
   ```batch
   copy ..\backend\dist\LiveIdolBackend.exe files\backend\
   xcopy /E /I ..\flutter_app\build\windows\runner\Release\* files\flutter\
   xcopy /E /I ..\unity_vrm\Build\* files\unity\
   ```

### 2. Build Installer

Open Inno Setup:
```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

Or:
1. Right-click `setup.iss`
2. Select **Compile**

**Output**: `installer\output\LiveIdolCloneInstaller_1.0.0.exe`

---

## 🧪 Test Full Installation

### On Clean Windows VM (Recommended)

1. **Create Windows 10/11 VM** (VMware, VirtualBox, Hyper-V)
2. **Copy installer** to VM
3. **Run installer**:
   - Double-click `LiveIdolCloneInstaller_1.0.0.exe`
   - Follow installation wizard
   - Install to default location

4. **Install VB-CABLE** (when prompted):
   - Download from link provided
   - Install and restart computer

5. **Launch Live Idol Clone**:
   - From Desktop or Start Menu
   - Wait for backend to initialize
   - Test speech generation

6. **Test Uninstaller**:
   - Control Panel → Uninstall
   - Verify clean removal

---

## 🎬 Configure OBS

### 1. Install VB-CABLE

1. Download: https://vb-audio.com/Cable/
2. Run installer
3. **Restart computer** (required!)

### 2. OBS Setup

#### Video Capture

1. Open **OBS Studio**
2. **Add Source** → **Window Capture**
3. Name: "VRM Avatar"
4. **Window**: Select `[VRMRenderer.exe]: Unity`
5. **Capture Method**: Auto-detect
6. Click **OK**
7. Position/resize as needed

#### Audio Capture

1. **Add Source** → **Audio Input Capture**
2. Name: "Avatar Voice"
3. **Device**: `CABLE Output (VB-Audio Virtual Cable)`
4. Click **OK**
5. Adjust volume in OBS mixer

### 3. Test OBS Capture

1. **Start Unity VRM Renderer**
2. **Start Live Idol Clone app**
3. **Generate speech** ("Hello, welcome to my stream")
4. **Check OBS**:
   - Video: Should see avatar with lip sync
   - Audio: Should hear voice in real-time

---

## 🎉 Go Live!

1. **Configure OBS streaming settings** (Twitch/YouTube)
2. **Start all components**:
   - Live Idol Clone app (auto-starts backend)
   - Unity VRM Renderer
   - OBS Studio
3. **Test speech generation** → Check OBS preview
4. **Start Streaming** in OBS
5. **Use Live Idol Clone to generate speech** during stream!

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Python not found | Add Python to PATH, restart terminal |
| Flutter build fails | Run `flutter doctor -v`, fix issues |
| Unity scripts errors | Check Unity version (2021.3+), reimport UniVRM |
| Backend slow TTS | Use GPU with CUDA, or reduce text length |
| OBS no audio | Install VB-CABLE, restart PC, check device in OBS |
| App can't find backend | Check backend path in `BackendService.dart` |
| Unity can't find audio | Update `watchDirectory` in `AudioReceiver.cs` |

---

## 📊 Estimated Times

| Task | Duration |
|------|----------|
| Install prerequisites | 30-60 min |
| Build backend | 10-20 min |
| Build Flutter | 5-10 min |
| Setup Unity project | 20-30 min |
| Build Unity | 5-10 min |
| Create installer | 5 min |
| Test installation | 10-15 min |
| **Total** | **~2-3 hours** |

---

## ✅ Checklist

- [ ] All prerequisites installed
- [ ] Backend built successfully
- [ ] Flutter app built successfully
- [ ] Unity project created and configured
- [ ] Unity VRM built successfully
- [ ] All components tested individually
- [ ] Installer created
- [ ] Installer tested on clean VM
- [ ] VB-CABLE installed and configured
- [ ] OBS configured for video + audio
- [ ] Full workflow tested end-to-end

---

**You're now ready to use Live Idol Clone for livestreaming with voice cloning and VRM avatars!** 🎉
