import torch

# Patch for 'accelerate' library checking torch.xpu which might be missing
if not hasattr(torch, 'xpu'):
    class MockXPU:
        @staticmethod
        def is_available():
            return False
        @staticmethod
        def empty_cache():
            pass
        @staticmethod
        def device_count():
            return 0
        @staticmethod
        def get_device_name(device=None):
            return "MockXPU"
        @staticmethod
        def current_device():
            return 0
        @staticmethod
        def manual_seed(seed):
            pass
        @staticmethod
        def seed():
            pass
        @staticmethod
        def synchronize():
            pass
    torch.xpu = MockXPU
import logging
import os
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from django.conf import settings



logger = logging.getLogger(__name__)

class SceneGenerator:
    _instance = None
    
    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def __init__(self):
        self.device = getattr(settings, 'VIDEO_DEVICE', 'cpu')
        self.pipeline = None
        self.model_id = "runwayml/stable-diffusion-v1-5" # Good baseline for general purpose
        # For better realism, we could use "SG161222/RealVisXL_V4.0" but it requires SDXL pipeline
        
        self.initialized = False
        
    def initialize(self):
        if self.initialized:
            return

        try:
            logger.info(f"Initializing Scene Generator with model {self.model_id} on {self.device}...")
            
            # Load model
            self.pipeline = StableDiffusionPipeline.from_pretrained(
                self.model_id,
                torch_dtype=torch.float16 if self.device != 'cpu' else torch.float32,
                use_safetensors=True
            )
            
            # Scheduler optimization
            self.pipeline.scheduler = DPMSolverMultistepScheduler.from_config(self.pipeline.scheduler.config)
            
            # Move to device
            self.pipeline.to(self.device)
            
            # Enable memory optimizations
            if self.device == 'cuda':
                self.pipeline.enable_model_cpu_offload() 
            elif self.device == 'mps':
                 # MPS sometimes has issues with heavy memory optimization, but attention slicing helps
                self.pipeline.enable_attention_slicing()

            self.initialized = True
            logger.info("Scene Generator initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Scene Generator: {e}")
            self.initialized = False
            raise e

    def generate_scene(self, prompt, negative_prompt=None, width=512, height=512):
        if not self.initialized:
            self.initialize()
            
        try:
            # Default negative prompt for better quality if not provided
            if not negative_prompt:
                negative_prompt = "cartoon, anime, 3d, painting, disfigured, bad art, deformed, extra limbs, blur, grainy"

            logger.info(f"Generating scene: '{prompt}'")
            
            # Generate
            image = self.pipeline(
                prompt=prompt,
                negative_prompt=negative_prompt,
                num_inference_steps=25, # standard
                width=width,
                height=height
            ).images[0]
            
            # Save to disk
            filename = f"scene_{os.urandom(4).hex()}.png"
            output_path = os.path.join(settings.BACKGROUNDS_DIR, filename)
            image.save(output_path)
            
            logger.info(f"Scene saved to {output_path}")
            
            return {
                "status": "success",
                "image_path": output_path,
                "filename": filename,
                "url": f"/static/images/backgrounds/{filename}" # Assuming static serving is set up
            }
            
        except Exception as e:
            logger.error(f"Error generating scene: {e}")
            return {"status": "error", "error": str(e)}
