#!/bin/bash
# Commands to run on RunPod via SSH

# 1. Navigate to workspace
cd /workspace

# 2. Clone Gaussian-LIC
git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git

# 3. Create Dockerfile
cat > Dockerfile << 'DOCKERFILE_END'
# Paste Dockerfile content here (see DOCKERFILE_CONTENT.txt)
DOCKERFILE_END

# 4. Build the Docker image (30-35 minutes on RTX 5090)
docker build --platform linux/amd64 -t rockrobotic961/gaussian-lic:latest .

# 5. Login to Docker Hub
echo "dckr_pat_WSWJv6850k2HmRiyUqTyagCAXTo" | docker login -u rockrobotic961 --password-stdin

# 6. Push to Docker Hub (5 minutes)
docker push rockrobotic961/gaussian-lic:latest

echo "✅ Build complete! Image pushed to Docker Hub"
