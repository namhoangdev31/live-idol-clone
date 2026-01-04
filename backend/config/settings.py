"""
Django settings for Live Idol Clone backend.
"""
import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-live-idol-clone-poc-key-change-in-production'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['localhost', '127.0.0.1']

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS settings - allow Flutter app to connect
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]

CORS_ALLOW_ALL_ORIGINS = True  # For PoC only

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# Database - Not needed for PoC
# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom settings
import sys

# Custom settings
VOICE_PROFILES_DIR = os.path.join(BASE_DIR, 'voice_profiles')
OUTPUT_DIR = os.path.join(BASE_DIR, 'output')

# Image storage directories
IMAGES_DIR = os.path.join(BASE_DIR, 'images')
AVATARS_DIR = os.path.join(IMAGES_DIR, 'avatars')
BACKGROUNDS_DIR = os.path.join(IMAGES_DIR, 'backgrounds')
OVERLAYS_DIR = os.path.join(IMAGES_DIR, 'overlays')

# File upload limits
MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'webp']

# Check if frozen (bundled)
if getattr(sys, 'frozen', False):
    # In production, look for models in {app}/backend/tts_models
    BASE_EXEC_DIR = Path(sys.executable).parent
    TTS_MODELS_DIR = BASE_EXEC_DIR / 'tts_models'
    
    # We need to point to the specific version folder inside tts_models
    # For simplicity, we'll assume the build process organizes it correctly
    # If using direct path, Coqui TTS needs full path to model.pth and config.json
    # OR we set TTS_HOME env var.
    
    # Let's set TTS_HOME to our bundled dir so TTS finds it naturally
    os.environ['TTS_HOME'] = str(TTS_MODELS_DIR)
    TTS_MODEL = 'tts_models/multilingual/multi-dataset/xtts_v2' # Name logic remains, but cache is local
else:
    TTS_MODEL = 'tts_models/multilingual/multi-dataset/xtts_v2'

import torch

# Dynamic Device Selection (CUDA vs MPS vs CPU)
if torch.cuda.is_available():
    TTS_DEVICE = 'cuda'
    VIDEO_DEVICE = 'cuda'
    print("🚀 Using Device: CUDA (NVIDIA)")
elif torch.backends.mps.is_available():
    TTS_DEVICE = 'mps'
    VIDEO_DEVICE = 'mps'
    print("🍎 Using Device: MPS (Apple Silicon)")
else:
    TTS_DEVICE = 'cpu'
    VIDEO_DEVICE = 'cpu'
    print("🐌 Using Device: CPU")

# Ensure directories exist
os.makedirs(VOICE_PROFILES_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(AVATARS_DIR, exist_ok=True)
os.makedirs(BACKGROUNDS_DIR, exist_ok=True)
os.makedirs(OVERLAYS_DIR, exist_ok=True)

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
    ],
}
