import logging
import time
import subprocess
import psutil
from pathlib import Path
from django.conf import settings
from obswebsocket import obsws, requests
from obswebsocket.exceptions import OBSWebSocketError

logger = logging.getLogger(__name__)

class OBSController:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(OBSController, cls).__new__(cls)
            cls._instance.client = None
            cls._instance.connected = False
            cls._instance.host = "localhost"
            cls._instance.port = 4455
            cls._instance.password = ""  # Default no password
        return cls._instance

    def connect(self):
        """Establish connection to OBS WebSocket."""
        try:
            self.client = obsws(self.host, self.port, self.password)
            self.client.connect()
            self.connected = True
            logger.info("Connected to OBS WebSocket")
            self.setup_default_scene()
            return True
        except Exception as e:
            logger.error(f"Failed to connect to OBS: {e}")
            self.connected = False
            return False

    def ensure_connected(self):
        """Check connection and reconnect if necessary."""
        if not self.connected:
            return self.connect()
        return True

    def setup_default_scene(self):
        """
        Auto-configure OBS Scene and Sources if missing.
        Ensures 'LiveIdol' scene and 'LiveIdolAudio' source exist.
        """
        if not self.connected:
            return

        SCENE_NAME = "LiveIdol"
        AUDIO_SOURCE = "LiveIdolAudio"

        try:
            # 1. Check/Create Scene
            scenes = self.client.call(requests.GetSceneList())
            scene_names = [s['sceneName'] for s in scenes.getScenes()]
            
            if SCENE_NAME not in scene_names:
                logger.info(f"Creating default scene: {SCENE_NAME}")
                self.client.call(requests.CreateScene(sceneName=SCENE_NAME))
                
            # 2. Check/Create Audio Source (ffmpeg_source)
            # We need to know if the source exists in the current scene
            # Simplified: Just try to create input, catch error if exists
            
            # First, check if input exists globally
            inputs = self.client.call(requests.GetInputList())
            input_names = [i['inputName'] for i in inputs.getInputs()]
            
            if AUDIO_SOURCE not in input_names:
                logger.info(f"Creating audio source: {AUDIO_SOURCE}")
                # Create ffmpeg_source
                # Note: We need a dummy file or just leave it empty initially if allowed
                # Using a placeholder settings dict
                self.client.call(requests.CreateInput(
                    sceneName=SCENE_NAME,
                    inputName=AUDIO_SOURCE,
                    inputKind="ffmpeg_source",
                    inputSettings={'is_local_file': True}
                ))
            else:
                # Ensure it is in the target scene (optional, advanced)
                pass

        except Exception as e:
            logger.warning(f"Auto-config failed (non-critical): {e}")

    def play_audio(self, file_path):
        """
        Play an audio file in OBS by setting a Media Source input.
        Requires a Media Source named 'LiveIdolAudio' in the current scene.
        """
        if not self.ensure_connected():
            return {"status": "error", "message": "OBS not connected"}

        source_name = "LiveIdolAudio"

        try:
            # Check if source exists (this is a bit tricky in OBS WS, simpler to just try setting it)
            # For Media Source (ffmpeg_source), input is 'local_file'
            response = self.client.call(requests.SetInputSettings(
                inputName=source_name,
                inputSettings={'local_file': file_path, 'restart_on_activate': True, 'is_local_file': True}
            ))
            
            # Restart playback (Deactivate -> Activate) ensures it plays from start
            self.client.call(requests.SetInputMute(inputName=source_name, inputMuted=False))
            # self.client.call(requests.SetInputActive(inputName=source_name, inputActive=False)) # Not standard req
            # Alternative: Trigger restart via settings update implicitly does it often, 
            # or we can toggle visibility if it's in the current scene.
            
            logger.info(f"OBS playing audio: {file_path}")
            return {"status": "success", "message": f"Playing {file_path}"}

        except OBSWebSocketError as e:
            logger.error(f"OBS WebSocket Error: {e}")
            return {"status": "error", "message": str(e)}
        except Exception as e:
            logger.error(f"OBS General Error: {e}")
            return {"status": "error", "message": str(e)}

    def trigger_animation(self):
        """Placeholder for triggering Unity animation via OBS if needed (unlikely)."""
        pass

    def get_obs_path(self):
        """
        Get absolute path to OBS executable in portable mode.
        Prod: {app_dir}/backend/obs-studio-portable/bin/64bit/obs64.exe
        """
        # Assume obs-studio-portable is sibling to renderer/backend
        # Prod structure:
        # app/
        #   backend/
        #   obs-studio-portable/
        
        # Check standard location relative to BASE_DIR
        # settings.BASE_DIR is backend/config/.. -> backend
        obs_dir = settings.BASE_DIR.parent / 'obs-studio-portable' / 'bin' / '64bit'
        exe_path = obs_dir / 'obs64.exe'
        
        if exe_path.exists():
            return exe_path
            
        return None

    def launch(self):
        """Launch OBS Studio in Portable Mode, Minimized."""
        # Check if already running (simple check)
        import psutil
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] == 'obs64.exe':
                logger.info("OBS is already running.")
                return True

        exe_path = self.get_obs_path()
        if not exe_path or not exe_path.exists():
            logger.error(f"OBS executable not found at: {exe_path}")
            return False

        try:
            logger.info(f"Launching OBS Portable: {exe_path}")
            # Launch with portable flag and minimize
            # Note: OBS doesn't have a built-in 'minimize' flag but we can start it.
            # --portable is critical.
            # --minimize-to-tray might work if configured in OBS settings, 
            # but we can't force it easily via generic cmdline without user config.
            # We'll just launch it.
            cwd = exe_path.parent.parent.parent # obs-studio-portable root for portable mode? 
            # Actually standard portable mode runs from bin/64bit but needs 'portable_mode' file in root or flag.
            # Command: obs64.exe --portable
            
            subprocess.Popen(
                [str(exe_path), '--portable', '--startreplaybuffer'],
                cwd=exe_path.parent,
                creationflags=subprocess.CREATE_NEW_CONSOLE
            )
            return True
        except Exception as e:
            logger.error(f"Failed to launch OBS: {e}")
            return False
