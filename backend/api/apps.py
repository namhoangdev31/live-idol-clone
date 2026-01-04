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
