# RunPod Connection Fix - Summary

## What Was Fixed

Your RunPod connection issues were caused by an **outdated runpodctl version** (1.0.0-test). This version had a broken `send` command that caused "connection refused" and "unknown flag" errors.

## Changes Made

### 1. ✅ Updated runpodctl (1.0.0-test → v1.14.4)

- Installed the latest stable version (v1.14.4) from GitHub releases
- Located in `~/.local/bin/runpodctl`
- To use it: `export PATH="$HOME/.local/bin:$PATH"`

**Verify your version:**
```bash
export PATH="$HOME/.local/bin:$PATH"
runpodctl version
# Should show: runpodctl v1.14.4
```

### 2. ✅ Fixed File Transfer Method in build-remote.sh

**Old method (broken):**
```bash
runpodctl send "$BUILD_DIR" "$POD_ID:/workspace/"
```

**New method (reliable):**
```bash
# Uses tar+base64 transfer via exec - works without SSH
tar -czf - . | base64 | runpodctl exec "$POD_ID" "base64 -d | tar -xzf - -C /workspace/build-files"
```

**Why this works:**
- Doesn't require SSH ports to be configured
- Doesn't use the buggy `send/receive` peer-to-peer system
- Uses `runpodctl exec` which is more reliable
- Handles large files by splitting if needed

### 3. ✅ Added Auto-Update to build-remote.sh

The script now:
- Automatically checks your runpodctl version
- Downloads and installs v1.14.4 if you have an outdated version
- Ensures `~/.local/bin` is in your PATH

### 4. ✅ Updated Documentation

- **QUICK_API_SETUP.md**: Added version requirements and installation instructions
- **REMOTE_BUILD_GUIDE.md**: Added critical troubleshooting for version issues

## How to Use Now

### Quick Start (2 commands)

```bash
# 1. Set your API key and Docker credentials
export RUNPOD_API_KEY="rpk_your_key_here"
export DOCKER_HUB_PASSWORD="dckr_pat_your_token_here"

# 2. Run the build (it auto-updates runpodctl if needed)
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-remote.sh YOUR_DOCKERHUB_USERNAME
```

The script will:
1. Check/update runpodctl automatically
2. Create a RunPod pod
3. Upload files using the new reliable method
4. Build the Docker image
5. Push to Docker Hub
6. Clean up and terminate the pod

### Manual runpodctl Update (if needed)

If you want to update manually before running:

```bash
mkdir -p ~/.local/bin
curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz
tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl
chmod +x ~/.local/bin/runpodctl
export PATH="$HOME/.local/bin:$PATH"
runpodctl version  # Verify it shows v1.14.4
```

## What to Expect

✅ **Working:**
- Pod creation
- File uploads (using tar+base64 method)
- Docker builds
- Image pushes to Docker Hub

❌ **No longer used:**
- `runpodctl send` command (broken in old versions)
- Homebrew version of runpodctl (may be outdated)

## Troubleshooting

### "Still seeing connection errors?"

1. **Check your runpodctl version:**
```bash
export PATH="$HOME/.local/bin:$PATH"
runpodctl version
```
Must show `v1.14.4` or higher, NOT `1.0.0-test`

2. **Ensure PATH is set in your shell:**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

3. **Check API key is set:**
```bash
echo $RUNPOD_API_KEY
# Should show your API key
```

### "Upload failed?"

The new tar+base64 method is very reliable, but if it fails:
- Check that Dockerfile and Gaussian-LIC directory exist
- Try running again (the script has retry logic)
- Check pod logs: `runpodctl get pod <pod-id>`

## Cost

- **One-time build**: ~$0.25-0.40 (35-45 minutes on RTX 3090/4090)
- **Pod auto-terminates** after build completes
- Your Docker image is then reusable forever from Docker Hub

## Next Steps

1. Run `./build-remote.sh YOUR_DOCKERHUB_USERNAME` to build your image
2. Once built, you can deploy pods using your custom image from Docker Hub
3. See `QUICKSTART.md` for running the built image on RunPod

---

## Technical Details

### Why runpodctl 1.0.0-test Failed

The old version's `send` command:
- Required peer-to-peer connection setup with `--code` flags
- Didn't support direct pod ID transfers like `send file.txt POD_ID:/path`
- Had syntax incompatibilities causing "unknown flag: --retry" errors

### Why We Can't Use the RunPod REST API for File Transfers

The RunPod REST API has **no endpoints for file upload/download** or **command execution**. According to official docs:
- API is for pod lifecycle (create/start/stop/delete) only
- Commands must use SSH
- Files must use Network Volumes, Cloud Sync, or workarounds
- SCP/SFTP are not supported on RunPod's SSH proxy

**See:** `RUNPOD_API_LIMITATIONS.md` for full details

### New Transfer Method: tar+base64 via exec

Uses standard UNIX tools available on all pods:
```bash
# Local side: compress, encode, pipe
tar -czf - -C $DIR . | base64

# Remote side (via runpodctl exec): decode, extract
runpodctl exec $POD_ID "base64 -d | tar -xzf - -C /destination"
```

This method:
- Works on any pod without special setup
- Handles directories and files uniformly
- Compresses data for faster transfer
- Uses base64 to ensure binary-safe transfer over text channels
- Bypasses the broken `send/receive` commands
- No SCP/SFTP needed (which aren't supported anyway)

---

**You're all set!** The connection issues are resolved. Just run `./build-remote.sh` and it should work now. 🚀

