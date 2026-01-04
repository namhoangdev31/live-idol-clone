from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'
    
    def ready(self):
        """Initialize TTS engine when Django starts."""
        import threading
        from .tts_engine import TTSEngine
        
        def init_tts():
            print("Starting background TTS initialization...")
            TTSEngine.get_instance()
            print("Background TTS initialization complete.")

        # Initialize in background thread to not block server startup
        thread = threading.Thread(target=init_tts, daemon=True)
        thread.start()
        
        # Start WebSocket Status Server (Port 8001)
        def run_ws_server():
            import asyncio
            import websockets
            import json
            
            print("Starting WebSocket Status Server on port 8001...")
            
            async def status_handler(websocket):
                try:
                    while True:
                        # Check TTS status
                        is_ready = TTSEngine.get_instance().initialized if TTSEngine._instance else False
                        status = "ready" if is_ready else "initializing"
                        
                        await websocket.send(json.dumps({
                            "type": "status",
                            "status": status,
                            "details": "Server is running"
                        }))
                        await asyncio.sleep(1) # Update every second
                except websockets.exceptions.ConnectionClosed:
                    pass
                except Exception as e:
                    print(f"WS Error: {e}")

            async def main():
                async with websockets.serve(status_handler, "0.0.0.0", 8001):
                    await asyncio.Future()  # run forever

            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                loop.run_until_complete(main())
            except Exception as e:
                print(f"Failed to start WS Server: {e}")

        ws_thread = threading.Thread(target=run_ws_server, daemon=True)
        ws_thread.start()
