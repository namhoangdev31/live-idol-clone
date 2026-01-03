#!/usr/bin/env bash
################################################################################
# Live Idol Clone - Fully Automated Production Build Script
# 
# This script automates the entire build process for production deployment.
# It builds all components and prepares them for packaging.
#
# Requirements:
#   - Python 3.10+
#   - Flutter SDK  
#   - Unity (manual step required)
#   - Sufficient disk space (~10GB)
#
# Usage:
#   chmod +x build_production.sh
#   ./build_production.sh
#
################################################################################

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build output directory
BUILD_OUTPUT="$PROJECT_ROOT/build_output"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Live Idol Clone - Production Build Script           ║"
echo "║                                                            ║"
echo "║  This script will build all components automatically      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

################################################################################
# Helper Functions
################################################################################

print_step() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

################################################################################
# Pre-flight Checks
################################################################################

print_step "Running pre-flight checks..."

CHECKS_PASSED=true

# Check Python
if check_command python3 || check_command python; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    echo "  Python version: $PYTHON_VERSION"
else
    CHECKS_PASSED=false
fi

# Check Flutter (optional on macOS, required on Windows)
if check_command flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n1)
    echo "  Flutter: $FLUTTER_VERSION"
else
    print_warning "Flutter not found (required for Windows build)"
fi

# Check disk space
AVAILABLE_SPACE=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
print_success "Available disk space: $AVAILABLE_SPACE"

if [ "$CHECKS_PASSED" = false ]; then
    print_error "Pre-flight checks failed. Please install missing dependencies."
    exit 1
fi

################################################################################
# Create Build Output Directory
################################################################################

print_step "Creating build output directory..."

rm -rf "$BUILD_OUTPUT"
mkdir -p "$BUILD_OUTPUT/backend"
mkdir -p "$BUILD_OUTPUT/flutter"
mkdir -p "$BUILD_OUTPUT/unity"
mkdir -p "$BUILD_OUTPUT/installer/files"

print_success "Build directory created at: $BUILD_OUTPUT"

################################################################################
# Build Backend
################################################################################

print_step "Building Django Backend..."

cd "$PROJECT_ROOT/backend"

# Create virtual environment
print_step "Creating Python virtual environment..."
$PYTHON_CMD -m venv venv

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
else
    print_error "Failed to find virtual environment activation script"
    exit 1
fi

print_success "Virtual environment activated"

# Upgrade pip
print_step "Upgrading pip..."
pip install --upgrade pip --quiet

# Install dependencies
print_step "Installing Python dependencies (this may take a while)..."
pip install -r requirements.txt --quiet

print_success "Dependencies installed"

# Download TTS models
print_step "Downloading TTS models (~2GB, this may take several minutes)..."
$PYTHON_CMD -c "from TTS.api import TTS; print('Initializing TTS...'); TTS(model_name='tts_models/multilingual/multi-dataset/xtts_v2')" || print_warning "TTS model download failed, will retry during build"

# Install PyInstaller
print_step "Installing PyInstaller..."
pip install pyinstaller --quiet

# Build backend
print_step "Building backend executable with PyInstaller..."
$PYTHON_CMD build_backend.py

