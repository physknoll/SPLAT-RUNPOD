# Building Gaussian-LIC Docker Image on RunPod

## Why Build on RunPod?

Your MacBook Pro **cannot build this Docker image** because:
- ❌ No NVIDIA GPU (CUDA requires NVIDIA hardware)
- ❌ ARM64 architecture (needs x86_64 with CUDA support)
- ❌ No CUDA drivers on macOS

**Solution**: Build the Docker image on RunPod itself using a GPU Pod!

---

## 🚀 Quick Build Process (30-40 minutes)

### Step 1: Create a Build Pod

1. Go to https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. Select:
   - **GPU**: RTX 3090 or RTX 4090 (cheaper for building)
   - **Template**: RunPod Pytorch (has Docker pre-installed)
   - **Container Disk**: 60GB minimum
   - **Volume**: Optional
4. Click **Deploy On-Demand**

**Cost**: ~$0.25-0.40 for a 40-minute build

### Step 2: Connect to Pod

**Option A: Web Terminal**
1. Click your Pod → **Connect** tab
2. Click **Start Web Terminal**

**Option B: SSH**
```bash
ssh root@<pod-ip> -p <port>
```

### Step 3: Clone and Build

```bash
# Install git if needed
apt-get update && apt-get install -y git

# Clone your repo
cd /workspace
git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git

# If you have custom changes, upload your Dockerfile:
# Use Web UI or: scp -P <port> Dockerfile root@<pod-ip>:/workspace/

# Build the image (this takes 30-40 minutes)
cd /workspace
docker build -t YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest -f Dockerfile .
```

### Step 4: Push to Docker Hub

```bash
# Login to Docker Hub
docker login
# Enter your Docker Hub username and password/token

# Push the image
docker push YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest
```

### Step 5: Clean Up

Once pushed, you can terminate the build Pod. The image is now on Docker Hub!

---

## 📋 Complete Script

Save this as `build-on-runpod.sh`:

```bash
#!/bin/bash
# Run this script inside your RunPod GPU Pod

set -e

echo "=========================================="
echo "  Gaussian-LIC Docker Build on RunPod"
echo "=========================================="

# Configuration
DOCKER_USERNAME="${1:-yourusername}"
IMAGE_NAME="gaussian-lic"
IMAGE_TAG="latest"

if [ "$DOCKER_USERNAME" = "yourusername" ]; then
    echo "Usage: $0 <your-dockerhub-username>"
    echo "Example: $0 john_doe"
    exit 1
fi

FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "Building: $FULL_IMAGE"
echo "This will take approximately 30-40 minutes..."
echo ""

# Update and install dependencies
echo "Installing dependencies..."
apt-get update && apt-get install -y git wget curl

# Clone Gaussian-LIC if not already present
if [ ! -d "/workspace/Gaussian-LIC" ]; then
    echo "Cloning Gaussian-LIC repository..."
    cd /workspace
    git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git
fi

# Create Dockerfile if not present
if [ ! -f "/workspace/Dockerfile" ]; then
    echo "Error: Dockerfile not found in /workspace/"
    echo "Please upload your Dockerfile to /workspace/"
    exit 1
fi

# Build the Docker image
echo ""
echo "Starting Docker build..."
echo "Start time: $(date)"
cd /workspace

docker build -t "$FULL_IMAGE" -f Dockerfile .

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed!"
    exit 1
fi

echo ""
echo "Build completed!"
echo "End time: $(date)"
echo ""

# Show image info
echo "Image details:"
docker images "$FULL_IMAGE"
echo ""

# Ask to push
read -p "Push to Docker Hub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Logging into Docker Hub..."
    docker login
    
    echo "Pushing image..."
    docker push "$FULL_IMAGE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "  SUCCESS!"
        echo "=========================================="
        echo "Image: $FULL_IMAGE"
        echo "Ready to use on RunPod!"
        echo ""
        echo "Next steps:"
        echo "1. Terminate this build Pod"
        echo "2. Deploy a new Pod with your image"
        echo "3. Start processing datasets!"
    else
        echo "Error: Failed to push image"
        exit 1
    fi
fi

echo ""
echo "Build Pod can now be terminated."
```

---

## 💡 Alternative: Use Pre-built Base Images

If you want to avoid building OpenCV (the slowest part), you can use a pre-built CUDA+OpenCV base image:

```dockerfile
# Option 1: Use OpenCV CUDA base
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04 as opencv-builder
# ... build OpenCV ...

# Option 2: Multi-stage build
FROM opencv-cuda-base:latest
# ... install only ROS and Gaussian-LIC ...
```

---

## 🔧 Troubleshooting

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean Docker cache
docker system prune -a

# Increase Container Disk when creating Pod
```

### Build Fails at OpenCV

```bash
# The download steps are cached, so rebuilding is faster
# Just run: docker build again
```

### Docker not installed

```bash
# Install Docker on RunPod Pod
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

---

## 📊 Build Time & Cost Breakdown

| GPU | Build Time | Cost | Notes |
|-----|------------|------|-------|
| RTX 3090 | 45-50 min | $0.18 | Cheapest option |
| RTX 4090 | 35-40 min | $0.23 | Faster, good value |
| RTX 5090 | 30-35 min | $0.35 | Fastest but pricier |

**Recommendation**: Use RTX 3090 for building (save money), then use RTX 5090 for processing.

---

## 🎯 After Building

Once your image is on Docker Hub:

1. **Terminate the build Pod** (stop paying)
2. **Deploy a new Pod** with your image
3. **Start processing** datasets immediately

Your image is now reusable across any number of Pods!

---

## 📚 Next Steps

After successful build:
- Read [QUICKSTART.md](./QUICKSTART.md) for usage
- See [DEPLOY_RTX5090.md](./DEPLOY_RTX5090.md) for RTX 5090 setup
- Check [CHEATSHEET.md](./CHEATSHEET.md) for commands

---

**Note**: Building on RunPod ensures compatibility and takes advantage of actual NVIDIA GPUs for CUDA compilation.

