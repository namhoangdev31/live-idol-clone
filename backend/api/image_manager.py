"""
Image upload and management module.
Handles avatar, background, and overlay image uploads.
"""
import os
import uuid
import logging
from pathlib import Path
from typing import Dict, List, Optional
from django.conf import settings
from django.core.files.uploadedfile import UploadedFile
from PIL import Image

logger = logging.getLogger(__name__)


class ImageManager:
    """Manages image uploads for avatars, backgrounds, and overlays."""
    
    CATEGORIES = {
        'avatar': settings.AVATARS_DIR,
        'background': settings.BACKGROUNDS_DIR,
        'overlay': settings.OVERLAYS_DIR,
    }
    
    @classmethod
    def validate_image(cls, uploaded_file: UploadedFile) -> Dict[str, any]:
        """
        Validate uploaded image file.
        
        Args:
            uploaded_file: Django UploadedFile object
            
        Returns:
            Dictionary with validation result and error message if any
        """
        # Check file size
        if uploaded_file.size > settings.MAX_UPLOAD_SIZE:
            return {
                'valid': False,
                'error': f'File too large. Max size: {settings.MAX_UPLOAD_SIZE / (1024*1024):.1f}MB'
            }
        
        # Get file extension
        filename = uploaded_file.name.lower()
        ext = filename.split('.')[-1] if '.' in filename else ''
        
        if ext not in settings.ALLOWED_IMAGE_EXTENSIONS:
            return {
                'valid': False,
                'error': f'Invalid file type. Allowed: {", ".join(settings.ALLOWED_IMAGE_EXTENSIONS)}'
            }
        
        # Validate image content (magic bytes)
        try:
            img = Image.open(uploaded_file)
            img.verify()  # Verify it's a valid image
            
            # Reset file pointer after verify
            uploaded_file.seek(0)
            
            return {
                'valid': True,
                'width': img.width,
                'height': img.height,
                'format': img.format,
            }
        except Exception as e:
            logger.error(f"Image validation failed: {e}")
            return {
                'valid': False,
                'error': 'Invalid image file or corrupted'
            }
    
    @classmethod
    def save_image(
        cls,
        uploaded_file: UploadedFile,
        category: str
    ) -> Dict[str, any]:
        """
        Save uploaded image to appropriate directory.
        
        Args:
            uploaded_file: Django UploadedFile object
            category: Image category (avatar/background/overlay)
            
        Returns:
            Dictionary with save result and file info
        """
        # Validate category
        if category not in cls.CATEGORIES:
            return {
                'success': False,
                'error': f'Invalid category. Must be one of: {", ".join(cls.CATEGORIES.keys())}'
            }
        
        # Validate image
        validation = cls.validate_image(uploaded_file)
        if not validation['valid']:
            return {
                'success': False,
                'error': validation['error']
            }
        
        try:
            # Generate unique filename
            ext = uploaded_file.name.split('.')[-1].lower()
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            
            # Get category directory
            category_dir = Path(cls.CATEGORIES[category])
            file_path = category_dir / unique_filename
            
            # Save the file with compression
            try:
                with Image.open(uploaded_file) as img:
                    # Convert RGBA to RGB if saving as JPEG
                    if img.mode == 'RGBA' and ext in ['jpg', 'jpeg']:
                        # Create white background
                        rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                        rgb_img.paste(img, mask=img.split()[3])  # Use alpha channel as mask
                        img = rgb_img
                    
                    # Compress and save
                    img.save(
                        file_path,
                        format=ext.upper() if ext != 'jpg' else 'JPEG',
                        optimize=True,
                        quality=85  # Good balance between quality and size
                    )
                    
                    # Get image info after compression
                    file_size = os.path.getsize(file_path)
                    width, height = img.size
            except Exception as e:
                logger.error(f"Failed to save/compress image: {e}")
                # Re-raise as a ValueError to be caught by the outer try-except
                raise ValueError(f"Image save failed: {str(e)}")
            
            logger.info(f"Image saved: {file_path} ({file_size} bytes)")
            
            return {
                'success': True,
                'filename': unique_filename,
                'path': str(file_path),
                'size': file_size,
                'width': width,
                'height': height,
                'category': category,
            }
            
        except Exception as e:
            logger.error(f"Failed to save image: {e}")
            return {
                'success': False,
                'error': f'Failed to save image: {str(e)}'
            }
    
    @classmethod
    def list_images(cls, category: str) -> List[Dict[str, any]]:
        """
        List all images in a category.
        
        Args:
            category: Image category (avatar/background/overlay)
            
        Returns:
            List of image info dictionaries
        """
        if category not in cls.CATEGORIES:
            return []
        
        category_dir = Path(cls.CATEGORIES[category])
        
        if not category_dir.exists():
            return []
        
        from .favorites import is_favorite
        
        images = []
        
        for img_file in category_dir.iterdir():
            if img_file.is_file() and img_file.suffix.lower()[1:] in settings.ALLOWED_IMAGE_EXTENSIONS:
                try:
                    # Get image dimensions
                    with Image.open(img_file) as img:
                        width, height = img.size
                    
                    images.append({
                        'filename': img_file.name,
                        'path': str(img_file),
                        'size': img_file.stat().st_size,
                        'width': width,
                        'height': height,
                        'category': category,
                        'is_favorite': is_favorite(category, img_file.name),
                    })
                except Exception as e:
                    logger.warning(f"Failed to read image {img_file}: {e}")
                    continue
        
        # Sort by filename (most recent first due to UUID)
        images.sort(key=lambda x: x['filename'], reverse=True)
        
        return images
    
    @classmethod
    def delete_image(cls, category: str, filename: str) -> Dict[str, any]:
        """
        Delete an image file.
        
        Args:
            category: Image category
            filename: Image filename
            
        Returns:
            Dictionary with deletion result
        """
        if category not in cls.CATEGORIES:
            return {
                'success': False,
                'error': 'Invalid category'
            }
        
        try:
            # Security check: ensure filename has no path traversal
            if '..' in filename or '/' in filename or '\\' in filename:
                return {
                    'success': False,
                    'error': 'Invalid filename'
                }
            
            category_dir = Path(cls.CATEGORIES[category])
            file_path = category_dir / filename
            
            if not file_path.exists():
                return {
                    'success': False,
                    'error': 'File not found'
                }
            
            # Delete file
            file_path.unlink()
            logger.info(f"Image deleted: {file_path}")
            
            return {
                'success': True,
                'message': 'Image deleted successfully'
            }
            
        except Exception as e:
            logger.error(f"Failed to delete image: {e}")
            return {
                'success': False,
                'error': f'Failed to delete image: {str(e)}'
            }
    
    @classmethod
    def get_image_path(cls, category: str, filename: str) -> Optional[Path]:
        """
        Get full path to an image file.
        
        Args:
            category: Image category
            filename: Image filename
            
        Returns:
            Path object or None if invalid
        """
        if category not in cls.CATEGORIES:
            return None
        
        # Security check
        if '..' in filename or '/' in filename or '\\' in filename:
            return None
        
        category_dir = Path(cls.CATEGORIES[category])
        file_path = category_dir / filename
        
        if file_path.exists():
            return file_path
        
        return None
