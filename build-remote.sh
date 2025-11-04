#!/bin/bash
# Build Gaussian-LIC Docker Image Remotely on RunPod
# Run this from your Mac - it creates a Pod, uploads files, builds, and cleans up

set -e

# Ensure we use the updated runpodctl (v1.14.4+)
export PATH="$HOME/.local/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "  Remote Docker Build on RunPod via API"
echo -e "==========================================${NC}"

# Check prerequisites
if [ -z "$RUNPOD_API_KEY" ]; then
    echo -e "${RED}Error: RUNPOD_API_KEY not set!${NC}"
    echo ""
    echo "Get your API key:"
    echo "1. Go to https://www.runpod.io/console/user/settings"
    echo "2. Click 'API Keys' → '+ Create API Key'"
    echo "3. Copy the key and run:"
    echo "   export RUNPOD_API_KEY='your-key-here'"
    echo ""
    exit 1
fi

# Configuration
DOCKER_USERNAME="${1}"
if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Usage: $0 <dockerhub-username>${NC}"
    echo "Example: $0 john_doe"
    exit 1
fi

IMAGE_NAME="gaussian-lic"
IMAGE_TAG="latest"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Docker Hub credentials
echo ""
echo -e "${YELLOW}Docker Hub Setup${NC}"
if [ -z "$DOCKER_HUB_PASSWORD" ]; then
    echo "Enter your Docker Hub password/token:"
    read -s DOCKER_HUB_PASSWORD
    export DOCKER_HUB_PASSWORD
fi

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Docker Image: $FULL_IMAGE"
echo "  GPU: RTX 3090 (checking availability...)"
echo "  Estimated time: 40-45 minutes"
echo "  Estimated cost: ~\$0.27"
echo ""

# Check runpodctl version
if ! command -v runpodctl &> /dev/null; then
    echo -e "${RED}runpodctl not found!${NC}"
    echo ""
    echo "Installing runpodctl v1.14.4..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mkdir -p ~/.local/bin
        curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
        tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
        chmod +x ~/.local/bin/runpodctl
        rm /tmp/runpodctl.tar.gz
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}✓ runpodctl v1.14.4 installed${NC}"
    else
        echo "Please install runpodctl manually:"
        echo "https://github.com/runpod/runpodctl/releases/download/v1.14.4/"
        exit 1
    fi
fi

# Verify runpodctl version (need v1.14+)
RUNPODCTL_VERSION=$(runpodctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+' | head -1 || echo "1.0")
if [[ "$RUNPODCTL_VERSION" == "1.0" ]] || [[ "$RUNPODCTL_VERSION" =~ ^v?1\.([0-9]|1[0-3])$ ]]; then
    echo -e "${YELLOW}Warning: runpodctl version $RUNPODCTL_VERSION is outdated${NC}"
    echo -e "${YELLOW}Updating to v1.14.4...${NC}"
    mkdir -p ~/.local/bin
    curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
    tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
    chmod +x ~/.local/bin/runpodctl
    rm /tmp/runpodctl.tar.gz
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}✓ Updated to runpodctl v1.14.4${NC}"
fi

# Configure runpodctl
echo -e "${YELLOW}Configuring runpodctl...${NC}"
runpodctl config --apiKey "$RUNPOD_API_KEY" > /dev/null 2>&1

# Create Pod (try RTX 4090 first, fallback to RTX 3090)
echo -e "${BLUE}Creating build Pod...${NC}"

# Disable exit-on-error temporarily for pod creation attempts
set +e
POD_OUTPUT=$(runpodctl create pod \
    --name "gaussian-lic-build-$(date +%s)" \
    --imageName "runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04" \
    --gpuType "NVIDIA RTX 4090" \
    --containerDiskSize 60 \
    --volumeSize 0 2>&1)
POD_EXIT=$?
set -e

# If RTX 4090 not available, try RTX 3090
if [ $POD_EXIT -ne 0 ] || echo "$POD_OUTPUT" | grep -q "no longer any instances available"; then
    echo -e "${YELLOW}RTX 4090 not available, trying RTX 3090...${NC}"
    
    set +e
    POD_OUTPUT=$(runpodctl create pod \
        --name "gaussian-lic-build-$(date +%s)" \
        --imageName "runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04" \
        --gpuType "NVIDIA GeForce RTX 3090" \
        --containerDiskSize 60 \
        --volumeSize 0 2>&1)
    POD_EXIT=$?
    set -e
fi

# Check if either attempt succeeded
if [ $POD_EXIT -ne 0 ]; then
    echo -e "${RED}Failed to create Pod!${NC}"
    echo "$POD_OUTPUT"
    exit 1
fi

# Extract Pod ID from output (format: pod "65oneac9azntre" created for $0.220 / hr)
POD_ID=$(echo "$POD_OUTPUT" | grep -oE '"[a-z0-9]{14}"' | tr -d '"' | head -1)

if [ -z "$POD_ID" ]; then
    echo -e "${RED}Failed to get Pod ID!${NC}"
    echo "Output was:"
    echo "$POD_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ Pod created: $POD_ID${NC}"

