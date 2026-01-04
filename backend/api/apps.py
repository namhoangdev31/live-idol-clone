from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'
    
    def ready(self):
        """Initialize WebSocket server for real-time updates and audio streaming."""
        import threading
        from .ws_server import WebSocketServer
        
        print("🚀 Backend starting... (TTS will load on-demand)")
        
        # Start the centralized WebSocket Server (Port 8001)
        # This handles both status updates and audio streaming
        ws_server = WebSocketServer.get_instance()
        ws_server.start()
        
        # We can still send periodic status updates if needed, 
        # but let's keep it simple for now or move that logic elsewhere if unrelated to core function.
        # For now, let's spawn a separate status updater thread if we really need the "loading/ready" status
        # that was there before, but integrating it into the WS server logic is better.
        
        def run_status_updater():
            import time
            import json
            from .tts_engine import TTSEngine
            
            while True:
                time.sleep(1)
                if WebSocketServer.get_instance().clients:
                    # Check TTS status
                    if TTSEngine._instance is not None:
                        is_ready = TTSEngine._instance.initialized
                        status = "ready" if is_ready else "loading"
                    else:
                        status = "ready"
                    
                    WebSocketServer.get_instance().broadcast_viseme({
                        "type": "status",
                        "status": status,
                        "details": "Server is running (TTS: lazy loading)"
                    })

        status_thread = threading.Thread(target=run_status_updater, daemon=True)
        status_thread.start()

