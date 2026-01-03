"""
PyInstaller build script for Django backend.

Packages the Django backend with all dependencies into a standalone executable.
"""
import PyInstaller.__main__
import os
import sys
from pathlib import Path

# Get base directory
BASE_DIR = Path(__file__).parent

# Output directory
DIST_DIR = BASE_DIR / 'dist'
BUILD_DIR = BASE_DIR / 'build'

# Additional data files to include
datas = [
    (str(BASE_DIR / 'voice_profiles'), 'voice_profiles'),
    (str(BASE_DIR / 'config'), 'config'),
    (str(BASE_DIR / 'api'), 'api'),
]

# Hidden imports (modules PyInstaller might miss)
hidden_imports = [
    'django',
    'django.core.management',
    'rest_framework',
    'corsheaders',
    'TTS',
    'TTS.api',
    'TTS.utils',
    'torch',
    'soundfile',
    'pydub',
    'numpy',
    'scipy',
]

# Build arguments
args = [
    'run_server.py',  # Entry point script
    '--name=LiveIdolBackend',
    f'--distpath={DIST_DIR}',
    f'--buildpath={BUILD_DIR}',
    '--onefile',
    '--console',  # Keep console for debugging
    '--clean',
]

# Add data files
for src, dest in datas:
    args.append(f'--add-data={src}{os.pathsep}{dest}')

# Add hidden imports
for module in hidden_imports:
    args.append(f'--hidden-import={module}')

# Add collection for TTS models
args.append('--collect-data=TTS')
args.append('--collect-binaries=torch')

print("Building Live Idol Backend...")
print(f"Output directory: {DIST_DIR}")
print(f"Args: {args}")

# Run PyInstaller
PyInstaller.__main__.run(args)

print("\nBuild complete!")
print(f"Executable: {DIST_DIR / 'LiveIdolBackend.exe'}")
