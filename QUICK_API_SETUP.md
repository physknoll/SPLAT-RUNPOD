# 🚀 Quick API Setup (2 Minutes)

## Build from Your Mac Terminal - No Web Interface!

This is the **fastest** way to build. Everything from your Mac terminal using the RunPod API.

---

## Step 1: Install runpodctl v1.14.4+ (30 seconds)

**Important:** You need version **v1.14.4 or later**. Older versions (like 1.0.0-test) have file transfer bugs.

```bash
# macOS - Recommended: Direct install (most reliable)
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
rm /tmp/runpodctl.tar.gz
export PATH="$HOME/.local/bin:$PATH"
```

**Verify installation:**
```bash
runpodctl version
# Should show: runpodctl v1.14.4 (or higher)
```

**Note:** If you see `1.0.0-test`, your Homebrew installation is outdated. Use the direct install method above instead.

---

## Step 2: Get RunPod API Key (1 minute)

1. Go to: https://www.runpod.io/console/user/settings
2. Click **"API Keys"** (left side)
3. Click **"+ Create API Key"**
4. Name it: `Local Build`
5. Permissions: **Read & Write**
6. Click **"Create"**
7. **COPY THE KEY** (can't see it again!)

---

## Step 3: Set Environment Variables (30 seconds)

```bash
# Set RunPod API Key
export RUNPOD_API_KEY="your-runpod-api-key-here"

# Set Docker Hub credentials
export DOCKER_HUB_USERNAME="your-dockerhub-username"
export DOCKER_HUB_PASSWORD="your-dockerhub-password-or-token"
```

**Make it permanent** (optional):
```bash
echo 'export RUNPOD_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

---

## Step 4: Build! (35-40 minutes automated)

```bash
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

**That's it!** ✨

The script will:
- ✅ Create Pod on RunPod
- ✅ Upload your files
- ✅ Build Docker image
- ✅ Push to Docker Hub
- ✅ Clean up Pod
- ✅ All from your Mac!

---

## 💰 Cost: ~$0.25 (one-time)

---

## 🎯 Full Command Sequence

```bash
# 1. Install CLI (v1.14.4+)
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
export PATH="$HOME/.local/bin:$PATH"

# Verify version
runpodctl version  # Should show v1.14.4 or higher

# 2. Set API keys
export RUNPOD_API_KEY="rpk_..."
export DOCKER_HUB_PASSWORD="dckr_pat_..."

# 3. Build!
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-remote.sh YOUR_DOCKERHUB_USERNAME

# Done! Your image is on Docker Hub
```

---

## 📖 More Details

See **[REMOTE_BUILD_GUIDE.md](./REMOTE_BUILD_GUIDE.md)** for:
- Troubleshooting
- Advanced options
- Python alternative
- Cost breakdown

---

**Ready?** Just run:
```bash
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

All automated! 🎉

