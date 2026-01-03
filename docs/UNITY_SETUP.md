# 🎮 Unity VRM Renderer - Setup Guide

This guide explains how to set up the Unity project from scratch using the provided scripts and build the `VRMRenderer.exe`.

## 1. Create Unity Project
1.  Open **Unity Hub**.
2.  Click **New Project**.
3.  Select **3D Core** template.
4.  **Project Name**: `unity_vrm`
5.  **Location**: `/Users/hoangnam/live-idol-clone/` (The root of this repo).
6.  Click **Create Project**.

## 2. Install UniVRM
The project currently uses the **UniVRM 0.x** API (e.g., `v0.112.0` or similar).
> ⚠️ **IMPORTANT**: Do NOT use UniVRM 1.0 (VRM 1.0) packages as the API is different.

1.  Download the latest **UniVRM-0.x.x.unitypackage** from [GitHub Releases](https://github.com/vrm-c/UniVRM/releases).
2.  In Unity, go to **Assets -> Import Package -> Custom Package...**
3.  Select the downloaded file and click **Import All**.

## 3. Import Scripts (File Copy)
This step is done **outside** of Unity (using Finder or File Explorer).

1.  **Open two windows**:
    *   Window A: Go to `live-idol-clone/unity_vrm_scripts/`.
    *   Window B: Go to `live-idol-clone/unity_vrm/Assets/` (This folder was created by Unity in Step 1).
2.  **Create folder**: In Window B, create a new folder named `Scripts`.
3.  **Copy files**:
    *   Select all `.cs` files in Window A (`LipSync.cs`, `LipSyncReceiver.cs`, `VRMLoader.cs`, etc.).
    *   **Copy** and **Paste** them into `Window B/Scripts`.
4.  **Verify**: Switch back to the Unity Editor. load bar will appear. You should now see the `Scripts` folder in the Project panel (bottom).

## 4. Scene Setup
1.  Open the default SampleScene.
2.  **Create an Empty GameObject** named `VRMController`.
3.  **Attach Components** to `VRMController`:
    > ⚠️ **IMPORTANT**: Only attach these **2 scripts**. The others (`IdleAnimation`, `AudioReceiver`, `LipSync`) are added **automatically** to the Avatar when it loads.
    
    *   **Method A (Drag & Drop)**: Find `VRMLoader.cs` in the Project window (bottom) and drag it onto the `VRMController`.
    *   **Method B (Search)**: Click the **Add Component** button in the Inspector, type `VRMLoader`, and hit Enter.
    *   **Repeat** for `LipSyncReceiver.cs`.
    
    (Do **NOT** attach `IdleAnimation`, `AudioReceiver`, or `LipSync` manually).
4.  **Configure VRMLoader**:
    *   **Debug / Import Mode**: Checked (if you want to test in Editor).
    *   **Default Avatar**: (Optional) Drag a .vrm file into `Assets/StreamingAssets` if you want a default.
5.  **Configure LipSyncReceiver**:
    *   **Port**: `5000` (Default).

## 5. Build for Windows
1.  Go to **File -> Build Profiles** (or **Build Settings**). Shortcut: `Ctrl + Shift + B`.
2.  Add the current scene (`Add Open Scenes`).
3.  **Platform**: Windows.
4.  **Architecture**: x86_64.
5.  Click **Build**.
6.  **Save Location**: Navigate to `live-idol-clone/unity_vrm_scripts/build/`.
7.  **File Name**: `VRMRenderer.exe`.

> **✅ Verification:**
> After building, ensure you have:
> `live-idol-clone/unity_vrm_scripts/build/VRMRenderer.exe`
> `live-idol-clone/unity_vrm_scripts/build/UnityPlayer.dll`
> ...and other folders.

## 6. Run the App
Now you can go back to the root folder can click `build.bat` to package everything!
