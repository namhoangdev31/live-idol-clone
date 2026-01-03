# Installer Preparation Instructions

This file guides you through preparing files for the Inno Setup installer.

## Prerequisites

All components must be built before creating the installer:

✅ Backend: `backend\dist\LiveIdolBackend.exe`  
✅ Flutter: `flutter_app\build\windows\runner\Release\*`  
✅ Unity: `unity_vrm\Build\VRMRenderer.exe`

## Step 1: Create Files Directory Structure

From the `installer/` directory, create this structure:

```
installer/files/
├── backend/
├── flutter/
├── unity/
└── assets/
    ├── voice_profiles/default/
    └── (VRM avatar file)
```

Run this command from `installer/` directory:

```batch
mkdir files
mkdir files\backend
mkdir files\flutter
mkdir files\unity
mkdir files\assets
mkdir files\assets\voice_profiles
mkdir files\assets\voice_profiles\default
```

## Step 2: Copy Built Files

### Backend

```batch
copy ..\backend\dist\LiveIdolBackend.exe files\backend\
```

### Flutter App

```batch
xcopy /E /I ..\flutter_app\build\windows\runner\Release\* files\flutter\
```

This copies all Flutter runtime files needed.

### Unity VRM Renderer

```batch
xcopy /E /I ..\unity_vrm\Build\* files\unity\
```

This copies the Unity executable and all its data files.

### Assets

1. **Voice Profile README**:
   ```batch
   copy ..\backend\voice_profiles\default\README.md files\assets\voice_profiles\default\
   ```

2. **Sample VRM Avatar** (if you have one):
   ```batch
   copy path\to\your\avatar.vrm files\assets\
   ```

## Step 3: Verify Files

Check that you have:

```
files/
├── backend/
│   └── LiveIdolBackend.exe (~500MB)
├── flutter/
│   ├── live_idol_clone.exe
│   ├── flutter_windows.dll
│   └── data/ (folder with assets)
├── unity/
│   ├── VRMRenderer.exe
│   ├── VRMRenderer_Data/ (folder)
│   ├── MonoBleedingEdge/ (folder)
│   └── UnityCrashHandler64.exe
└── assets/
    ├── avatar.vrm (optional - sample VRM)
    └── voice_profiles/
        └── default/
            └── README.md
```

## Step 4: Build Installer

1. **Install Inno Setup** (if not already):
   - Download from: https://jrsoftware.org/isdl.php
   - Install Inno Setup 6+

2. **Open Inno Setup Compiler**:
   - Open `setup.iss` in Inno Setup Compiler
   - Or right-click `setup.iss` → Compile

3. **Build**:
   - Click "Build" → "Compile"
   - Or press Ctrl+F9

4. **Output**:
   - Installer will be created in `output/`
   - Filename: `LiveIdolCloneInstaller_1.0.0.exe`

## Step 5: Test Installer

### On Clean Windows VM

1. Create a Windows 10/11 VM (or use clean machine)
2. Copy `LiveIdolCloneInstaller_1.0.0.exe` to the VM
3. Run the installer
4. Check that all components are installed correctly
5. Launch the app and test functionality

### Checklist

- [ ] Installer runs without errors
- [ ] All files copied to `C:\Program Files\LiveIdolClone\`
- [ ] Desktop shortcut created (if selected)
- [ ] Start Menu entry created
- [ ] App launches successfully
- [ ] Backend starts automatically
- [ ] VB-CABLE prompt appears if not installed
- [ ] Uninstaller works correctly

## Troubleshooting

### "File not found" during build

- Check that all paths in `setup.iss` are correct
- Verify files exist in `files/` directory
- Check for typos in file paths

### Installer too large

- Expected size: ~650MB
- This is normal due to TTS models and frameworks
- Can't be reduced significantly without breaking functionality

### VB-CABLE check not working

- VB-CABLE detection uses registry check
- May need to update GUID in `setup.iss` if VB-CABLE version changes

## Advanced: Icon and Banner (Optional)

To customize the installer appearance:

1. **Application Icon** (`icon.ico`):
   - Create a 256x256 icon
   - Place in `installer/` directory
   - Update `setup.iss`: `SetupIconFile=icon.ico`

2. **Installer Banner** (`installer_banner.bmp`):
   - Create a 164x314 bitmap
   - Place in `installer/` directory

3. **Small Icon** (`installer_small.bmp`):
   - Create a 55x58 bitmap
   - Place in `installer/` directory

If these files don't exist, Inno Setup will use defaults.

## Building from Command Line

```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

This is useful for automated builds or CI/CD.

## Directory Size Estimates

| Component | Size |
|-----------|------|
| Backend | ~500MB |
| Flutter | ~50MB |
| Unity | ~100MB |
| Assets | ~10MB |
| **Total Installer** | **~650MB** |

---

After successful installer creation, proceed to test it before distributing!
