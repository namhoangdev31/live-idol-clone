# 🛠️ Live Idol Clone - Troubleshooting Guide

This document lists common issues and solutions for the "All-in-One" Live Idol Clone application.

## 🔴 OBS Issues

### "Failed to connect to OBS"
1.  **Is OBS Running?** 
    Ensure OBS Studio is launched. If using the All-in-One version, click "Launch OBS" in the app.
2.  **WebSocket Enabled?**
    *   Open OBS -> Tools -> WebSocket Server Settings.
    *   Ensure **Enable WebSocket server** is CHECKED.
    *   **Server Port**: `4455`
    *   **Server Password**: (Leave empty, or update `backend/api/obs_control.py` if you set one).
3.  **Firewall?**
    Ensure Windows Firewall is not blocking port 4455 (Localhost).

### "Audio not playing"
1.  **Check Source**: Verify the `LiveIdol` scene has a `LiveIdolAudio` source.
2.  **Check Mixer**: Ensure `LiveIdolAudio` is not muted in the OBS Audio Mixer.
3.  **Monitoring**: To hear the audio yourself, go to Audio Mixer -> Gear Icon (Advanced Audio Properties) -> LiveIdolAudio -> **Monitor and Output**.

---

## 🎮 Unity Renderer Issues

### "Unity Renderer not launching"
1.  **Check Path**: The backend looks for `VRMRenderer.exe` in `backend/renderer/`.
2.  **Manual Launch**: Try running the `.exe` manually to see if it crashes (e.g., missing DirectX drivers).

### "Avatar not moving"
1.  **LipSync**: Currently, LipSync is a planned feature. Ensure `LipSyncReceiver` script is attached in Unity if you are testing the dev build.

---

## 🐍 Backend Issues

### "TTS Engine not initialized"
1.  **Models**: The first run requires internet to download XTTS models (~3GB). Check the console window for download progress.
2.  **GPU**: If you have an NVIDIA GPU, ensure CUDA is installed. If not, the app will run on CPU (slower).

### "Port 8000 already in use"
1.  Check if another instance is running.
2.  Open Task Manager and kill any `LiveIdolBackend.exe` or `python.exe` processes.

---

## 📱 Flutter Client Issues

### "Connection Refused"
1.  Ensure the Backend is running (Green "Backend" indicator).
2.  If running on a different machine, update `BASE_URL` in `api_client.dart`.
