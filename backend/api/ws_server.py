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
            
            async def main():
                async with websockets.serve(self._handler, "0.0.0.0", self.port):
                    logger.info(f"WebSocket Server running on port {self.port}")
                    self.running = True
                    # Keep running forever
                    await asyncio.Future()

            try:
                self.loop.run_until_complete(main())
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

    async def broadcast_json(self, data: dict):
        """Broadcast JSON data to all connected clients."""
        if not self.clients:
            return

        message = json.dumps(data)

        async def _broadcast():
            for client in list(self.clients):
                try:
                    await client.send(message)
                except websockets.exceptions.ConnectionClosed:
                    self.clients.discard(client)
                except Exception as e:
                    logger.error(f"Error broadcasting JSON: {e}")

        if self.loop and self.running:
           asyncio.run_coroutine_threadsafe(_broadcast(), self.loop)

    # Legacy methods removed (broadcast_audio, broadcast_viseme)

