# Base image
# We use a standard Python image. For CUDA support, we might need nvidia/cuda base,
# but usually pytorch/pytorch is better if we want pre-installed torch.
# However, for multi-arch (Mac M-series support), we should stick to standard python 
# and let pip handle the platform specific wheels.
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# ffmpeg: For video/audio processing (Wav2Lip, TTS)
# build-essential: For compiling python extensions
# git: For installing deps from git
# portaudio19-dev: For pyaudio (though we might remove pyaudio in docker)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    build-essential \
    git \
    portaudio19-dev \
    libsndfile1 \
    curl \
    cargo \
    rustc \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Install LivePortrait (Clone and Pre-download weights logic)
# We clone to /app/LivePortrait
RUN git clone https://github.com/KwaiVGI/LivePortrait /app/LivePortrait
# Install LivePortrait requirements (contained in our backend requirements mostly, but let's be safe)
# LivePortrait uses `pip install -r requirements.txt` usually.
# However, we are merging deps into our main requirements.txt to avoid conflicts.

# Create directories for Weights
RUN mkdir -p /app/LivePortrait/pretrained_weights

# Download Weights (This is heavy, maybe move to a script or use a base image with weights)
# For now, we assume the user will mount weights or we download specific ones here?
# Downloading inside Docker build makes it slow and cache-heavy.
# Alternative: Add a script to download on startup if missing.
# Let's create the directories and assume runtime download or volume mount.

# Clone Wav2Lip (Fallback/LipSync Engine)
RUN git clone https://github.com/Rudrabha/Wav2Lip /app/Wav2Lip
RUN mkdir -p /app/Wav2Lip/checkpoints

# Create output directories
RUN mkdir -p /app/output /app/voice_profiles

# Expose port
EXPOSE 8000

# Server entrypoint
CMD ["python", "run_server.py"]
