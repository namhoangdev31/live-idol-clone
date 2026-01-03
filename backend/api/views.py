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
    
    from .obs_control import OBSController
    obs_controller = OBSController()
    
    from .unity_control import UnityController
    unity_controller = UnityController()
    
    return Response({
        'tts_initialized': tts_engine.initialized,
        'device': tts_engine.device,
        'voice_profiles': tts_engine.get_available_profiles(),
        'output_directory': str(tts_engine.output_dir),
        'obs_connected': obs_controller.connected,
        'obs_port': obs_controller.port,
        'unity_running': unity_controller.is_running(),
    })


@api_view(['POST'])
def speak(request):
    """
    Generate speech from text using voice cloning.
    
    POST /api/speak
    """
    # ... existing implementation ...
    # (Leaving speak implementation untouched here, just showing context)
    # But for replace_file_content I must replace the whole block if I touch system_status
    # Wait, I can just target system_status block and append launch_unity at end of file.
    pass 

@api_view(['POST'])
def connect_obs(request):
    """Attempt to connect to OBS WebSocket."""
    from .obs_control import OBSController
    obs_controller = OBSController()
    
    success = obs_controller.connect()
    
    if success:
        return Response({'status': 'connected'})
    else:
        return Response(
            {'status': 'failed', 'error': 'Could not connect to OBS. Check if OBS is running and WebSocket is enabled (Port 4455).'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )


@api_view(['POST'])
def launch_unity(request):
    """
    Launch the Unity VRM Renderer process.
    
    POST /api/unity/launch
    """
    from .unity_control import UnityController
    unity_controller = UnityController()
    
    if unity_controller.is_running():
        return Response({'status': 'already_running', 'message': 'Unity Renderer is already running'})
    
    success = unity_controller.launch()
    
    if success:
        return Response({'status': 'launched', 'message': 'Unity Renderer launched successfully'})
    else:
        return Response(
            {'status': 'failed', 'error': 'Could not launch Unity Renderer. Check logs for details.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


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


@api_view(['POST'])
def connect_obs(request):
    """
    Attempt to connect to OBS WebSocket.
    
    POST /api/obs/connect
    """
    from .obs_control import OBSController
    obs_controller = OBSController()
    
    success = obs_controller.connect()
    
    if success:
        return Response({'status': 'connected'})
    else:
        return Response(
            {'status': 'failed', 'error': 'Could not connect to OBS. Check if OBS is running and WebSocket is enabled (Port 4455).'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
@api_view(['POST'])
def launch_obs(request):
    """
    Launch the OBS Studio Portable process.
    
    POST /api/obs/launch
    """
    from .obs_control import OBSController
    obs_controller = OBSController()
    
    # Check if already running (via process list, handled in launch)
    
    success = obs_controller.launch()
    
    if success:
        return Response({'status': 'launched', 'message': 'OBS Studio launched successfully'})
    else:
        return Response(
            {'status': 'failed', 'error': 'Could not launch OBS Studio. Check logs for details.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
