from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'
    
    def ready(self):
        """Initialize WebSocket status server for real-time updates."""
        import threading
        
        print("🚀 Backend starting... (TTS will load on-demand)")
        
        # Start WebSocket Status Server (Port 8001)
        def run_ws_server():
            import asyncio
            import websockets
            import json
            
            print("Starting WebSocket Status Server on port 8001...")
            
            async def status_handler(websocket):
                try:
                    from .tts_engine import TTSEngine
                    
                    while True:
                        # Check TTS status WITHOUT triggering initialization
                        if TTSEngine._instance is not None:
                            is_ready = TTSEngine._instance.initialized
                            status = "ready" if is_ready else "loading"
                        else:
                            status = "ready"  # Backend ready, TTS will load on-demand
                        
                        await websocket.send(json.dumps({
                            "type": "status",
                            "status": status,
                            "details": "Server is running (TTS: lazy loading)"
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
