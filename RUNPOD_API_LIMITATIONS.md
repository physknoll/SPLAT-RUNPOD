# RunPod API Limitations & Workarounds

## Critical Understanding: What RunPod API Can and Cannot Do

Based on official RunPod documentation and our implementation experience.

---

## ✅ What the REST API **CAN** Do

1. **Pod Management**
   - Create/start/stop/delete pods
   - Configure GPU/CPU, disk size, volumes
   - Set CUDA versions, environment variables
   - Expose ports (including SSH)
   - Monitor pod status and get connection details

2. **Templates**
   - Create reusable pod configurations
   - Manage Docker images
   - Standardize deployments

3. **Storage**
   - Attach Network Volumes
   - Configure Cloud Sync (S3/GCS/Dropbox)

**Reference:** [RunPod API Docs](https://docs.runpod.io/api-reference/overview)

---

## ❌ What the REST API **CANNOT** Do

### 1. **No Interactive Shell Execution**
The API has **no "exec" endpoint** to run commands inside a pod.

**Workaround:** Use SSH after pod creation
```bash
# Get connection details from API
ssh -p <PORT> root@<PUBLIC_IP>
```

### 2. **No Direct File Upload/Download**
The API cannot push/pull arbitrary files to/from pods.

**Workarounds:**
- **Network Volumes**: Persistent storage across pods
- **Cloud Sync**: S3/GCS/Dropbox integration
- **SSH + tar/base64**: What our script uses (see below)

### 3. **No SCP/SFTP Support**
RunPod's SSH proxy doesn't support SCP or SFTP.

**Workaround:** Use tar+base64 over SSH/exec (our implementation)

**Reference:** [RunPod SSH Documentation](https://docs.runpod.io/pods/configuration/use-ssh)

---

## 🔧 Our Implementation: How We Work Around API Limits

### Problem: Need to Transfer Files to Pod

Since the API can't upload files and SCP doesn't work, we use:

**Method: tar+base64 via `runpodctl exec`**

```bash
# Compress, encode, pipe to pod via exec, decode and extract
tar -czf - . | base64 | runpodctl exec "$POD_ID" "base64 -d | tar -xzf - -C /workspace/"
```

**Why this works:**
- `runpodctl exec` can run commands (uses SSH under the hood)
- tar+base64 is binary-safe over text channels
- No need for SCP/SFTP support
- Works on any pod without special setup

### Problem: `runpodctl send` Command is Broken

The CLI has a `send/receive` feature, but:
- It's peer-to-peer (requires both sides to run commands)
- Old versions (1.0.0-test) have broken syntax
- Not reliable for automation

**Our solution:** Avoid `send/receive` entirely, use tar+base64 method

---

## 📋 Recommended Architecture

### For Building Docker Images on RunPod

1. **Create pod via API** (or runpodctl)
   ```bash
   curl -X POST https://rest.runpod.io/v2/pods \
     -H "Authorization: Bearer $RUNPOD_API_KEY" \
     -d '{"imageName": "runpod/pytorch:...", "ports": ["22/tcp"], ...}'
   ```

2. **Wait for pod to be RUNNING**
   ```bash
   curl https://rest.runpod.io/v2/pods/$POD_ID \
     -H "Authorization: Bearer $RUNPOD_API_KEY"
   ```

3. **Transfer files via tar+base64**
   ```bash
   tar -czf - -C $BUILD_DIR . | base64 | \
     runpodctl exec "$POD_ID" "base64 -d | tar -xzf - -C /workspace/"
   ```

4. **Execute build via exec**
   ```bash
   runpodctl exec "$POD_ID" "cd /workspace && docker build -t myimage ."
   ```

5. **Push to registry**
   ```bash
   runpodctl exec "$POD_ID" "docker push myimage"
   ```

6. **Cleanup via API**
   ```bash
   curl -X DELETE https://rest.runpod.io/v2/pods/$POD_ID \
     -H "Authorization: Bearer $RUNPOD_API_KEY"
   ```

**This is exactly what `build-remote.sh` does!**

---

## 🔑 Key Takeaways

### For Developers

1. **API is for lifecycle management** (create/stop/start/delete)
2. **SSH is for command execution** (no API exec endpoint)
3. **Volumes/Cloud Sync are for large file operations** (no API upload/download)
4. **tar+base64 over exec works for small file transfers** (our workaround)

### Why Our Solution Works

✅ **No API file upload needed** - we use tar+base64  
✅ **No SCP needed** - we pipe through exec  
✅ **No peer-to-peer setup** - exec is one-way  
✅ **Works with runpodctl v1.14.4+** - reliable exec command  
✅ **Fully automatable** - no manual steps  

---

## 📚 Official Documentation References

- **API Overview**: https://docs.runpod.io/api-reference/overview
- **Create Pod**: https://docs.runpod.io/api-reference/pods/POST/pods
- **SSH Setup**: https://docs.runpod.io/pods/configuration/use-ssh
- **File Transfer**: https://docs.runpod.io/pods/storage/transfer-files
- **Cloud Sync**: https://docs.runpod.io/pods/storage/cloud-sync
- **Network Volumes**: https://docs.runpod.io/storage/network-volumes

---

## 🎯 Alternative Approaches (Not Recommended for Our Use Case)

### Option A: Network Volumes
**Good for:** Persistent data across many pods  
**Bad for:** One-time builds (adds complexity and cost)

### Option B: Cloud Sync (S3/GCS)
**Good for:** Large datasets, public repos  
**Bad for:** Local development, requires cloud setup

### Option C: Git Clone Inside Pod
**Good for:** Public repos  
**Bad for:** Private repos, local changes not in Git

### Option D: Bake Everything Into Docker Image
**Good for:** Production deployments  
**Bad for:** Development iteration (slow rebuild cycles)

**Our tar+base64 method is best for:**
- ✅ Local development
- ✅ Quick iteration
- ✅ One-time builds
- ✅ No cloud dependencies
- ✅ Works with private code

---

## 💡 Future Improvements

If RunPod adds API features:

1. **Native file upload endpoint** - replace tar+base64
2. **API exec endpoint** - replace SSH dependency
3. **Better SCP support** - use standard tools

Until then, our current implementation is the most reliable approach.

---

**Bottom Line:** The RunPod REST API is for **pod lifecycle management**, not file I/O or command execution. For those, you need SSH + workarounds. Our `build-remote.sh` implements the most reliable workaround pattern. 🚀

