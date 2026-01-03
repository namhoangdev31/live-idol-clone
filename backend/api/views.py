"""
API views for Live Idol Clone backend.
"""
import logging
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .tts_engine import TTSEngine

logger = logging.getLogger(__name__)


@api_view(['GET'])
def health_check(request):
    """
    Health check endpoint.
    
    GET /api/health
    
    Returns:
        200 OK if backend is running and TTS is initialized
    """
    tts_engine = TTSEngine.get_instance()
    
    return Response({
        'status': 'ok',
        'tts_ready': tts_engine.initialized,
        'device': tts_engine.device
    })


@api_view(['GET'])
def system_status(request):
    """
    System status endpoint with detailed information.
    
    GET /api/status
    
    Returns:
        Detailed system status including available voice profiles
    """
    tts_engine = TTSEngine.get_instance()
    
    return Response({
        'tts_initialized': tts_engine.initialized,
        'device': tts_engine.device,
        'voice_profiles': tts_engine.get_available_profiles(),
        'output_directory': str(tts_engine.output_dir),
    })


@api_view(['POST'])
def speak(request):
    """
    Generate speech from text using voice cloning.
    
    POST /api/speak
    
    Request body:
        {
            "text": "Hello, welcome to our livestream",
            "voice_profile": "default",  # optional
            "language": "en"  # optional, defaults to 'en'
        }
    
    Returns:
        {
            "audio_path": "/path/to/speech_123.wav",
            "duration_ms": 3500,
            "generation_time_ms": 2100,
            "voice_profile": "default",
            "status": "success"
        }
    """
    # Get request data
    text = request.data.get('text')
    voice_profile = request.data.get('voice_profile', 'default')
    language = request.data.get('language', 'en')
    
    # Validate input
    if not text:
        return Response(
            {'error': 'Text is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if len(text) > 1000:
        return Response(
            {'error': 'Text too long (max 1000 characters)'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Get TTS engine instance
        tts_engine = TTSEngine.get_instance()
        
        if not tts_engine.initialized:
            return Response(
                {'error': 'TTS engine not initialized'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Generate speech
        logger.info(f"Processing speak request: text_length={len(text)}, profile={voice_profile}")
        result = tts_engine.generate_speech(
            text=text,
            voice_profile=voice_profile,
            language=language
        )
        
        if result['status'] == 'error':
            return Response(
                {'error': result.get('error', 'Unknown error')},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(result, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error in speak endpoint: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def list_voice_profiles(request):
    """
    List available voice profiles.
    
    GET /api/voice-profiles
    
    Returns:
        {
            "profiles": ["default", "user1", "user2"]
        }
    """
    tts_engine = TTSEngine.get_instance()
    profiles = tts_engine.get_available_profiles()
    
    return Response({
        'profiles': profiles,
        'count': len(profiles)
    })
