# Build Instructions

Complete guide for building all components from source.

## Prerequisites

### Required Software

1. **Python 3.10+**
   ```bash
   python --version  # Should be 3.10 or higher
   ```

2. **Flutter SDK** (Latest stable)
   ```bash
   flutter --version
   flutter doctor  # Check for issues
   ```

3. **Unity 2021.3 LTS or newer**
   - Download from: https://unity.com/download

4. **Inno Setup 6+** (for Windows installer)
   - Download from: https://jrsoftware.org/isdl.php

5. **Git** (for cloning dependencies)

### System Requirements

- Windows 10/11 (64-bit) for building Windows executables
- 16GB RAM recommended
- 10GB free disk space

## Build Steps

### 1. Build Django Backend

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install pyinstaller

# Download TTS models (first time only - will download ~2GB)
python -c "from TTS.api import TTS; TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')"

# Build standalone executable
python build_backend.py

# Output: dist/LiveIdolBackend.exe
```

**Expected Output**:
```
backend/
└── dist/
    └── LiveIdolBackend.exe  (~500MB)
```

### 2. Build Flutter Windows App

```bash
# Navigate to Flutter app directory
cd flutter_app

# Get dependencies
flutter pub get

# Build for Windows (Release mode)
flutter build windows --release

# Output: build/windows/runner/Release/
```

**Expected Output**:
```
flutter_app/build/windows/runner/Release/
├── live_idol_clone.exe
├── flutter_windows.dll
└── data/
    └── ... (Flutter assets)
```

### 3. Build Unity VRM Renderer

#### Setup Unity Project

1. **Open Unity Hub**
2. **Create New Project**:
   - Template: 3D (URP) or 3D Core
   - Project Name: `UnityVRMRenderer`
   - Location: `live-idol-clone/unity_vrm/`

3. **Import UniVRM Package**:
   - Download latest UniVRM from: https://github.com/vrm-c/UniVRM/releases
   - In Unity: Assets → Import Package → Custom Package
   - Select downloaded `.unitypackage`

4. **Create Project Structure**:
   ```
   Assets/
   ├── Scenes/
   │   └── MainScene.unity
   ├── Scripts/
   │   ├── VRMLoader.cs
   │   ├── LipSync.cs
   │   ├── AudioReceiver.cs
   │   └── IdleAnimation.cs
   ├── VRM/
   │   └── avatar.vrm  (download a sample if needed)
   └── StreamingAssets/
   ```

5. **Add Scripts** (see Unity Scripts section below)

6. **Build Settings**:
   - File → Build Settings
   - Platform: Windows
   - Architecture: x86_64
   - Target: Standalone
   - Build Location: `unity_vrm/Build/VRMRenderer.exe`

7. **Build**:
   - Click "Build"
   - Output: `unity_vrm/Build/VRMRenderer.exe`

### 4. Create Windows Installer

#### Prepare Files

Create this directory structure:

```
installer/
├── setup.iss
└── files/
    ├── backend/
    │   └── LiveIdolBackend.exe
    ├── flutter/
    │   └── (all files from flutter_app/build/windows/runner/Release/)
    ├── unity/
    │   └── VRMRenderer.exe  (and Unity data files)
    └── assets/
        ├── avatar.vrm
        └── voice_profiles/
            └── default/
                └── README.md
```

#### Copy Built Files

```bash
# From project root
mkdir -p installer/files/backend installer/files/flutter installer/files/unity installer/files/assets

# Copy backend
cp backend/dist/LiveIdolBackend.exe installer/files/backend/

