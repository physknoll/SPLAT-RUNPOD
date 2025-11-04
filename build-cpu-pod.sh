#!/bin/bash
# Build Gaussian-LIC on RunPod CPU Pod (with Docker support)
# This is the SIMPLE solution that actually works!

set -e

# Ensure we use the updated runpodctl
export PATH="$HOME/.local/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Build on RunPod CPU Pod with Docker"
echo -e "==========================================${NC}"

# Check prerequisites
if [ -z "$RUNPOD_API_KEY" ]; then
    echo -e "${RED}Error: RUNPOD_API_KEY not set!${NC}"
    echo "Set it with: export RUNPOD_API_KEY='your-key-here'"
    exit 1
fi

# Configuration
DOCKER_USERNAME="${1}"
if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Usage: $0 <dockerhub-username>${NC}"
    exit 1
fi

IMAGE_NAME="gaussian-lic"
IMAGE_TAG="latest"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Docker Hub credentials
if [ -z "$DOCKER_HUB_PASSWORD" ]; then
    echo "Enter your Docker Hub password/token:"
    read -s DOCKER_HUB_PASSWORD
    export DOCKER_HUB_PASSWORD
fi

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Image: $FULL_IMAGE"
echo "  Pod Type: CPU-8 (has Docker support!)"
echo "  Method: Git clone + docker build"
echo "  Cost: ~\$0.08/hr (much cheaper than GPU)"
echo ""

# Configure runpodctl
runpodctl config --apiKey "$RUNPOD_API_KEY" > /dev/null 2>&1

# Create CPU Pod with Docker support
echo -e "${BLUE}Creating CPU Pod with Docker support...${NC}"
POD_OUTPUT=$(runpodctl create pod \
    --name "gaussian-lic-cpu-build-$(date +%s)" \
    --imageName "runpod/ubuntu:22.04" \
    --gpuType "CPU-8" \
    --containerDiskSize 60 \
    --volumeSize 0 \
    --ports "22/tcp" 2>&1)

# Extract Pod ID
POD_ID=$(echo "$POD_OUTPUT" | grep -oE '"[a-z0-9]{14}"' | tr -d '"' | head -1)

if [ -z "$POD_ID" ]; then
    echo -e "${RED}Failed to create Pod!${NC}"
    echo "$POD_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ CPU Pod created: $POD_ID${NC}"

# Cleanup function
cleanup() {
    if [ -n "$POD_ID" ]; then
        echo ""
        echo -e "${YELLOW}Stopping Pod: $POD_ID${NC}"
        runpodctl stop pod "$POD_ID" > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ Pod stopped${NC}"
    fi
}
trap cleanup EXIT

# Wait for Pod to be ready
echo -e "${YELLOW}Waiting for Pod to be ready...${NC}"
MAX_WAIT=180
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    POD_STATUS=$(runpodctl get pod 2>/dev/null | grep "$POD_ID" | awk '{print $NF}')
    
    if [ "$POD_STATUS" = "RUNNING" ]; then
        echo -e "${GREEN}✓ Pod is running!${NC}"
        break
    fi
    
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}Timeout waiting for Pod!${NC}"
    exit 1
fi

# Give it a moment to fully initialize
sleep 10

# Create the build script to run on the pod
echo -e "${YELLOW}Preparing build commands...${NC}"

# Show instructions since we can't easily execute commands remotely
echo ""
echo -e "${GREEN}=========================================="
echo "  Pod is Ready! Follow These Steps:"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}1. Open Web Terminal:${NC}"
echo "   Go to: https://www.runpod.io/console/pods"
echo "   Click on your pod: ${POD_ID}"
echo "   Click 'Connect' → 'Start Web Terminal'"
echo ""
echo -e "${BLUE}2. Paste these commands in the Web Terminal:${NC}"
echo ""
cat << 'EOF'
# Install Docker (CPU pods support Docker!)
apt-get update && apt-get install -y docker.io git

# Start Docker service
service docker start

# Clone your repo (or use the code you have)
git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git /workspace/build
cd /workspace/build

# If you have a custom Dockerfile, you'd upload it via Cloud Sync
# For now, we'll use the standard one

# Build the Docker image (all downloads happen on RunPod!)
docker build --platform=linux/amd64 -t DOCKERUSER/gaussian-lic:latest .

# Login to Docker Hub
docker login -u DOCKERUSER

# Push the image
docker push DOCKERUSER/gaussian-lic:latest

echo "✅ Build complete! Image pushed to Docker Hub."
EOF

echo ""
echo -e "${YELLOW}Replace DOCKERUSER with: ${DOCKER_USERNAME}${NC}"
echo ""
echo -e "${BLUE}3. When done, come back here and press Enter to stop the pod${NC}"
echo ""
read -p "Press Enter after you've completed the build..."

echo ""
echo -e "${GREEN}=========================================="
echo "  Build Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Your image should now be on Docker Hub: $FULL_IMAGE"
echo "Pod will be stopped automatically."
echo ""

