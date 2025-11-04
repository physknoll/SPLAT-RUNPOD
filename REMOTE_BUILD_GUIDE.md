# Build Gaussian-LIC Remotely via API (From Your Mac)

## 🎯 What This Does

This guide lets you build the Docker image **entirely from your Mac terminal** using the RunPod API. No web interface needed!

The script will:
1. ✅ Create a temporary GPU Pod on RunPod
2. ✅ Upload your local files (Dockerfile, Gaussian-LIC code)
3. ✅ Build the Docker image remotely
4. ✅ Push to Docker Hub
5. ✅ Clean up and terminate the Pod
6. ✅ All automated from your Mac!

**Cost**: ~$0.25 (one-time)  
**Time**: 35-40 minutes

---

## 📋 Prerequisites

### 1. Install runpodctl CLI (v1.14.4+)

**Critical:** You MUST use version **v1.14.4 or later**. Earlier versions have broken file transfer.

```bash
# macOS - Direct install (recommended)
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
export PATH="$HOME/.local/bin:$PATH"

# Verify version (IMPORTANT!)
runpodctl version
# Must show: runpodctl v1.14.4 or higher
# If it shows 1.0.0-test, you have the wrong version!
```

### 2. Get RunPod API Key

1. Go to https://www.runpod.io/console/user/settings
2. Click **"API Keys"** (left sidebar)
3. Click **"+ Create API Key"**
4. Name: "Local Build Automation"
5. Permissions: **Read & Write**
6. Click **"Create"** and **copy the key**

### 3. Set Environment Variables

```bash
# Add to ~/.zshrc (or ~/.bash_profile)
export RUNPOD_API_KEY="your-api-key-here"
export DOCKER_HUB_PASSWORD="your-dockerhub-password-or-token"

# Reload
source ~/.zshrc
```

Or set them temporarily:
```bash
export RUNPOD_API_KEY="your-api-key-here"
export DOCKER_HUB_PASSWORD="your-dockerhub-password-or-token"
```

---

## 🚀 Usage

### One Command Build:

```bash
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

**That's it!** The script handles everything:
- Creates Pod
- Uploads files
- Builds image
- Pushes to Docker Hub
- Cleans up Pod

---

## 📊 What Happens Step-by-Step

```
1. ✓ Checking prerequisites...
2. ✓ Creating build Pod (RTX 4090)...
3. ✓ Waiting for Pod to be ready...
4. ✓ Uploading Dockerfile + code...
5. ⏳ Building Docker image (30-40 min)...
6. ✓ Pushing to Docker Hub...
7. ✓ Cleaning up Pod...
8. ✨ DONE!
```

---

## 💻 Example Session

```bash
$ cd /Users/harrisonknoll/GaussianSplat-LIC2
$ ./build-remote.sh john_doe

==========================================
  Remote Docker Build on RunPod via API
==========================================

Configuration:
  Docker Image: john_doe/gaussian-lic:latest
  GPU: RTX 4090 (best value for building)
  Estimated time: 35-40 minutes
  Estimated cost: ~$0.25

Creating build Pod...
✓ Pod created: abc123xyz

Waiting for Pod to be ready...
✓ Pod is running!

✓ Connection: 194.123.45.67:12345

Preparing files...
✓ Files uploaded

==========================================
  Building Docker Image (30-40 minutes)
==========================================

[Build output streams here...]

==========================================
  ✨ BUILD SUCCESSFUL! ✨
==========================================

Image: john_doe/gaussian-lic:latest
Ready to use on RunPod!

Next steps:
1. Deploy a new Pod with your image
2. Use image: john_doe/gaussian-lic:latest
3. Start processing datasets!