if [ -f "dist/LiveIdolBackend" ] || [ -f "dist/LiveIdolBackend.exe" ]; then
    print_success "Backend build successful"
    
    # Copy to build output
    cp -r dist/* "$BUILD_OUTPUT/backend/"
    print_success "Backend copied to build output"
else
    print_error "Backend build failed"
    exit 1
fi

# Deactivate virtual environment
deactivate

cd "$PROJECT_ROOT"

################################################################################
# Build Flutter App
################################################################################

print_step "Building Flutter Windows App..."

# Check if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_warning "Flutter Windows build requires Windows platform"
    print_warning "Skipping Flutter build on macOS"
    print_warning "You'll need to build Flutter on Windows using: flutter build windows --release"
else
    cd "$PROJECT_ROOT/flutter_app"
    
    # Get dependencies
    print_step "Getting Flutter dependencies..."
    flutter pub get
    
    # Build for Windows
    print_step "Building Flutter for Windows (Release mode)..."
    flutter build windows --release
    
    if [ -d "build/windows/runner/Release" ]; then
        print_success "Flutter build successful"
        
        # Copy to build output
        cp -r build/windows/runner/Release/* "$BUILD_OUTPUT/flutter/"
        print_success "Flutter app copied to build output"
    else
        print_error "Flutter build failed"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
fi

################################################################################
# Unity Build Instructions
################################################################################

print_step "Unity VRM Renderer Setup..."

echo ""
print_warning "Unity build requires manual steps:"
echo ""
echo "  1. Open Unity Hub"
echo "  2. Create new 3D project at: $PROJECT_ROOT/unity_vrm/"
echo "  3. Import UniVRM package from https://github.com/vrm-c/UniVRM/releases"
echo "  4. Copy scripts from $PROJECT_ROOT/unity_vrm_scripts/ to Assets/Scripts/"
echo "  5. Add VRM avatar to Assets/StreamingAssets/"
echo "  6. Create main scene with VRMController GameObject"
echo "  7. Build Settings → Windows x64 → Build to $PROJECT_ROOT/unity_vrm/Build/"
echo ""

read -p "Press Enter once Unity build is complete (or Ctrl+C to skip)..."

# Check if Unity build exists
if [ -f "$PROJECT_ROOT/unity_vrm/Build/VRMRenderer" ] || [ -f "$PROJECT_ROOT/unity_vrm/Build/VRMRenderer.exe" ]; then
    print_success "Unity build found"
    cp -r "$PROJECT_ROOT/unity_vrm/Build/"* "$BUILD_OUTPUT/unity/"
    print_success "Unity app copied to build output"
else
    print_warning "Unity build not found - you'll need to build it manually"
fi

################################################################################
# Prepare Installer Files
################################################################################

print_step "Preparing installer files..."

cd "$PROJECT_ROOT/installer"

# Create installer file structure
mkdir -p files/backend
mkdir -p files/flutter
mkdir -p files/unity
mkdir -p files/assets/voice_profiles/default

# Copy built components
if [ -d "$BUILD_OUTPUT/backend" ]; then
    cp -r "$BUILD_OUTPUT/backend/"* files/backend/
    print_success "Backend files copied to installer"
fi

if [ -d "$BUILD_OUTPUT/flutter" ]; then
    cp -r "$BUILD_OUTPUT/flutter/"* files/flutter/
    print_success "Flutter files copied to installer"
fi

if [ -d "$BUILD_OUTPUT/unity" ]; then
    cp -r "$BUILD_OUTPUT/unity/"* files/unity/
    print_success "Unity files copied to installer"
fi

# Copy assets
cp "$PROJECT_ROOT/backend/voice_profiles/default/README.md" files/assets/voice_profiles/default/ 2>/dev/null || true

print_success "Installer files prepared"

################################################################################
# Build Summary
################################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Build Summary                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check what was built
BACKEND_BUILT=false
FLUTTER_BUILT=false
UNITY_BUILT=false

if [ -d "$BUILD_OUTPUT/backend" ] && [ "$(ls -A $BUILD_OUTPUT/backend)" ]; then
    echo -e "${GREEN}✓ Backend:${NC} $BUILD_OUTPUT/backend/"
    BACKEND_BUILT=true
else
    echo -e "${RED}✗ Backend: Not built${NC}"
fi

if [ -d "$BUILD_OUTPUT/flutter" ] && [ "$(ls -A $BUILD_OUTPUT/flutter)" ]; then
    echo -e "${GREEN}✓ Flutter:${NC} $BUILD_OUTPUT/flutter/"
    FLUTTER_BUILT=true
else
    echo -e "${YELLOW}⚠ Flutter: Not built (requires Windows)${NC}"
fi

if [ -d "$BUILD_OUTPUT/unity" ] && [ "$(ls -A $BUILD_OUTPUT/unity)" ]; then
    echo -e "${GREEN}✓ Unity:${NC} $BUILD_OUTPUT/unity/"
    UNITY_BUILT=true
else
    echo -e "${YELLOW}⚠ Unity: Not built (manual step required)${NC}"
fi

echo ""
echo -e "${BLUE}Installer files:${NC} $PROJECT_ROOT/installer/files/"
echo ""

################################################################################
# Next Steps
################################################################################

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      Next Steps                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$FLUTTER_BUILT" = false ]; then
    echo -e "${YELLOW}1. Transfer project to Windows machine${NC}"
    echo -e "   Run: cd flutter_app && flutter build windows --release"
    echo ""
fi

if [ "$UNITY_BUILT" = false ]; then
    echo -e "${YELLOW}2. Complete Unity build${NC}"
    echo -e "   Follow Unity setup instructions in COMPLETE_GUIDE.md"
    echo ""
fi

echo -e "${GREEN}3. Build installer with Inno Setup (Windows only)${NC}"
echo -e "   Open installer/setup.iss in Inno Setup Compiler"
echo -e "   Click Build → Compile"
echo ""

echo -e "${GREEN}4. Test installer on clean Windows VM${NC}"
echo ""

echo -e "${GREEN}5. Configure OBS and go live!${NC}"
echo ""

################################################################################
# File Sizes
################################################################################

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Build Output Sizes                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -d "$BUILD_OUTPUT/backend" ]; then
    BACKEND_SIZE=$(du -sh "$BUILD_OUTPUT/backend" 2>/dev/null | cut -f1)
    echo "Backend:  $BACKEND_SIZE"
fi

if [ -d "$BUILD_OUTPUT/flutter" ]; then
    FLUTTER_SIZE=$(du -sh "$BUILD_OUTPUT/flutter" 2>/dev/null | cut -f1)
    echo "Flutter:  $FLUTTER_SIZE"
fi

if [ -d "$BUILD_OUTPUT/unity" ]; then
    UNITY_SIZE=$(du -sh "$BUILD_OUTPUT/unity" 2>/dev/null | cut -f1)
    echo "Unity:    $UNITY_SIZE"
fi

TOTAL_SIZE=$(du -sh "$BUILD_OUTPUT" 2>/dev/null | cut -f1)
echo ""
echo "Total:    $TOTAL_SIZE"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Production Build Script Complete! 🎉             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_success "Build output saved to: $BUILD_OUTPUT"
print_success "Installer files at: $PROJECT_ROOT/installer/files/"

echo ""
echo "For complete documentation, see: COMPLETE_GUIDE.md"
echo ""
