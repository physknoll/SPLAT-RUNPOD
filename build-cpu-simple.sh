#!/bin/bash
# Build Gaussian-LIC on RunPod CPU Pod (REST API method)

set -e

# Credentials
RUNPOD_API_KEY="rpa_NBSR9A4QL46VY2DPM5OQPA3JLZR44DN3RO6LAP3O151sqr"
DOCKER_USERNAME="rockrobotic961"
DOCKER_TOKEN="dckr_pat_I8wQSm81lmi9UvCs_8x1n-L_fgQ"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Build on RunPod CPU Pod"
echo -e "==========================================${NC}"

# Step 1: Query available CPU types
echo -e "${YELLOW}Querying available CPU types...${NC}"
CPU_TYPES=$(curl -s --request POST \
  --header 'content-type: application/json' \
  --url 'https://api.runpod.io/graphql' \
  --header "Authorization: Bearer $RUNPOD_API_KEY" \
  --data '{"query": "query cpuTypes { cpuTypes { id displayName cores } }"}')

echo "Available CPU types:"
echo "$CPU_TYPES" | jq -r '.data.cpuTypes[] | "\(.id) - \(.displayName) (\(.cores) cores)"' | head -10

# Extract first few CPU flavor IDs
CPU_FLAVORS=$(echo "$CPU_TYPES" | jq -r '[.data.cpuTypes[0:5] | .[].id] | @json')
echo ""
echo -e "${GREEN}Using CPU flavors: $CPU_FLAVORS${NC}"

# Step 2: Create CPU pod
echo ""
echo -e "${YELLOW}Creating CPU pod...${NC}"

POD_RESPONSE=$(curl -s https://api.runpod.io/graphql \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"mutation { podFindAndDeployOnDemand(input: { 
      name: \\\"gaussian-cpu-build\\\", 
      computeType: CPU,
      imageName: \\\"runpod/ubuntu:22.04\\\",
      vcpuCount: 8,
      volumeInGb: 0,
      containerDiskInGb: 60,
      cpuFlavorIds: $CPU_FLAVORS,
      cpuFlavorPriority: AVAILABILITY,
      ports: \\\"22/tcp\\\"
    }) { 
      id 
      desiredStatus
      imageName
      machine { podHostId }
    } }\"
  }")

echo "$POD_RESPONSE"

# Extract pod ID
POD_ID=$(echo "$POD_RESPONSE" | jq -r '.data.podFindAndDeployOnDemand.id')

if [ "$POD_ID" = "null" ] || [ -z "$POD_ID" ]; then
    echo -e "${RED}Failed to create pod!${NC}"
    echo "$POD_RESPONSE" | jq .
    exit 1
fi

echo -e "${GREEN}✓ CPU Pod created: $POD_ID${NC}"

# Cleanup function
cleanup() {
    if [ -n "$POD_ID" ] && [ "$POD_ID" != "null" ]; then
        echo ""
        echo -e "${YELLOW}Stopping Pod: $POD_ID${NC}"
        curl -s https://api.runpod.io/graphql \
          -H "Authorization: Bearer $RUNPOD_API_KEY" \
          -H "Content-Type: application/json" \
          -d "{\"query\": \"mutation { podStop(input: {podId: \\\"$POD_ID\\\"}) { id desiredStatus } }\"}" > /dev/null
        echo -e "${GREEN}✓ Pod stop requested${NC}"
    fi
}
trap cleanup EXIT

# Step 3: Wait for pod to be running
echo -e "${YELLOW}Waiting for pod to start...${NC}"
MAX_WAIT=180
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    POD_STATUS=$(curl -s https://api.runpod.io/graphql \
      -H "Authorization: Bearer $RUNPOD_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"query\": \"query { pod(input: {podId: \\\"$POD_ID\\\"}) { id runtime { ports { ip privatePort publicPort } } } }\"}")
    
    # Check if we have port mappings (means it's running)
    PUBLIC_IP=$(echo "$POD_STATUS" | jq -r '.data.pod.runtime.ports[0].ip // empty')
    SSH_PORT=$(echo "$POD_STATUS" | jq -r '.data.pod.runtime.ports[0].publicPort // empty')
    
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
        echo ""
        echo -e "${GREEN}✓ Pod is running!${NC}"
        echo -e "${GREEN}SSH: ssh root@$PUBLIC_IP -p $SSH_PORT${NC}"
        break
    fi
    
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}Timeout waiting for pod!${NC}"
    exit 1
fi

# Step 4: Show instructions
echo ""
echo -e "${GREEN}=========================================="
echo "  Pod Ready! Web Terminal Instructions"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}1. Go to RunPod Console:${NC}"
echo "   https://www.runpod.io/console/pods"
echo ""
echo -e "${BLUE}2. Find your pod: ${POD_ID}${NC}"
echo "   Click 'Connect' → 'Start Web Terminal'"
echo ""
echo -e "${BLUE}3. Paste these commands:${NC}"
echo ""
cat << 'COMMANDS'
# Install Docker (CPU pods have Docker support!)
apt-get update && apt-get install -y docker.io git curl
service docker start

# Clone Gaussian-LIC
git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git /workspace/Gaussian-LIC
cd /workspace

# Copy Dockerfile if you have a custom one
# For now, we'll use the one from the repo or create a basic one

# Build the image
docker build --platform=linux/amd64 -t rockrobotic961/gaussian-lic:latest -f Gaussian-LIC/Dockerfile Gaussian-LIC/

# Login to Docker Hub
echo "dckr_pat_I8wQSm81lmi9UvCs_8x1n-L_fgQ" | docker login -u rockrobotic961 --password-stdin

# Push to Docker Hub
docker push rockrobotic961/gaussian-lic:latest

echo "✅ Build complete! Image: rockrobotic961/gaussian-lic:latest"
COMMANDS

echo ""
echo -e "${YELLOW}Note: The Dockerfile is in your Gaussian-LIC repo.${NC}"
echo -e "${YELLOW}If you need YOUR custom Dockerfile, you'll need to:${NC}"
echo "  1. Push it to GitHub first, OR"
echo "  2. Use Cloud Sync to upload from S3/Dropbox, OR"
echo "  3. Manually paste it in the web terminal"
echo ""
echo -e "${BLUE}4. When done, press Enter here to stop the pod${NC}"
read -p ""

echo ""
echo -e "${GREEN}Build complete! Pod will be stopped.${NC}"

