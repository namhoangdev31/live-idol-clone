# 🎤 Live Idol Clone - AI Vtuber

This project creates a **completely local AI Vtuber** that talks, moves, and livestreams independently. There is no cloud dependency—everything runs on your machine.

**✨ New "All-in-One" Architecture:**

* **Zero Configuration**: No VB-CABLE, no manual OBS setup required.
* **Self-Contained**: Installer bundles Backend, Client, Unity Renderer, and OBS Portable.
* **One-Click Launch**: Open the app, and it automatically launches all necessary components.

---

## 🏗️ Architecture

1. **Backend (Django)**:
    * Handles AI logic (LLM/TTS).
    * Manages system processes (Unity, OBS).
    * Generates audio via XTTS v2.
2. **Frontend (Flutter)**:
    * User control panel.
    * Displays Status (Backend, Unity, OBS).
    * Provides "Auto-Launch" buttons.
3. **Renderer (Unity)**:
    * 3D VRM Avatar visualization.
    * Receives LipSync data (Planned).
4. **Broadcast (OBS Portable)**:
    * Pre-configured local broadcasting suite.
    * Controlled via WebSocket by the Backend.

---

## 🛠️ Build & Install

### Requirements

#### End-User (To Run)
* Windows 10/11 (x64)
* **None!** (Everything is bundled in the installer)

#### Developer (To Build)
* **Unity Hub** & **Unity 2021.3 LTS** (Only for building the Renderer executable)
* **Inno Setup 6+** (Only for creating the installer)

### ⚠️ Note on Audio Sync
This PoC currently uses **File-based Audio Sync** for maximum stability and zero-driver configuration.
* **Latency**: There is a small delay (TTS generation + File I/O).
* **Sync**: Lipsync is timer-based. "True streaming" (low latency) is planned for future versions.

### Automatic Build

We provide a smart `build.bat` script that automates the entire process:

1. **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/live-idol-clone.git
    cd live-idol-clone
    ```

2. **Prepare External Files**:
    * **Unity**: This requires a manual setup steps. Please read [UNITY_SETUP.md](docs/UNITY_SETUP.md) to create the project and build `VRMRenderer.exe`.
    * **OBS**: Download **OBS Studio Portable** and extract it to `installer/files/obs-studio-portable/` (Ensure `bin/64bit/obs64.exe` exists).

3. **Run Build Script**:
    Double-click `build.bat`. It will:
    * ✅ Detect/Download Python & Flutter (Portable Mode).
    * ✅ Build Django Backend (Exe).
    * ✅ Build Flutter Client (Exe).
    * ✅ Detect Unity Build.
    * ✅ Compile "All-in-One" Installer using Inno Setup.

4. **Result**:
    Run the installer found in `installer/output/LiveIdolCloneInstaller.exe`.

---

## 🚀 Usage

1. Run the **Live Idol Clone** shortcut on your desktop.
2. **Dashboard**:
    * **Unity Status**: Click "Launch" if not running.
    * **OBS Status**: Click "Launch" if not running.
3. **To Speak**:
    * Type text in the box and hit "Speak".
    * Audio will play directly through OBS (Media Source).

---

## 🧩 Troubleshooting

* **Unity not launching?**
    Check if `VRMRenderer.exe` exists in `backend/renderer`.
* **OBS not connecting?**
    The app automatically finds an open port (range `4455-4499`) and configures OBS. Check the dashboard to see which port is active. If issues persist, ensure `obs64.exe` is not blocked by firewall.
* **"Build Failed"?**
    Check `build.log` for details. Ensure you have internet access for downloading dependencies on the first run.

For more detailed issues, please check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

---

## 🤝 Contributing

Contributions are welcome! Please verify your changes with `build.bat` before submitting a PR.
