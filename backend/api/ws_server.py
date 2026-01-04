import asyncio
import websockets
import json
import logging
import threading
import base64
import platform

logger = logging.getLogger(__name__)

class WebSocketServer:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(WebSocketServer, cls).__new__(cls)
                cls._instance.clients = set()
                cls._instance.loop = None
                cls._instance.port = 8001
                cls._instance.running = False
            return cls._instance

    @classmethod
    def get_instance(cls):
        return cls()

    def start(self):
        """Start the WebSocket server in a separate thread."""
        if self.running:
            return

        def run_loop():
            if platform.system() == 'Windows':
                asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
            
            self.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self.loop)
            
            start_server = websockets.serve(self._handler, "0.0.0.0", self.port)
            logger.info(f"WebSocket Server starting on port {self.port}...")
            
            self.running = True
            
            try:
                self.loop.run_until_complete(start_server)
                self.loop.run_forever()
            except Exception as e:
                logger.error(f"WebSocket Server crashed: {e}")
            finally:
                self.running = False

        thread = threading.Thread(target=run_loop, daemon=True)
        thread.start()

    async def _handler(self, websocket):
        """Handle new WebSocket connections."""
        self.clients.add(websocket)
        logger.info(f"New client connected. Total clients: {len(self.clients)}")
        
        try:
            # Send initial status
            await websocket.send(json.dumps({
                "type": "status",
                "message": "Connected to Live Idol Audio Stream"
            }))
            
            # Keep connection alive
            async for message in websocket:
                pass
                
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            self.clients.remove(websocket)
            logger.info(f"Client disconnected. Total clients: {len(self.clients)}")

    def broadcast_audio(self, audio_data: bytes, sample_rate: int = 24000):
        """
        Broadcast audio data to all connected clients.
        
        Args:
            audio_data: Raw PCM audio bytes (S16LE)
            sample_rate: Sample rate of the audio (default: 24000)
        """
        if not self.clients:
            return

        if self.loop is None or not self.running:
            logger.warning("WebSocket server is not running, cannot broadcast audio")
            return

        # Encode header info if needed, or just send raw binary with a prefix 
        # But for Unity default usage, sending a JSON message with B64 encoded audio
        # is safer than raw binary mixing control messages.
        # Alternatively, we can use binary frame for audio and text frame for control.
        # Let's use strict Binary frame for audio to minimize overhead.
        
        # However, Unity needs to know it's audio.
        # Let's stick to a simple protocol: 
        # Binary messages are PCM audio samples (S16LE, 1 channel).
        
        message = audio_data

        async def _broadcast():
            # Create a list copy to avoid modification during iteration
            for client in list(self.clients):
                try:
                    await client.send(message)
                except websockets.exceptions.ConnectionClosed:
                    self.clients.discard(client)
                except Exception as e:
                    logger.error(f"Error sending to client: {e}")

        asyncio.run_coroutine_threadsafe(_broadcast(), self.loop)

    def broadcast_viseme(self, viseme_data: dict):
        """Broadcast viseme/control data as JSON."""
        if not self.clients:
            return
            
        message = json.dumps(viseme_data)
        
        async def _broadcast():
            for client in list(self.clients):
                try:
                    await client.send(message)
                except:
                    pass
        
        asyncio.run_coroutine_threadsafe(_broadcast(), self.loop)

    def broadcast_config(self, config_data: dict):
        """Broadcast configuration/settings to all connected clients."""
        if not self.clients:
            return

        # Ensure type is set
        if 'type' not in config_data:
            config_data['type'] = 'config'

        message = json.dumps(config_data)

        async def _broadcast():
            for client in list(self.clients):
                try:
                    await client.send(message)
                except websockets.exceptions.ConnectionClosed:
                    self.clients.discard(client)
                except Exception as e:
                    logger.error(f"Error broadcasting config: {e}")

        if self.loop and self.running:
           asyncio.run_coroutine_threadsafe(_broadcast(), self.loop)