# Cleanup function
cleanup() {
    if [ -n "$POD_ID" ]; then
        echo ""
        echo -e "${YELLOW}Cleaning up Pod: $POD_ID${NC}"
        runpodctl stop pod "$POD_ID" > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ Pod terminated${NC}"
    fi
}
trap cleanup EXIT

# Wait for Pod to be ready
echo -e "${YELLOW}Waiting for Pod to be ready...${NC}"
MAX_WAIT=180  # 3 minutes
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    POD_STATUS=$(runpodctl get pod 2>/dev/null | grep "$POD_ID" | awk '{print $NF}')
    
    if [ "$POD_STATUS" = "RUNNING" ]; then
        echo ""
        echo -e "${GREEN}✓ Pod is running!${NC}"
        break
    fi
    
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}Timeout waiting for Pod to start!${NC}"
    exit 1
fi

echo -e "${YELLOW}Waiting for SSH to be ready (30 seconds)...${NC}"
sleep 30

echo -e "${GREEN}✓ Pod ready for connection${NC}"

# Create build directory locally
BUILD_DIR="/tmp/gaussian-lic-build-$$"
mkdir -p "$BUILD_DIR"

# Copy necessary files
echo -e "${YELLOW}Preparing files...${NC}"
cp Dockerfile.fixed "$BUILD_DIR/Dockerfile" 2>/dev/null || cp Dockerfile "$BUILD_DIR/Dockerfile"
cp -r Gaussian-LIC "$BUILD_DIR/"

# Create remote build script
cat > "$BUILD_DIR/remote-build.sh" << 'REMOTE_EOF'
#!/bin/bash
set -e

cd /workspace

# Install dependencies
apt-get update -qq && apt-get install -y -qq git wget curl > /dev/null 2>&1

# Build Docker image
echo "Starting Docker build..."
docker build -t "$1" -f Dockerfile . 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"

# Login to Docker Hub
echo "$2" | docker login -u "$3" --password-stdin

# Push image
echo "Pushing image to Docker Hub..."
docker push "$1"

if [ $? -eq 0 ]; then
    echo "SUCCESS! Image pushed: $1"
else
    echo "Failed to push image!"
    exit 1
fi
REMOTE_EOF
chmod +x "$BUILD_DIR/remote-build.sh"

# Upload files to Pod using tar+base64 method (works without SSH)
echo -e "${YELLOW}Uploading files to Pod...${NC}"
echo -e "${YELLOW}(This may take 2-3 minutes for large files)${NC}"

# Create workspace directory on pod
export PATH="$HOME/.local/bin:$PATH"
runpodctl exec "$POD_ID" "mkdir -p /workspace/build-files" > /dev/null 2>&1

# Tar the directory, base64 encode, send via exec, decode and extract on pod
# This method works reliably without requiring SSH ports to be open
cd "$BUILD_DIR"
tar -czf - . | base64 | runpodctl exec "$POD_ID" "base64 -d | tar -xzf - -C /workspace/build-files"
UPLOAD_EXIT=$?
cd - > /dev/null

if [ $UPLOAD_EXIT -ne 0 ]; then
    echo -e "${RED}Failed to upload files!${NC}"
    echo -e "${YELLOW}Trying alternative method (split upload)...${NC}"
    
    # Alternative: upload files individually for smaller payloads
    for file in "$BUILD_DIR"/*; do
        filename=$(basename "$file")
        if [ -d "$file" ]; then
            # For directories, tar them separately
            tar -czf - -C "$BUILD_DIR" "$filename" | base64 | runpodctl exec "$POD_ID" "base64 -d | tar -xzf - -C /workspace/build-files"
        else
            # For individual files, cat and base64
            cat "$file" | base64 | runpodctl exec "$POD_ID" "base64 -d > /workspace/build-files/$filename"
        fi
    done
    
    # Verify at least the Dockerfile made it
    runpodctl exec "$POD_ID" "test -f /workspace/build-files/Dockerfile"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Upload failed after retry!${NC}"
        rm -rf "$BUILD_DIR"
        exit 1
    fi
fi

rm -rf "$BUILD_DIR"
echo -e "${GREEN}✓ Files uploaded${NC}"

# Run build on Pod
echo ""
echo -e "${BLUE}=========================================="
echo "  Building Docker Image (30-40 minutes)"
echo -e "==========================================${NC}"
echo ""

runpodctl exec "$POD_ID" "chmod +x /workspace/build-files/remote-build.sh && cd /workspace && cp -r /workspace/build-files/* /workspace/ && /workspace/remote-build.sh '$FULL_IMAGE' '$DOCKER_HUB_PASSWORD' '$DOCKER_USERNAME'"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "  ✨ BUILD SUCCESSFUL! ✨"
    echo -e "==========================================${NC}"
    echo ""
    echo "Image: $FULL_IMAGE"
    echo "Ready to use on RunPod!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy a new Pod with your image"
    echo "2. Use image: $FULL_IMAGE"
    echo "3. Start processing datasets!"
    echo ""
else
    echo ""
    echo -e "${RED}Build failed!${NC}"
    echo "Check the output above for errors"
    exit 1
fi

# Pod will be automatically cleaned up by trap
echo -e "${YELLOW}Terminating build Pod...${NC}"

