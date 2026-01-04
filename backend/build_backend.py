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
    'websockets',
]

# Build arguments
args = [
    'run_server.py',  # Entry point script
    '--name=LiveIdolBackend',
    f'--distpath={DIST_DIR}',
    f'--workpath={BUILD_DIR}',
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

# Run PyInstaller via subprocess to properly capture exit code
import subprocess
result = subprocess.run(
    [sys.executable, '-m', 'PyInstaller'] + args
)

if result.returncode != 0:
    print(f"\n[ERROR] PyInstaller failed with exit code: {result.returncode}")
    sys.exit(1)

# Check if executable was created
output_exe = DIST_DIR / 'LiveIdolBackend.exe'
if not output_exe.exists():
    print("\n[ERROR] Build failed - executable not found!")
    sys.exit(1)

print("\n[OK] Build complete!")
print(f"Executable: {output_exe}")


