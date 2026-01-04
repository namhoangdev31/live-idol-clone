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
        """Establish connection to OBS WebSocket. Auto-scan ports if default fails."""
        try:
            # 1. Try current configured port
            logger.info(f"Connecting to OBS on port {self.port}...")
            self.client = obsws(self.host, self.port, self.password)
            self.client.connect()
            self.connected = True
            logger.info(f"Connected to OBS WebSocket on port {self.port}")
            self.setup_default_scene()
            return True
        except Exception:
            # 2. If failed, scan range 4455-4460 (quick scan) since we might have launched on dynamic port
            logger.warning(f"Connection failed on {self.port}. Scanning ports...")
            for p in range(4455, 4460): # limit scan range for speed
                if p == self.port: continue
                try:
                    client = obsws(self.host, p, self.password)
                    client.connect()
                    self.client = client
                    self.port = p # Update current port
                    self.connected = True
                    logger.info(f"Found OBS on port {p}")
                    self.setup_default_scene()
                    return True
                except:
                    continue
            
            logger.error("Failed to connect to OBS on any port.")
            self.connected = False
            return False

    def ensure_connected(self):
        """Check connection and reconnect if necessary."""
        # Simple check if client object exists and implies connected?
        # obsws doesn't have reliable is_connected property without pinging
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

    def get_available_port(self, start_port=4455, max_port=4499):
        """Find a free port in range."""
        import socket
        for port in range(start_port, max_port + 1):
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                if s.connect_ex(('localhost', port)) != 0:
                    return port
        return start_port

    def update_obs_config(self, port):
        """
        Update OBS Portable global.ini with selected port.
        Path: obs-studio-portable/config/obs-studio/global.ini
        Section: [ObsWebSocket] -> ServerPort=xxxx
        """
        obs_dir = self.get_obs_path()
        if not obs_dir:
            return

        # config path: obs-studio-portable/config/obs-studio/global.ini
        # obs_dir is .../bin/64bit/obs64.exe
        # so config is at .../../../config/obs-studio/global.ini
        config_path = obs_dir.parent.parent.parent / 'config' / 'obs-studio' / 'global.ini'
        
        if not config_path.exists():
            logger.warning(f"OBS config not found at {config_path}. Creating basic config.")
            config_path.parent.mkdir(parents=True, exist_ok=True)
            # Create basic init if missing
            with open(config_path, 'w') as f:
                f.write("[ObsWebSocket]\nServerPort=4455\nServerEnabled=true\n")

        try:
            # We use simple string replacement to avoid configparser issues with OBS ini format quirks
            with open(config_path, 'r') as f:
                content = f.read()
            
            if "[ObsWebSocket]" not in content:
                content += f"\n[ObsWebSocket]\nServerEnabled=true\nServerPort={port}\n"
            else:
                # Regex replace port
                import re
                if "ServerPort=" in content:
                    content = re.sub(r"ServerPort=\d+", f"ServerPort={port}", content)
                else:
                    # Insert after header
                    content = content.replace("[ObsWebSocket]", f"[ObsWebSocket]\nServerPort={port}")
            
            with open(config_path, 'w') as f:
                f.write(content)
            
            logger.info(f"Updated OBS config to use port: {port}")
            
        except Exception as e:
            logger.error(f"Failed to update OBS config: {e}")

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
            
        # Dev fallback (installer/files/...)
        dev_path = settings.BASE_DIR.parent / 'installer' / 'files' / 'obs-studio-portable' / 'bin' / '64bit' / 'obs64.exe'
        if dev_path.exists():
            return dev_path

        return None

    def launch(self):
        """Launch OBS Studio in Portable Mode with Dynamic Port."""
        # Check if already running
        import psutil
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] == 'obs64.exe':
                logger.info("OBS is already running.")
                # Assumes running instance is on default port or we can't easily check
                # Ideally, we should check its network connection, but simplicity first.
                return True

        exe_path = self.get_obs_path()
        if not exe_path or not exe_path.exists():
            logger.error(f"OBS executable not found at: {exe_path}")
            return False

        # 1. Select Port
        port = self.get_available_port()
        self.port = port
        
        # 2. Update Config
        self.update_obs_config(port)

        try:
            logger.info(f"Launching OBS Portable: {exe_path} on port {port}")
            # Launch with portable flag and minimize
            subprocess.Popen(
                [str(exe_path), '--portable', '--startreplaybuffer'],
                cwd=exe_path.parent,
                creationflags=subprocess.CREATE_NEW_CONSOLE
            )
            
            # Wait a bit for startup
            time.sleep(2)
            return True
        except Exception as e:
            logger.error(f"Failed to launch OBS: {e}")
            return False

    def set_scene_background(self, image_path):
        """
        Set an image as the background of the current OBS scene.
        
        Args:
            image_path: Absolute path to the image file
            
        Returns:
            True if successful, False otherwise
        """
        if not self.ensure_connected():
            logger.error("OBS not connected")
            return False
        
        source_name = "LiveStreamBackground"
        scene_name = "LiveIdol"
        
        try:
            # Check if source already exists
            inputs = self.client.call(requests.GetInputList())
            input_names = [i['inputName'] for i in inputs.getInputs()]
            
            if source_name in input_names:
                # Update existing source
                self.client.call(requests.SetInputSettings(
                    inputName=source_name,
                    inputSettings={'file': image_path}
                ))
                logger.info(f"Updated background image: {image_path}")
            else:
                # Create new image source
                self.client.call(requests.CreateInput(
                    sceneName=scene_name,
                    inputName=source_name,
                    inputKind="image_source",
                    inputSettings={'file': image_path}
                ))
                logger.info(f"Created background image source: {image_path}")
            
            # Set to background (bottom of scene)
            scene_items = self.client.call(requests.GetSceneItemList(sceneName=scene_name))
            for item in scene_items.getSceneItems():
                if item['sourceName'] == source_name:
                    item_id = item['sceneItemId']
                    # Move to index 0 (bottom layer)
                    self.client.call(requests.SetSceneItemIndex(
                        sceneName=scene_name,
                        sceneItemId=item_id,
                        sceneItemIndex=0
                    ))
                    break
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to set OBS background: {e}")
            return False
    
    def add_image_overlay(self, image_path, position=(0, 0), size=(400, 400)):
        """
        Add an image overlay to the OBS scene.
        
        Args:
            image_path: Absolute path to the image file
            position: Tuple of (x, y) position in pixels
            size: Tuple of (width, height) in pixels
            
        Returns:
            Source name if successful, None otherwise
        """
        if not self.ensure_connected():
            logger.error("OBS not connected")
            return None
        
        import time
        source_name = f"Overlay_{int(time.time())}"
        scene_name = "LiveIdol"
        
        try:
            # Create image source
            self.client.call(requests.CreateInput(
                sceneName=scene_name,
                inputName=source_name,
                inputKind="image_source",
                inputSettings={'file': image_path}
            ))
            
            # Get the scene item ID for positioning
            scene_items = self.client.call(requests.GetSceneItemList(sceneName=scene_name))
            item_id = None
            for item in scene_items.getSceneItems():
                if item['sourceName'] == source_name:
                    item_id = item['sceneItemId']
                    break
            
            if item_id:
                # Set position and size
                transform = {
                    'positionX': position[0],
                    'positionY': position[1],
                    'scaleX': size[0] / 100,  # OBS uses base size scaling
                    'scaleY': size[1] / 100,
                }
                
                self.client.call(requests.SetSceneItemTransform(
                    sceneName=scene_name,
                    sceneItemId=item_id,
                    sceneItemTransform=transform
                ))
            
            logger.info(f"Added overlay: {source_name} at {position}")
            return source_name
            
        except Exception as e:
            logger.error(f"Failed to add OBS overlay: {e}")
            return None

