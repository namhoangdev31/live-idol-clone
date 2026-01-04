import logging
import base64
import io
import time
from django.http import StreamingHttpResponse, JsonResponse
from obswebsocket import requests as obs_requests
from .obs_control import OBSController
from PIL import Image

logger = logging.getLogger(__name__)


class OBSStreamController:
    """Controller for streaming OBS preview output with adaptive features."""
    
    # Quality presets: (width, height, jpeg_quality)
    QUALITY_PRESETS = {
        'low': (640, 360, 50),
        'medium': (1280, 720, 75),
        'high': (1920, 1080, 90),
    }
    
    def __init__(self):
        self.obs = OBSController()
        self.last_frame_hash = None
        self.frame_cache = None
        self.cache_timestamp = 0
        self.cache_ttl = 0.1  # Cache valid for 100ms
    
    def get_screenshot(self, quality='medium'):
        """
        Get a single screenshot from OBS current scene with quality option.
        Returns image bytes or None if OBS not connected.
        
        Args:
            quality: 'low', 'medium', or 'high'
        """
        if not self.obs.ensure_connected():
            return None
        
        # Check cache first
        import time
        current_time = time.time()
        if self.frame_cache and (current_time - self.cache_timestamp) < self.cache_ttl:
            return self.frame_cache
        
        try:
            preset = self.QUALITY_PRESETS.get(quality, self.QUALITY_PRESETS['medium'])
            width, height, jpeg_quality = preset
            
            # Get screenshot using OBS WebSocket API
            response = self.obs.client.call(obs_requests.GetSourceScreenshot(
                sourceName="LiveIdol",
                imageFormat="jpg",
                imageWidth=width,
                imageHeight=height,
                imageCompressionQuality=jpeg_quality
            ))
            
            img_data = response.getImageData()
            
            if ',' in img_data:
                img_data = img_data.split(',', 1)[1]
            
            img_bytes = base64.b64decode(img_data)
            
            # Update cache
            self.frame_cache = img_bytes
            self.cache_timestamp = current_time
            
            # Update hash for change detection
            import hashlib
            frame_hash = hashlib.md5(img_bytes).hexdigest()
            scene_changed = (self.last_frame_hash != frame_hash)
            self.last_frame_hash = frame_hash
            
            return img_bytes
            
        except Exception as e:
            logger.error(f"Failed to get OBS screenshot: {e}")
            return None
    
    def detect_scene_change(self, current_frame_bytes):
        """
        Detect if scene has changed since last frame.
        
        Args:
            current_frame_bytes: Image bytes to check
            
        Returns:
            True if scene changed, False otherwise
        """
        import hashlib
        frame_hash = hashlib.md5(current_frame_bytes).hexdigest()
        
        if self.last_frame_hash != frame_hash:
            self.last_frame_hash = frame_hash
            return True
        return False
    
    def get_placeholder_image(self):
        """Generate a placeholder image when OBS is not available."""
        from PIL import Image, ImageDraw, ImageFont
        
        # Create a simple placeholder
        img = Image.new('RGB', (1280, 720), color=(30, 30, 40))
        draw = ImageDraw.Draw(img)
        
        # Add text
        text = "OBS Preview Not Available\n\nPlease launch OBS Studio"
        bbox = draw.textbbox((0, 0), text)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        position = ((1280 - text_width) // 2, (720 - text_height) // 2)
        draw.text(position, text, fill=(150, 150, 160), align='center')
        
        # Convert to bytes
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG', quality=70)
        return buffer.getvalue()
    
    def generate_mjpeg_stream(self, quality='medium', adaptive=True):
        """
        Generate MJPEG stream from OBS screenshots.
        
        Args:
            quality: 'low', 'medium', or 'high'
            adaptive: If True, only update on scene changes
            
        Yields multipart frames for streaming.
        """
        import time
        
        frame_delay = 0.2  # Base delay (5 FPS)
        if quality == 'low':
            frame_delay = 0.33  # 3 FPS for low quality
        elif quality == 'high':
            frame_delay = 0.1  # 10 FPS for high quality
        
        last_frame = None
        
        while True:
            try:
                # Get screenshot from OBS
                img_bytes = self.get_screenshot(quality)
                
                if img_bytes is None:
                    # Use placeholder if OBS not available
                    img_bytes = self.get_placeholder_image()
                    last_frame = img_bytes
                elif adaptive:
                    # Only yield if scene changed
                    if img_bytes != last_frame:
                        last_frame = img_bytes
                    else:
                        # Scene unchanged, wait longer
                        time.sleep(frame_delay * 2)
                        continue
                else:
                    last_frame = img_bytes
                
                # Yield as MJPEG frame
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + img_bytes + b'\r\n')
                
                # Control frame rate
                time.sleep(frame_delay)
                
            except GeneratorExit:
                logger.info("Stream client disconnected")
                break
            except Exception as e:
                logger.error(f"Stream error: {e}")
                time.sleep(1)  # Wait before retry


def stream_preview(request):
    """
    View for streaming OBS preview as MJPEG.
    
    Query params:
        quality: 'low', 'medium', 'high' (default: 'medium')
        adaptive: 'true' or 'false' (default: 'true')
    """
    controller = OBSStreamController()
    
    # Get parameters
    quality = request.GET.get('quality', 'medium')
    adaptive = request.GET.get('adaptive', 'true').lower() == 'true'
    
    response = StreamingHttpResponse(
        controller.generate_mjpeg_stream(quality=quality, adaptive=adaptive),
        content_type='multipart/x-mixed-replace; boundary=frame'
    )
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'
    
    return response


def get_preview_snapshot(request):
    """
    Get a single snapshot from OBS (for testing or thumbnail).
    Returns JSON with base64 encoded image.
    """
    controller = OBSStreamController()
    
    img_bytes = controller.get_screenshot()
    
    if img_bytes is None:
        img_bytes = controller.get_placeholder_image()
    
    # Encode to base64 for JSON response
    img_base64 = base64.b64encode(img_bytes).decode('utf-8')
    
    return JsonResponse({
        'status': 'success',
        'image': f'data:image/jpeg;base64,{img_base64}',
        'timestamp': int(time.time() * 1000)
    })