# Copy Flutter app
cp -r flutter_app/build/windows/runner/Release/* installer/files/flutter/

# Copy Unity renderer
cp -r unity_vrm/Build/* installer/files/unity/

# Copy assets
cp -r backend/voice_profiles installer/files/assets/
```

#### Inno Setup Script

Create `installer/setup.iss`:

```iss
#define MyAppName "Live Idol Clone"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company"
#define MyAppURL "https://yourwebsite.com/"
#define MyAppExeName "live_idol_clone.exe"

[Setup]
AppId={{YOUR-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\LiveIdolClone
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=output
OutputBaseFilename=LiveIdolCloneInstaller
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Flutter app
Source: "files\flutter\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Backend
Source: "files\backend\LiveIdolBackend.exe"; DestDir: "{app}\backend"; Flags: ignoreversion

; Unity VRM Renderer
Source: "files\unity\*"; DestDir: "{app}\unity"; Flags: ignoreversion recursesubdirs createallsubdirs

; Assets
Source: "files\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs

; Documentation
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if MsgBox('This installer requires VB-CABLE Virtual Audio Device to be installed separately.' + #13#10 + 
            'Would you like to download it after installation?', mbConfirmation, MB_YESNO) = IDYES then
  begin
    // User will be prompted to download VB-CABLE
  end;
end;
```

#### Build Installer

```bash
# Open Inno Setup Compiler
# File → Open → setup.iss
# Build → Compile

# Or from command line:
iscc installer/setup.iss

# Output: installer/output/LiveIdolCloneInstaller.exe
```

## Unity Scripts

### VRMLoader.cs

```csharp
using UnityEngine;
using UniGLTF;
using VRM;
using System.IO;

public class VRMLoader : MonoBehaviour
{
    public string vrmFilePath = "avatar.vrm";
    private GameObject vrmInstance;
    
    void Start()
    {
        LoadVRM();
    }
    
    void LoadVRM()
    {
        // Load VRM from StreamingAssets
        string path = Path.Combine(Application.streamingAssetsPath, vrmFilePath);
        
        if (!File.Exists(path))
        {
            Debug.LogError($"VRM file not found: {path}");
            return;
        }
        
        byte[] vrmBytes = File.ReadAllBytes(path);
        var context = new VRMImporterContext();
        context.ParseGlb(vrmBytes);
        context.Load();
        
        vrmInstance = context.Root;
        vrmInstance.transform.position = Vector3.zero;
        
        Debug.Log("VRM loaded successfully");
    }
    
    public GameObject GetVRMInstance()
    {
        return vrmInstance;
    }
}
```

### LipSync.cs

```csharp
using UnityEngine;
using VRM;

public class LipSync : MonoBehaviour
{
    private VRMBlendShapeProxy blendShapeProxy;
    private AudioSource audioSource;
    
    [Range(0f, 1f)]
    public float sensitivity = 0.5f;
    
    [Range(0f, 1f)]
    public float smoothing = 0.3f;
    
    private float currentMouthOpen = 0f;
    
    void Start()
    {
        // Get VRM blend shape proxy
        blendShapeProxy = GetComponent<VRMBlendShapeProxy>();
        
        // Get or create audio source
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
    }
    
    void Update()
    {
        if (blendShapeProxy == null || audioSource == null)
            return;
        
        // Calculate audio volume (RMS)
        float volume = GetAudioVolume();
        
        // Map to mouth open (0-1)
        float targetMouth = Mathf.Clamp01(volume * sensitivity);
        
        // Smooth transition
        currentMouthOpen = Mathf.Lerp(currentMouthOpen, targetMouth, smoothing);
        
        // Apply to blend shape
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.A, currentMouthOpen);
    }
    
    float GetAudioVolume()
    {
        if (!audioSource.isPlaying)
            return 0f;
        
        float[] samples = new float[256];
        audioSource.GetOutputData(samples, 0);
        
        float sum = 0f;
        foreach (float sample in samples)
        {
            sum += sample * sample;
        }
        
        return Mathf.Sqrt(sum / samples.Length);
    }
}
```

### AudioReceiver.cs

```csharp
using UnityEngine;
using System.IO;

public class AudioReceiver : MonoBehaviour
{
    private AudioSource audioSource;
    public string watchDirectory = @"C:\Program Files\LiveIdolClone\backend\output";
    
    private FileSystemWatcher watcher;
    private string latestAudio = null;
    
    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        
        if (!Directory.Exists(watchDirectory))
        {
            Debug.LogError($"Watch directory not found: {watchDirectory}");
            return;
        }
        
        // Watch for new audio files
        watcher = new FileSystemWatcher(watchDirectory);
        watcher.Filter = "*.wav";
        watcher.Created += OnAudioFileCreated;
        watcher.EnableRaisingEvents = true;
    }
    
    void OnAudioFileCreated(object sender, FileSystemEventArgs e)
    {
        latestAudio = e.FullPath;
        Debug.Log($"New audio file detected: {e.Name}");
    }
    
    void Update()
    {
        if (latestAudio != null && !audioSource.isPlaying)
        {
            PlayAudio(latestAudio);
            latestAudio = null;
        }
    }
    
    void PlayAudio(string path)
    {
        StartCoroutine(LoadAndPlayAudio(path));
    }
    
    System.Collections.IEnumerator LoadAndPlayAudio(string path)
    {
        WWW www = new WWW("file://" + path);
        yield return www;
        
        audioSource.clip = www.GetAudioClip(false, false, AudioType.WAV);
        audioSource.Play();
        
        Debug.Log($"Playing audio: {Path.GetFileName(path)}");
    }
    
    void OnDestroy()
    {
        if (watcher != null)
        {
            watcher.Dispose();
        }
    }
}
```

### IdleAnimation.cs

```csharp
using UnityEngine;
using VRM;

public class IdleAnimation : MonoBehaviour
{
    private VRMBlendShapeProxy blendShapeProxy;
    
    public float blinkInterval = 3f;
    private float nextBlinkTime;
    
    void Start()
    {
        blendShapeProxy = GetComponent<VRMBlendShapeProxy>();
        nextBlinkTime = Time.time + blinkInterval;
    }
    
    void Update()
    {
        if (blendShapeProxy == null)
            return;
        
        // Blink animation
        if (Time.time >= nextBlinkTime)
        {
            StartCoroutine(Blink());
            nextBlinkTime = Time.time + Random.Range(2f, 5f);
        }
    }
    
    System.Collections.IEnumerator Blink()
    {
        // Close eyes
        float t = 0f;
        while (t < 0.1f)
        {
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, t / 0.1f);
            t += Time.deltaTime;
            yield return null;
        }
        
        // Open eyes
        t = 0f;
        while (t < 0.1f)
        {
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, 1f - (t / 0.1f));
            t += Time.deltaTime;
            yield return null;
        }
        
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, 0f);
    }
}
```

## Testing

### Test Backend

```bash
cd backend
python run_server.py

# In another terminal:
curl http://127.0.0.1:8000/api/health
```

### Test Flutter App

```bash
cd flutter_app
flutter run -d windows
```

### Test Unity VRM Renderer

1. Open Unity project
2. Click Play in Unity Editor
3. Check console for VRM loading messages

## Troubleshooting Build Issues

### Python/TTS Issues

- Make sure you're using Python 3.10 or 3.11 (3.12 may have compatibility issues)
- For CUDA/GPU: Install PyTorch with CUDA support first

### Flutter Issues

- Run `flutter doctor` to check for missing dependencies
- Make sure Visual Studio 2019/2022 is installed with C++ desktop development

### Unity Issues

- Ensure UniVRM version is compatible with your Unity version
- Check for script compilation errors before building

### PyInstaller Issues

- If .exe is too large, reduce by excluding unnecessary packages
- Use `--exclude-module` for large unused dependencies

## Next Steps

After successful build:
1. Test each component individually
2. Create the installer package
3. Test installer on clean Windows VM
4. Document any additional dependencies
