#!/bin/bash

# Script to build and push Gaussian-LIC Docker image
# Usage: ./build-and-push.sh [docker-username]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Get Docker username
if [ -z "$1" ]; then
    echo -e "${YELLOW}Enter your Docker Hub username:${NC}"
    read DOCKER_USERNAME
else
    DOCKER_USERNAME=$1
fi

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker username is required${NC}"
    exit 1
fi

IMAGE_NAME="${DOCKER_USERNAME}/gaussian-lic"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${GREEN}Building Docker image: ${FULL_IMAGE}${NC}"
echo -e "${YELLOW}This will take 30-60 minutes depending on your system...${NC}"

# Build the Docker image
docker build -t ${FULL_IMAGE} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"
echo -e "${YELLOW}Image size:${NC}"
docker images ${FULL_IMAGE}

# Ask if user wants to push
echo -e "${YELLOW}Do you want to push the image to Docker Hub? (y/n)${NC}"
read -r PUSH_CONFIRM

if [[ $PUSH_CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Logging into Docker Hub...${NC}"
    docker login
    
    echo -e "${GREEN}Pushing image: ${FULL_IMAGE}${NC}"
    docker push ${FULL_IMAGE}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully pushed ${FULL_IMAGE}${NC}"
        echo -e "${GREEN}You can now use this image in RunPod!${NC}"
        echo -e "${YELLOW}Image: ${FULL_IMAGE}${NC}"
    else
        echo -e "${RED}Error: Failed to push image${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Skipping push. You can push later with:${NC}"
    echo -e "  docker push ${FULL_IMAGE}"
fi

echo -e "${GREEN}Done!${NC}"

