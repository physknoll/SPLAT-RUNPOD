#!/bin/bash
# Gaussian-LIC Docker Build Script for RunPod
# Run this script INSIDE a RunPod GPU Pod

set -e

echo "=========================================="
echo "  Gaussian-LIC Docker Build on RunPod"
echo "=========================================="

# Configuration
DOCKER_USERNAME="${1}"

if [ -z "$DOCKER_USERNAME" ]; then
    echo ""
    echo "Usage: $0 <your-dockerhub-username>"
    echo "Example: $0 john_doe"
    echo ""
    exit 1
fi

IMAGE_NAME="gaussian-lic"
IMAGE_TAG="latest"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "Building: $FULL_IMAGE"
echo "This will take approximately 30-40 minutes..."
echo ""

# Check if we're on RunPod
if ! command -v nvidia-smi &> /dev/null; then
    echo "⚠️  WARNING: nvidia-smi not found!"
    echo "This script should be run on a RunPod GPU Pod with NVIDIA GPU."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update and install dependencies
echo "📦 Installing dependencies..."
apt-get update -qq && apt-get install -y -qq git wget curl > /dev/null 2>&1

# Clone Gaussian-LIC if not already present
if [ ! -d "/workspace/Gaussian-LIC" ]; then
    echo "📥 Cloning Gaussian-LIC repository..."
    cd /workspace
    git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git
fi

# Use the fixed Dockerfile
if [ -f "/workspace/Dockerfile.fixed" ]; then
    DOCKERFILE="/workspace/Dockerfile.fixed"
elif [ -f "/workspace/Dockerfile" ]; then
    DOCKERFILE="/workspace/Dockerfile"
else
    echo "❌ Error: No Dockerfile found in /workspace/"
    echo "Please upload Dockerfile or Dockerfile.fixed to /workspace/"
    exit 1
fi

echo "Using Dockerfile: $DOCKERFILE"

# Show GPU info
echo ""
echo "🎮 GPU Information:"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo ""

# Build the Docker image
echo "🔨 Starting Docker build..."
echo "Start time: $(date)"
echo ""

cd /workspace

# Build with progress
docker build -t "$FULL_IMAGE" -f "$DOCKERFILE" . 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Error: Docker build failed!"
    echo "Check build.log for details"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo "End time: $(date)"
echo ""

# Show image info
echo "📊 Image details:"
docker images "$FULL_IMAGE"
IMAGE_SIZE=$(docker images "$FULL_IMAGE" --format "{{.Size}}")
echo ""
echo "Image size: $IMAGE_SIZE"
echo ""

# Ask to push
echo "Would you like to push this image to Docker Hub?"
read -p "Push to Docker Hub? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔐 Logging into Docker Hub..."
    echo "Enter your Docker Hub credentials:"
    docker login
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker login failed"
        exit 1
    fi
    
    echo ""
    echo "📤 Pushing image to Docker Hub..."
    echo "This may take 10-15 minutes depending on your connection..."
    docker push "$FULL_IMAGE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "  ✨ SUCCESS! ✨"
        echo "=========================================="
        echo ""
        echo "Image: $FULL_IMAGE"
        echo "Status: Ready to use on RunPod!"
        echo ""
        echo "📋 Next steps:"
        echo "1. Terminate this build Pod (stop paying)"
        echo "2. Deploy a new Pod with image: $FULL_IMAGE"
        echo "3. Start processing datasets!"
        echo ""
        echo "💰 Build cost: ~\$0.25-0.40 (one-time)"
        echo ""
    else
        echo "❌ Error: Failed to push image to Docker Hub"
        echo "You can try pushing again with:"
        echo "  docker push $FULL_IMAGE"
        exit 1
    fi
else
    echo ""
    echo "Image built but not pushed."
    echo "To push later, run:"
    echo "  docker login"
    echo "  docker push $FULL_IMAGE"
fi

echo ""
echo "🎯 Build Pod can now be terminated to stop charges."
echo ""