Terminating build Pod...
```

---

## 🔧 Advanced Usage

### Custom GPU Selection

Edit `build-remote.sh` and change:
```bash
--gpuType "NVIDIA RTX 4090"  # Change to RTX 3090, RTX 5090, etc.
```

### Keep Pod Running (Debug)

Comment out the cleanup:
```bash
# trap cleanup EXIT  # Comment this line
```

Then manually clean up later:
```bash
runpodctl get pod  # Find your Pod ID
runpodctl remove pod <pod-id>
```

### Monitor Build Progress

The output streams in real-time to your terminal!

### Resume Failed Build

If build fails, the Pod is automatically cleaned up. Just run the script again - downloads are cached on Docker layers.

---

## 🆘 Troubleshooting

### "runpodctl version shows 1.0.0-test" ⚠️ CRITICAL

This is the #1 cause of connection failures!

**Solution:**
```bash
# Remove old version
brew uninstall runpodctl 2>/dev/null || true

# Install correct version
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
export PATH="$HOME/.local/bin:$PATH"

# Verify
runpodctl version  # Should show v1.14.4
```

**Why?** Version 1.0.0-test has broken `send` command syntax that causes "connection refused" errors.

### "RUNPOD_API_KEY not set"

```bash
export RUNPOD_API_KEY="your-key-here"
```

### "Failed to create Pod"

Check you have credits:
```bash
runpodctl get user
```

### "Connection timeout"

Some Pods take longer to start. The script waits up to 3 minutes.

### "Upload failed" or "Connection refused"

1. **Check runpodctl version first** (see above - must be v1.14.4+)
2. Ensure your files exist:
```bash
ls -la Dockerfile.fixed Gaussian-LIC/
```
3. The script now uses tar+base64 transfer method which is more reliable

### Check Pod Status

```bash
# Ensure you're using the right version
export PATH="$HOME/.local/bin:$PATH"

runpodctl get pod  # List all Pods
runpodctl get pod <pod-id>  # Specific Pod info
```

---

## 💰 Cost Breakdown

| Item | Duration | Rate | Cost |
|------|----------|------|------|
| Pod Creation | ~1 min | $0.34/hr | <$0.01 |
| Build | ~35 min | $0.34/hr | ~$0.20 |
| Push to Docker Hub | ~5 min | $0.34/hr | ~$0.03 |
| **Total** | **~41 min** | **RTX 4090** | **~$0.23** |

---

## 📋 Comparison: API vs Web Interface

| Aspect | API Method (This) | Web Interface |
|--------|-------------------|---------------|
| **Automation** | ✅ Fully automated | ❌ Manual steps |
| **Local Files** | ✅ Uploads from Mac | ❌ Must clone/upload |
| **Reproducible** | ✅ Script reusable | ❌ Manual each time |
| **CI/CD Ready** | ✅ Yes | ❌ No |
| **Monitoring** | ✅ Terminal output | 🟡 Web logs |
| **Setup** | 🟡 API key needed | ✅ Just account |

---

## 🎯 Benefits of API Method

✅ **No manual steps** - Everything automated  
✅ **Uses local files** - No need to push to GitHub first  
✅ **Reproducible** - Run the same script anytime  
✅ **CI/CD ready** - Can integrate into workflows  
✅ **Real-time output** - See build progress in terminal  
✅ **Automatic cleanup** - Pod terminated after build  

---

## 🔄 Alternative: Python Script

If you prefer Python over bash:

```python
#!/usr/bin/env python3
import runpod
import os

runpod.api_key = os.getenv('RUNPOD_API_KEY')

# Create Pod
pod = runpod.create_pod(
    name="gaussian-lic-build",
    image_name="runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel",
    gpu_type_id="NVIDIA RTX 4090",
    container_disk_in_gb=60
)

print(f"Pod created: {pod['id']}")

# Upload files, build, push...
# (Full implementation available)
```

---

## 📚 Next Steps

After successful build:

1. **Verify on Docker Hub**: https://hub.docker.com
2. **Deploy**: Follow `QUICKSTART.md` to use your image
3. **Process data**: Use `DEPLOY_RTX5090.md` for RTX 5090 setup

---

## 🆘 Support

- **runpodctl docs**: https://github.com/runpod/runpodctl
- **RunPod API docs**: https://docs.runpod.io/api-reference
- **Discord**: https://discord.gg/cUpRmau42V

---

**Ready to build?** Run:
```bash
export RUNPOD_API_KEY="your-key"
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

All done from your Mac terminal! 🚀

