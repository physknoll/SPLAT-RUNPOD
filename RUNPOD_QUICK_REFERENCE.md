# RunPod Quick Reference Card

## 🚀 Quick Build (3 Steps)

```bash
# 1. Verify setup
cd /Users/harrisonknoll/GaussianSplat-LIC2
./verify-runpod-setup.sh

# 2. Set credentials
export RUNPOD_API_KEY="rpk_your_key_here"
export DOCKER_HUB_PASSWORD="dckr_pat_your_token"

# 3. Build!
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

---

## ✅ Before You Start

### Check Your runpodctl Version

```bash
export PATH="$HOME/.local/bin:$PATH"
runpodctl version
```

**Must show:** `runpodctl v1.14.4` (or higher)  
**NOT:** `1.0.0-test` ← This version is broken!

### Update if Needed

```bash
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
export PATH="$HOME/.local/bin:$PATH"
```

---

## 🔑 Environment Variables

```bash
# Required
export RUNPOD_API_KEY="rpk_..."              # From RunPod console
export DOCKER_HUB_PASSWORD="dckr_pat_..."   # Docker Hub token

# Optional - add to ~/.zshrc to persist
echo 'export RUNPOD_API_KEY="rpk_..."' >> ~/.zshrc
echo 'export DOCKER_HUB_PASSWORD="dckr_pat_..."' >> ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 📝 Common Commands

### Build Image
```bash
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

### Check Build Status
```bash
# List all pods
runpodctl get pod

# Get specific pod details
runpodctl get pod <pod-id>

# Stop a pod
runpodctl stop pod <pod-id>
```

### Verify Setup
```bash
./verify-runpod-setup.sh
```

---

## 🆘 Troubleshooting

### Problem: "Connection refused" or "Unknown flag"
**Solution:** You have runpodctl 1.0.0-test. Update to v1.14.4 (see above).

### Problem: "RUNPOD_API_KEY not set"
**Solution:**
```bash
export RUNPOD_API_KEY="rpk_your_key"
```
Get key at: https://www.runpod.io/console/user/settings

### Problem: "Failed to create Pod"
**Solution:** Check credits:
```bash
runpodctl get user
```

### Problem: "Upload failed"
**Solution:**
1. Check version: `runpodctl version` (must be v1.14.4+)
2. Check files exist: `ls -la Dockerfile Gaussian-LIC/`
3. Try again (script has retry logic)

### Problem: Homebrew version is wrong
**Solution:** Don't use Homebrew version. Use direct install:
```bash
brew uninstall runpodctl  # Remove Homebrew version
# Then use the install commands above
```

---

## 💰 Cost Reference

| Operation | Duration | GPU | Cost |
|-----------|----------|-----|------|
| Build Image | 35-45 min | RTX 3090/4090 | ~$0.25-0.40 |
| Test Run | Per hour | RTX 5090 | ~$0.89/hr |
| Production | Per hour | H100 | ~$4.00/hr |

**Tip:** Use cheaper GPUs for building, expensive GPUs for running.

---

## 📂 File Structure

```
GaussianSplat-LIC2/
├── build-remote.sh              # Main build script
├── verify-runpod-setup.sh       # Setup verification
├── Dockerfile                   # Docker image definition
├── Gaussian-LIC/                # Source code
├── RUNPOD_FIX_SUMMARY.md       # What was fixed
├── RUNPOD_QUICK_REFERENCE.md   # This file
├── QUICK_API_SETUP.md          # Detailed setup guide
└── REMOTE_BUILD_GUIDE.md       # Complete reference
```

---

## 🎯 Workflow

1. **Build once** (this guide): ~$0.30, 40 minutes
2. **Push to Docker Hub**: Automatic
3. **Deploy many times**: Use your image from Docker Hub
4. **No rebuild needed**: Unless you change code

---

## 📚 Documentation

- **Quick Setup:** `QUICK_API_SETUP.md`
- **Full Guide:** `REMOTE_BUILD_GUIDE.md`
- **Fix Details:** `RUNPOD_FIX_SUMMARY.md`
- **API Limits:** `RUNPOD_API_LIMITATIONS.md` (technical deep-dive)
- **This Card:** `RUNPOD_QUICK_REFERENCE.md`

---

## ✨ Key Points

✅ **Use runpodctl v1.14.4+** (not 1.0.0-test)  
✅ **Build script auto-updates** runpodctl if needed  
✅ **New file transfer method** uses tar+base64 (reliable)  
✅ **No SSH setup needed** - works out of the box  
✅ **Auto cleanup** - pod terminates after build  

---

**Ready?** Run `./verify-runpod-setup.sh` then `./build-remote.sh YOUR_USERNAME` 🚀

