import logging
import subprocess
import os
import psutil
import sys
from pathlib import Path
from django.conf import settings

logger = logging.getLogger(__name__)

class UnityController:
    _instance = None
    PROCESS_NAME = "VRMRenderer.exe"
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(UnityController, cls).__new__(cls)
            cls._instance.process = None
        return cls._instance

    def get_renderer_path(self):
        """
        Get absolute path to VRMRenderer.exe.
        Assumes it is located in 'renderer' sibling directory or configured path.
        """
        if getattr(sys, 'frozen', False):
            # In production (frozen), executable is in {app}/backend/LiveIdolBackend.exe
            # Renderer is in {app}/backend/renderer/VRMRenderer.exe
            exe_dir = Path(sys.executable).parent
            return exe_dir / 'renderer' / self.PROCESS_NAME
            
        # Check standard location relative to BASE_DIR
        # prod: BASE_DIR (backend/config/..) -> backend -> renderer
        renderer_dir = settings.BASE_DIR.parent / 'renderer'
        exe_path = renderer_dir / self.PROCESS_NAME
        
        if exe_path.exists():
            return exe_path
            
        # Fallback 1: User-specified path (live-idol-clone/build_output/unity/VRMRenderer.exe)
        # settings.BASE_DIR is 'backend', so parent is project root
        user_specified_path = settings.BASE_DIR.parent / 'build_output' / 'unity' / self.PROCESS_NAME
        if user_specified_path.exists():
            return user_specified_path

        # Fallback 2: Dev environment (unity_vrm/Build)
        dev_path = settings.BASE_DIR.parent / 'unity_vrm' / 'Build' / self.PROCESS_NAME
        if dev_path.exists():
            return dev_path

        # Fallback 3: Old build structure
        build_output_path = settings.BASE_DIR.parent / 'build_output' / 'backend' / 'renderer' / self.PROCESS_NAME
        if build_output_path.exists():
            return build_output_path
            
        return None

    def is_running(self):
        """Check if Unity process is currently running."""
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] == self.PROCESS_NAME:
                self.process = proc
                return True
        return False

    def launch(self):
        """Launch the Unity Renderer process."""
        exe_path = self.get_renderer_path()
        if not exe_path or not exe_path.exists():
            logger.error(f"Unity Renderer executable not found at: {exe_path}")
            return False

        if self.is_running():
            logger.info("Unity Renderer is already running.")
            return True

        try:
            # Launch detached process
            logger.info(f"Launching Unity Renderer: {exe_path}")
            self.process = subprocess.Popen(
                [str(exe_path), '-window-mode', 'borderless', '-screen-width', '1920', '-screen-height', '1080'],
                cwd=exe_path.parent,
                creationflags=subprocess.CREATE_NEW_CONSOLE
            )
            return True
        except Exception as e:
            logger.error(f"Failed to launch Unity Renderer: {e}")
            return False

    def close(self):
        """Terminate the Unity process."""
        if self.is_running() and self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=3)
                logger.info("Unity Renderer closed.")
                return True
            except psutil.NoSuchProcess:
                return True
            except Exception as e:
                logger.error(f"Error closing Unity Renderer: {e}")
                # Force kill if terminate fails
                try:
                    self.process.kill()
                    return True
                except:
                    return False
        return True

    def send_viseme(self, viseme_info):
        """
        Send LipSync viseme data to Unity via network.
        For now, this is a placeholder stub for TCP/UDP socket communication.
        Viseme info could be phoneme ID, duration, or blendshap weights.
        """
        # TODO: Implement actual socket client
        # Example:
        # sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # sock.sendto(json.dumps(viseme_info).encode(), ('localhost', 5000))
        logger.debug(f"Sending viseme to Unity: {viseme_info}")
        pass
