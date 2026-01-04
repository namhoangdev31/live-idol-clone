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


# ============================================================================
# Image Upload & Management Endpoints
# ============================================================================

@api_view(['POST'])
def upload_image(request):
    """
    Upload an image file (avatar, background, or overlay).
    
    POST /api/images/upload
    
    Form data:
        file: Image file
        category: 'avatar', 'background', or 'overlay'
    """
    from .image_manager import ImageManager
    
    # Get uploaded file
    if 'file' not in request.FILES:
        return Response(
            {'error': 'No file provided'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    uploaded_file = request.FILES['file']
    category = request.data.get('category', 'background')
    
    # Save image
    result = ImageManager.save_image(uploaded_file, category)
    
    if result['success']:
        return Response(result, status=status.HTTP_201_CREATED)
    else:
        return Response(
            {'error': result['error']},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
def list_images(request, category):
    """
    List all images in a category.
    
    GET /api/images/{category}
    
    Params:
        category: 'avatar', 'background', or 'overlay'
    """
    from .image_manager import ImageManager
    
    images = ImageManager.list_images(category)
    
    return Response({
        'category': category,
        'images': images,
        'count': len(images)
    })


@api_view(['DELETE'])
def delete_image(request, category, filename):
    """
    Delete an image file.
    
    DELETE /api/images/{category}/{filename}
    """
    from .image_manager import ImageManager
    
    result = ImageManager.delete_image(category, filename)
    
    if result['success']:
        return Response(result)
    else:
        return Response(
            {'error': result['error']},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def set_obs_background(request):
    """
    Set an image as OBS scene background.
    
    POST /api/obs/set-background
    
    Request body:
        {
            "category": "background",
            "filename": "abc123.jpg"
        }
    """
    from .image_manager import ImageManager
    from .obs_control import OBSController
    
    category = request.data.get('category')
    filename = request.data.get('filename')
    
    if not category or not filename:
        return Response(
            {'error': 'Missing category or filename'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get image path
    image_path = ImageManager.get_image_path(category, filename)
    
    if not image_path:
        return Response(
            {'error': 'Image not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Set background in OBS
    obs_controller = OBSController()
    
    if not obs_controller.ensure_connected():
        return Response(
            {'error': 'OBS not connected'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    try:
        success = obs_controller.set_scene_background(str(image_path))
        
        if success:
            return Response({
                'success': True,
                'message': 'Background set successfully',
                'image': filename
            })
        else:
            return Response(
                {'error': 'Failed to set background in OBS'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    except Exception as e:
        logger.error(f"Error setting OBS background: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def add_obs_overlay(request):
    """
    Add an image overlay to OBS scene.
    
    POST /api/obs/add-overlay
    
    Request body:
        {
            "category": "overlay",
            "filename": "logo.png",
            "x": 100,
            "y": 100,
            "width": 400,
            "height": 400
        }
    """
    from .image_manager import ImageManager
    from .obs_control import OBSController
    
    category = request.data.get('category')
    filename = request.data.get('filename')
    x = request.data.get('x', 0)
    y = request.data.get('y', 0)
    width = request.data.get('width', 400)
    height = request.data.get('height', 400)
    
    if not category or not filename:
        return Response(
            {'error': 'Missing category or filename'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get image path
    image_path = ImageManager.get_image_path(category, filename)
    
    if not image_path:
        return Response(
            {'error': 'Image not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Add overlay to OBS
    obs_controller = OBSController()
    
    if not obs_controller.ensure_connected():
        return Response(
            {'error': 'OBS not connected'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    try:
        source_name = obs_controller.add_image_overlay(
            str(image_path),
            position=(x, y),
            size=(width, height)
        )
        
        if source_name:
            return Response({
                'success': True,
                'message': 'Overlay added successfully',
                'source_name': source_name
            })
        else:
            return Response(
                {'error': 'Failed to add overlay to OBS'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    except Exception as e:
        logger.error(f"Error adding OBS overlay: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def get_recording_status(request):
    """
    Get OBS recording status.
    
    GET /api/obs/recording-status
    
    Returns:
        {
            "recording": true/false,
            "duration_ms": 12345  # If recording
        }
    """
    from .obs_control import OBSController
    from obswebsocket import requests as obs_requests
    
    obs_controller = OBSController()
    
    if not obs_controller.ensure_connected():
        return Response(
            {'error': 'OBS not connected'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    try:
        # Get recording status from OBS
        status_response = obs_controller.client.call(obs_requests.GetRecordStatus())
        
        is_recording = status_response.getOutputActive()
        
        result = {
            'recording': is_recording
        }
        
        if is_recording:
            # Get output duration if recording
            duration = status_response.getOutputDuration()
            result['duration_ms'] = int(duration)
        
        return Response(result)
        
    except Exception as e:
        logger.error(f"Error getting recording status: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def toggle_image_favorite(request, category, filename):
    """
    Toggle favorite status of an image.
    
    POST /api/images/{category}/{filename}/favorite
    
    Returns:
        {
            "success": true,
            "action": "added" or "removed",
            "is_favorite": true/false
        }
    """
    from .favorites import toggle_favorite, is_favorite
    
    try:
        action = toggle_favorite(category, filename)
        
        return Response({
            'success': True,
            'action': action,
            'is_favorite': is_favorite(category, filename)
        })
        
    except Exception as e:
        logger.error(f"Error toggling favorite: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )




@api_view(['POST'])
def update_lipsync_settings(request):
    """
    Update Lip Sync settings and broadcast to Unity.
    
    POST /api/settings/lipsync
    
    Request body:
        {
            "enabled": true,
            "sensitivity": 20.0
        }
    """
    from .ws_server import WebSocketServer
    
    enabled = request.data.get('enabled', True)
    sensitivity = request.data.get('sensitivity', 10.0)
    
    try:
        ws_server = WebSocketServer.get_instance()
        
        config_data = {
            "type": "lipsync_config",
            "enabled": enabled,
            "sensitivity": sensitivity
        }
        
        ws_server.broadcast_config(config_data)
        
        return Response({
            'status': 'success', 
            'message': 'Lip Sync settings updated',
            'config': config_data
        })
        
    except Exception as e:
        logger.error(f"Error updating Lip Sync settings: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
