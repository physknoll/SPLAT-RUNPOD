#!/bin/bash
# Simplified Remote Build Script using RunPod GraphQL API
# Works with any runpodctl version

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Remote Docker Build on RunPod via API"
echo -e "==========================================${NC}"

# Check prerequisites
if [ -z "$RUNPOD_API_KEY" ]; then
    echo -e "${RED}Error: RUNPOD_API_KEY not set!${NC}"
    exit 1
fi

if [ -z "$DOCKER_HUB_PASSWORD" ]; then
    echo -e "${RED}Error: DOCKER_HUB_PASSWORD not set!${NC}"
    exit 1
fi

DOCKER_USERNAME="${1:-rockrobotic961}"
FULL_IMAGE="${DOCKER_USERNAME}/gaussian-lic:latest"

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Docker Image: $FULL_IMAGE"
echo "  GPU: RTX 4090 (best value for building)"
echo "  Estimated time: 35-40 minutes"
echo "  Estimated cost: ~\$0.25"
echo ""

# Find available RTX 4090 GPU
echo -e "${YELLOW}Finding available RTX 4090...${NC}"

GPU_QUERY='{
  "query": "query GpuTypes { gpuTypes(input: {}) { id displayName memoryInGb } }"
}'

GPU_RESPONSE=$(curl -s -X POST \
  https://api.runpod.io/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "$GPU_QUERY")

echo "Available GPUs (sample):"
echo "$GPU_RESPONSE" | python3 -m json.tool | grep -A 2 "4090" | head -10 || echo "Checking..."

# Use RunPod's template for PyTorch with CUDA
TEMPLATE_ID="runpod-torch-cuda"
GPU_TYPE_ID="NVIDIA RTX 4090"

# Create Pod using GraphQL API
echo -e "${BLUE}Creating build Pod...${NC}"

POD_NAME="gaussian-lic-build-$(date +%s)"

CREATE_POD_QUERY=$(cat <<EOF
{
  "query": "mutation { podFindAndDeployOnDemand(input: { cloudType: ALL, gpuCount: 1, volumeInGb: 0, containerDiskInGb: 60, minVcpuCount: 2, minMemoryInGb: 20, gpuTypeId: \"$GPU_TYPE_ID\", name: \"$POD_NAME\", imageName: \"runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04\", dockerArgs: \"\", ports: \"22/tcp\", volumeMountPath: \"/workspace\", env: [] }) { id imageName env machineId machine { podHostId } } }"
}
EOF
)

POD_RESPONSE=$(curl -s -X POST \
  https://api.runpod.io/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "$CREATE_POD_QUERY")

# Extract Pod ID
POD_ID=$(echo "$POD_RESPONSE" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
pod_id = data.get('data', {}).get('podFindAndDeployOnDemand', {}).get('id', '')
print(pod_id)
" 2>&1)

# Debug output
if [ -z "$POD_ID" ]; then
    echo -e "${YELLOW}Debug: Full API response:${NC}"
    echo "$POD_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$POD_RESPONSE"
fi

if [[ "$POD_ID" == ERROR:* ]]; then
    echo -e "${RED}Failed to create Pod!${NC}"
    echo "$POD_ID"
    echo ""
    echo "Full response:"
    echo "$POD_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$POD_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Pod created: $POD_ID${NC}"

# Cleanup function
cleanup() {
    if [ -n "$POD_ID" ]; then
        echo ""
        echo -e "${YELLOW}Cleaning up Pod: $POD_ID${NC}"
        
        TERMINATE_QUERY="{\"query\": \"mutation { podTerminate(input: {podId: \\\"$POD_ID\\\"}) }\"}"
        
        curl -s -X POST \
          https://api.runpod.io/graphql \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $RUNPOD_API_KEY" \
          -d "$TERMINATE_QUERY" > /dev/null
        
        echo -e "${GREEN}✓ Pod terminated${NC}"
    fi
}
trap cleanup EXIT

# Wait for Pod to be ready
echo -e "${YELLOW}Waiting for Pod to start (this may take 1-2 minutes)...${NC}"
sleep 30

# Use runpodctl for file transfer (easier than API)
echo -e "${YELLOW}Preparing files...${NC}"

# Create build directory
BUILD_DIR="/tmp/gaussian-lic-build-$$"
mkdir -p "$BUILD_DIR"

# Copy files
cp Dockerfile "$BUILD_DIR/"
cp -r Gaussian-LIC "$BUILD_DIR/" 2>/dev/null || echo "Warning: Gaussian-LIC directory not found locally"

# Create remote build script
cat > "$BUILD_DIR/remote-build.sh" << 'REMOTE_EOF'
#!/bin/bash
set -e

cd /workspace

echo "Installing Docker if needed..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
fi

echo "Building Docker image..."
docker build --platform linux/amd64 -t "$1" . 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Build failed!"
    tail -100 build.log
    exit 1
fi

echo "Logging into Docker Hub..."
echo "$2" | docker login -u "$3" --password-stdin

echo "Pushing image..."
docker push "$1"

echo "SUCCESS! Image pushed: $1"
REMOTE_EOF
chmod +x "$BUILD_DIR/remote-build.sh"

# Upload files using runpodctl
echo -e "${YELLOW}Uploading files to Pod (this may take a minute)...${NC}"
runpodctl send "$BUILD_DIR" "$POD_ID:/workspace/" 2>&1 | grep -v "Scanning" || true

rm -rf "$BUILD_DIR"
echo -e "${GREEN}✓ Files uploaded${NC}"

# Execute build
echo ""
echo -e "${BLUE}=========================================="
echo "  Building Docker Image (35-40 minutes)"
echo -e "==========================================${NC}"
echo ""

runpodctl exec "$POD_ID" "chmod +x /workspace/remote-build.sh && /workspace/remote-build.sh '$FULL_IMAGE' '$DOCKER_HUB_PASSWORD' '$DOCKER_USERNAME'" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "  ✨ BUILD SUCCESSFUL! ✨"
    echo -e "==========================================${NC}"
    echo ""
    echo "Image: $FULL_IMAGE"
    echo ""
    echo "Next steps:"
    echo "1. Go to https://www.runpod.io/console/pods"
    echo "2. Click 'Deploy' → 'Deploy Pod'"
    echo "3. Use your image: $FULL_IMAGE"
    echo "4. Select RTX 5090 GPU"
    echo "5. Start processing!"
    echo ""
else
    echo ""
    echo -e "${RED}Build failed!${NC}"
    echo "Check logs above for details"
    exit 1
fi

