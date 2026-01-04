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
        'obs_connected': False, # Deprecated
        'obs_port': 0,          # Deprecated
        'unity_running': False, # Deprecated
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

# Connect OBS removed



# Unity Launch removed



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


# OBS Logic Removed



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


# OBS Overlay logic removed



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




# LipSync settings removed

@api_view(['POST'])
def generate_scene(request):
    """
    Generate a scene (background/character) from text description.
    
    POST /api/scene/generate
    
    Request body:
        {
            "prompt": "A beautiful lounge with a city view night",
            "negative_prompt": "ugly, blurry" (optional)
        }
    """
    prompt = request.data.get('prompt')
    negative_prompt = request.data.get('negative_prompt')
    
    if not prompt:
        return Response(
            {'error': 'Prompt is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
        
    try:
        from .scene_engine import SceneGenerator
        generator = SceneGenerator.get_instance()
        
        # This might take time, so ideally run in background task (Celery/RQ)
        # For MVP/PoC, synchronous is acceptable but will block this worker.
        result = generator.generate_scene(prompt, negative_prompt)
        
        if result['status'] == 'error':
            return Response(
                {'error': result['error']},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
        return Response(result)
        
    except Exception as e:
        logger.error(f"Error in generate_scene: {e}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def generate_idle(request):
    """
    Generate an idle looping video for a character.
    
    POST /api/video/idle
    
    Request body:
        {
            "image_path": "/path/to/image.png"
        }
    """
    image_path = request.data.get('image_path')
    
    if not image_path:
        return Response({'error': 'image_path is required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        from .video_engine import VideoGenerationEngine
        engine = VideoGenerationEngine.get_instance()
        
        video_path = engine.generate_idle_video(image_path)
        
        if not video_path:
            return Response({'error': 'Failed to generate idle video'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
        return Response({
            'status': 'success',
            'video_path': video_path,
            'url': f"/static/output/{os.path.basename(video_path)}"
        })
    except Exception as e:
        logger.error(f"Error generating idle video: {e}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def process_comment(request):
    """
    Process a comment: Generate Text Response -> TTS -> Video.
    
    POST /api/process-comment
    
    Request body:
        {
            "comment": "Hello idol!",
            "viewer": "User123",
            "image_path": "/path/to/character.png"
        }
    """
    comment = request.data.get('comment')
    viewer = request.data.get('viewer', 'Viewer')
    image_path = request.data.get('image_path')
    
    if not comment or not image_path:
        return Response({'error': 'comment and image_path are required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        # 1. Generate Text Response
        from .comment_processor import CommentProcessor
        processor = CommentProcessor.get_instance()
        reply_text = processor.generate_reply(comment, viewer)
        
        # 2. Generate Audio (TTS)
        tts = TTSEngine.get_instance()
        # TODO: Get voice profile from request or default
        tts_result = tts.generate_speech(reply_text, voice_profile="default")
        
        if tts_result['status'] == 'error':
            raise Exception(f"TTS Error: {tts_result.get('error')}")
            
        audio_path = tts_result['audio_path']
        
        # 3. Generate Video (Video Engine)
        from .video_engine import VideoGenerationEngine
        video_engine = VideoGenerationEngine.get_instance()
        
        video_path = video_engine.generate_talking_video(image_path, audio_path)
        
        return Response({
            'status': 'success',
            'reply_text': reply_text,
            'audio_path': audio_path,
            'video_path': video_path,
            'video_url': f"/static/output/{os.path.basename(video_path)}"
        })
        
    except Exception as e:
        logger.error(f"Error processing comment: {e}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


