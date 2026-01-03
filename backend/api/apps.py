from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'
    
    def ready(self):
        """Initialize TTS engine when Django starts."""
        from .tts_engine import TTSEngine
        # Initialize the singleton instance
        TTSEngine.get_instance()
