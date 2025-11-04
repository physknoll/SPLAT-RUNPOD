# 🎯 Manual Build on RunPod (10 minutes to start, 40 minutes build time)

## This Method is GUARANTEED to Work!

Since the CLI/API has version compatibility issues, here's the bulletproof manual method:

---

## Step 1: Create a Build Pod (2 minutes)

1. Go to: https://www.runpod.io/console/pods
2. Click **"+ Deploy"** (top right)
3. Select **"GPU Pod"**

**GPU Selection:**
- Filter: **"RTX 4090"** or **"RTX 3090"** (cheaper)
- Click on any available GPU card

**Configuration:**
- **Template**: Search for `pytorch` → Select **"PyTorch 2.1.0"** or similar with CUDA 11.8+
- **Container Disk**: `60 GB`
- **Volume Disk**: `0 GB` (not needed)
- **Pod Name**: `gaussian-lic-builder`

4. Click **"Deploy On-Demand"**
5. Wait ~30 seconds for Pod to start

---

## Step 2: Connect to Pod (1 minute)

1. Once Pod shows **"Running"**
2. Click **"Connect"** → **"Start Web Terminal"**
3. A terminal window opens in your browser

---

## Step 3: Upload Files (2 minutes)

In the **Web Terminal**:

```bash
# Navigate to workspace
cd /workspace

# Clone the repository
git clone https://github.com/APRIL-ZJU/Gaussian-LIC.git

# Create Dockerfile
cat > Dockerfile << 'EOF'
[COPY YOUR FULL DOCKERFILE CONTENT HERE]
EOF
```

**Alternative**: Use RunPod's file upload feature:
- Click the **folder icon** in top-left of terminal
- Upload your `Dockerfile` and `Gaussian-LIC` folder

---

## Step 4: Build Docker Image (35-40 minutes)

In the Web Terminal:

```bash
# Make sure Docker is available
docker --version

# Build the image (this takes 35-40 minutes)
docker build --platform linux/amd64 -t rockrobotic961/gaussian-lic:latest .
```

The build will run... go get coffee! ☕

---

## Step 5: Push to Docker Hub (5 minutes)

Once build completes:

```bash
# Login to Docker Hub
docker login -u rockrobotic961
# When prompted, paste your token:
# dckr_pat_WSWJv6850k2HmRiyUqTyagCAXTo

# Push the image
docker push rockrobotic961/gaussian-lic:latest
```

---

## Step 6: Clean Up

1. Go back to https://www.runpod.io/console/pods
2. Find your build Pod
3. Click **"⋮"** → **"Terminate"**

---

## ✅ Done!

Your image is now on Docker Hub: `rockrobotic961/gaussian-lic:latest`

**Next Steps:**
1. Deploy a new Pod with your image
2. Select RTX 5090 GPU
3. Start processing datasets!

---

## 💰 Cost Summary

- **Build Pod (RTX 4090)**: 45 minutes × $0.34/hr = **$0.26**
- **Total**: **$0.26** ✅

---

## 🐛 Troubleshooting

### Build fails partway through
- All downloads are cached in Docker layers
- Just run the `docker build` command again
- It will resume from the last successful step

### Docker not found
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### Out of disk space
- Increase Container Disk to 80 GB when creating Pod

---

## 📋 Quick Checklist

- [  ] Created build Pod with RTX 4090
- [ ] Connected to Web Terminal
- [ ] Uploaded Dockerfile and code
- [ ] Started Docker build
- [ ] Waited 35-40 minutes
- [ ] Pushed image to Docker Hub
- [ ] Terminated build Pod
- [ ] Ready to deploy!


