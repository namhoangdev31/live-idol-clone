"""
TTS Engine wrapper for Coqui TTS with voice cloning support.
"""
import os
import time
import logging
from pathlib import Path
from typing import Optional, Dict
import torch
import soundfile as sf
import numpy as np
from django.conf import settings

logger = logging.getLogger(__name__)


class TTSEngine:
    """Singleton TTS engine using Coqui TTS XTTS-v2 for voice cloning with lazy loading."""
    
    _instance = None
    _lock = None  # Will be initialized at module level
    
    def __init__(self):
        """Initialize TTS engine structure (without loading model)."""
        self.model = None
        self.initialized = False
        self.device = settings.TTS_DEVICE
        self.output_dir = Path(settings.OUTPUT_DIR)
        self.voice_profiles_dir = Path(settings.VOICE_PROFILES_DIR)
        
        logger.info(f"TTS Engine created (lazy loading enabled for device: {self.device})")
        # Model will be loaded on first use
    
    @classmethod
    def get_instance(cls):
        """Get singleton instance (lazy initialization)."""
        if cls._instance is None:
            if cls._lock is None:
                import threading
                cls._lock = threading.Lock()
            
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance
    
    def ensure_initialized(self):
        """Ensure TTS model is loaded (called on first use)."""
        if not self.initialized:
            if self._lock is None:
                import threading
                self._lock = threading.Lock()
            
            with self._lock:
                if not self.initialized:  # Double-check after acquiring lock
                    logger.info("🎯 First TTS request - loading model now...")
                    self._load_model()
    
    def _load_model(self):
        """Load Coqui TTS model."""
        try:
            from TTS.api import TTS
            
            logger.info(f"Loading TTS model: {settings.TTS_MODEL}")
            self.model = TTS(model_name=settings.TTS_MODEL, progress_bar=False)
            
            # Move to appropriate device
            if self.device == 'cuda' and torch.cuda.is_available():
                self.model.to('cuda')
                logger.info("TTS model loaded on CUDA")
            else:
                self.model.to('cpu')
                logger.info("TTS model loaded on CPU")
            
            self.initialized = True
            logger.info("TTS Engine initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to load TTS model: {e}")
            self.initialized = False
            raise
    
    def get_voice_profile_path(self, profile_name: str = "default") -> Optional[Path]:
        """
        Get path to voice profile audio file.
        
        Args:
            profile_name: Name of the voice profile
            
        Returns:
            Path to voice profile audio file, or None if not found
        """
        # Look for any audio file in the profile directory
        profile_dir = self.voice_profiles_dir / profile_name
        
        if not profile_dir.exists():
            logger.warning(f"Voice profile directory not found: {profile_dir}")
            return None
        
        # Search for common audio formats
        for ext in ['.wav', '.mp3', '.flac', '.ogg']:
            audio_files = list(profile_dir.glob(f'*{ext}'))
            if audio_files:
                logger.info(f"Found voice profile: {audio_files[0]}")
                return audio_files[0]
        
        logger.warning(f"No audio file found in voice profile: {profile_name}")
        return None
    
    def generate_speech(
        self,
        text: str,
        voice_profile: str = "default",
        language: str = "en"
    ) -> Dict[str, any]:
        """
        Generate speech from text using voice cloning.
        
        Args:
            text: Text to convert to speech
            voice_profile: Name of voice profile to use
            language: Language code (e.g., 'en', 'vi')
            
        Returns:
            Dictionary with audio_path, duration_ms, and status
        """
        # Lazy load TTS model on first use
        self.ensure_initialized()
        
        if not self.initialized:
            raise RuntimeError("TTS Engine failed to initialize")
        
        try:
            # Get voice profile path
            speaker_wav = self.get_voice_profile_path(voice_profile)
            
            if speaker_wav is None:
                # Create a default voice profile if none exists
                logger.warning(f"Voice profile '{voice_profile}' not found, using default TTS")
                return self._generate_default_speech(text, language)
            
            # Generate unique output filename
            timestamp = int(time.time() * 1000)
            output_path = self.output_dir / f"speech_{timestamp}.wav"
            
            logger.info(f"Generating speech: {len(text)} chars, profile={voice_profile}")
            start_time = time.time()
            
            # Generate speech with voice cloning
            self.model.tts_to_file(
                text=text,
                file_path=str(output_path),
                speaker_wav=str(speaker_wav),
                language=language
            )
            
            generation_time = time.time() - start_time
            
            # Get audio duration
            audio_data, sample_rate = sf.read(str(output_path))
            duration_ms = int((len(audio_data) / sample_rate) * 1000)
            
            logger.info(
                f"Speech generated successfully: {output_path.name}, "
                f"duration={duration_ms}ms, generation_time={generation_time:.2f}s"
            )
            
            # TRIGGER UNITY LIPSYNC (Simple Contract)
            # from .unity_control import UnityController
            # UnityController().send_viseme({
            #     "event": "speech_start",
            #     "duration_ms": duration_ms
            # })

            # BROADCAST AUDIO TO UNITY VIA WEBSOCKET
            try:
                from .ws_server import WebSocketServer
                with open(str(output_path), "rb") as f:
                    audio_data = f.read()
                    # Skip WAV header (44 bytes) to get raw PCM if needed, 
                    # but Unity's audio handler might prefer the full wav or raw pcm.
                    # For simplicity, let's send the WHOLE file and let Unity decie,
                    # OR ideally send raw PCM. 
                    # Let's send the whole WAV file bytes for now, 
                    # assuming the client can parse WAV or we strip header there.
                    WebSocketServer.get_instance().broadcast_audio(audio_data)
                    logger.info("Audio broadcasted via WebSocket")
            except Exception as e:
                logger.error(f"Failed to broadcast audio: {e}")

            # TRIGGER OBS PLAYBACK
            from .obs_control import OBSController
            obs_status = OBSController().play_audio(str(output_path))
            
            return {
                'audio_path': str(output_path),
                'duration_ms': duration_ms,
                'generation_time_ms': int(generation_time * 1000),
                'voice_profile': voice_profile,
                'obs_status': obs_status,
                'status': 'success'
            }
            
        except Exception as e:
            logger.error(f"Speech generation failed: {e}")
            return {
                'audio_path': None,
                'duration_ms': 0,
                'error': str(e),
                'status': 'error'
            }
    
    def _generate_default_speech(self, text: str, language: str) -> Dict[str, any]:
        """Generate speech without voice cloning (fallback)."""
        try:
            timestamp = int(time.time() * 1000)
            output_path = self.output_dir / f"speech_{timestamp}.wav"
            
            logger.info(f"Generating default speech: {len(text)} chars")
            start_time = time.time()
            
            # Use first available speaker from the model
            self.model.tts_to_file(
                text=text,
                file_path=str(output_path),
                language=language
            )
            
            generation_time = time.time() - start_time
            
            # Get audio duration
            audio_data, sample_rate = sf.read(str(output_path))
            duration_ms = int((len(audio_data) / sample_rate) * 1000)
            
            logger.info(f"Default speech generated: {output_path.name}")
            
            return {
                'audio_path': str(output_path),
                'duration_ms': duration_ms,
                'generation_time_ms': int(generation_time * 1000),
                'voice_profile': 'default',
                'status': 'success'
            }
            
        except Exception as e:
            logger.error(f"Default speech generation failed: {e}")
            raise
    
    def get_available_profiles(self) -> list:
        """Get list of available voice profiles."""
        profiles = []
        
        if not self.voice_profiles_dir.exists():
            return profiles
        
        for profile_dir in self.voice_profiles_dir.iterdir():
            if profile_dir.is_dir():
                # Check if directory contains audio files
                has_audio = any(
                    profile_dir.glob(f'*{ext}')
                    for ext in ['.wav', '.mp3', '.flac', '.ogg']
                )
                if has_audio:
                    profiles.append(profile_dir.name)
        
        return profiles
