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
        
        # Status updater thread removed for simplified architecture


