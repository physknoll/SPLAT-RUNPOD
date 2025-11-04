# Deploy Gaussian-LIC on RunPod with RTX 5090

## Why RTX 5090?

The RTX 5090 offers the **best balance** for Gaussian-LIC:

✅ **32GB VRAM** - 33% more than RTX 4090 (24GB)  
✅ **$0.69/hour** - Only $0.35 more than RTX 4090  
✅ **Ada Lovelace architecture** - Latest NVIDIA architecture with enhanced ray tracing  
✅ **Fast build times** - ~35 minutes to build Docker image  
✅ **Real-time performance** - Process most datasets in under 10 minutes

### Performance Comparison

| Metric | RTX 3090 | RTX 4090 | RTX 5090 ⭐ | L40S | A40 |
|--------|----------|----------|------------|------|-----|
| **VRAM** | 24GB | 24GB | **32GB** | 48GB | 48GB |
| **Architecture** | Ampere | Ada | **Ada** | Ada | Ampere |
| **Cost/hour** | $0.22 | $0.34 | **$0.69** | $0.79 | $0.35 |
| **Build time** | ~50 min | ~40 min | **~35 min** | ~30 min | ~40 min |
| **Processing (HKU2)** | ~15 min | ~10 min | **~8 min** | ~7 min | ~10 min |
| **Cost/dataset** | $0.06 | $0.06 | **$0.09** | $0.09 | $0.06 |

**Winner: RTX 5090** - Best future-proofing with extra VRAM for complex scenes

---

## Step-by-Step Deployment

### 1. Build Docker Image

First, build the image on your Mac or on RunPod:

```bash
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-and-push.sh YOUR_DOCKERHUB_USERNAME
```

This creates: `YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest`

---

### 2. Configure RunPod Pod

Go to [RunPod Console](https://www.runpod.io/console/pods) and click **+ Deploy**:

#### GPU Configuration
- **Cloud Type**: Community Cloud (cheaper) or Secure Cloud (more reliable)
- **GPU Type**: Select **RTX 5090**
  - Filter by: `32GB VRAM`
  - Look for: `RTX 5090` in the GPU name
- **GPU Count**: 1 (single GPU is sufficient)

#### Container Configuration
- **Template**: Select "Custom"
- **Container Image**: `YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest`
- **Container Disk**: 50GB minimum (60GB recommended)
- **Expose HTTP Ports**: 8888 (optional, for Jupyter)
- **Expose TCP Ports**: 11311 (optional, for ROS master)

#### Storage Configuration

**Option A: Container Disk Only (Simple)**
- No network volume
- Data lost when Pod terminates
- Good for: Testing, one-off processing

**Option B: With Network Volume (Recommended)**
- Create new volume: 100GB (or attach existing)
- Mount path: `/workspace`
- Data persists across Pod restarts
- Good for: Production, multiple datasets

#### Advanced Options
- **Environment Variables** (optional):
```bash
ROS_MASTER_URI=http://localhost:11311
ROS_IP=127.0.0.1
DISPLAY=:0
```

- **Docker Command** (optional, uses default entrypoint):
```bash
/runpod-start.sh
```

---

### 3. Deploy and Connect

Click **Deploy On-Demand** (or **Deploy Spot** for 30-50% savings with interruption risk)

**Wait for initialization**: ~2-3 minutes

#### Connection Method A: Web Terminal
1. Click your running Pod
2. **Connect** tab → **Start Web Terminal**
3. Login (default: root)

#### Connection Method B: SSH
1. Add SSH key: Settings → SSH Public Keys
2. Copy SSH command from Pod details:
```bash
ssh root@<pod-ip> -p <port> -i ~/.ssh/id_ed25519
```

#### Connection Method C: VS Code Remote
1. Install "Remote - SSH" extension
2. Add SSH config:
```
Host runpod-gaussian
    HostName <pod-ip>
    User root
    Port <port>
    IdentityFile ~/.ssh/id_ed25519
```
3. Connect: `CMD+Shift+P` → "Remote-SSH: Connect to Host" → `runpod-gaussian`

---

### 4. Verify Installation

Inside your Pod terminal:

```bash
# Check GPU
nvidia-smi

# Expected output:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 535.xx.xx    Driver Version: 535.xx.xx    CUDA Version: 11.7   |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |                               |                      |               MIG M. |
# |===============================+======================+======================|
# |   0  NVIDIA GeForce ...  Off  | 00000000:00:05.0 Off |                  N/A |
# |  0%   35C    P0    50W / 450W |      0MiB / 32768MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+

# Check ROS
rosversion -d
# Expected: noetic

# Check workspaces
ls -la /root/catkin_gaussian/src/Gaussian-LIC
ls -la /root/catkin_coco/src/Coco-LIC
```

---

### 5. Upload Dataset

#### Method A: Direct Upload via Web UI
1. RunPod Dashboard → Your Pod → Files
2. Navigate to `/workspace/datasets/`
3. Upload your `.bag` file

#### Method B: Using runpodctl (from local machine)
```bash
# Install runpodctl on your Mac
brew install runpod/runpodctl/runpodctl

# Send file to Pod
runpodctl send data/hku2.bag <pod-id>:/workspace/datasets/
```

#### Method C: wget/curl (if dataset has URL)
```bash
# Inside Pod
cd /workspace/datasets
wget https://example.com/dataset.bag
```

#### Method D: SCP from your Mac
```bash
# From your Mac
scp -P <port> path/to/dataset.bag root@<pod-ip>:/workspace/datasets/
```

---

### 6. Configure Gaussian-LIC

Edit the Coco-LIC configuration:

```bash
nano /root/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml
```

Update these parameters:

```yaml
# Dataset path
bag_path: "/workspace/datasets/hku2.bag"

# Output path (optional)
output_path: "/workspace/results/"

# Performance tuning for RTX 5090
max_iterations: 30000  # Can increase with more VRAM
batch_size: 4096       # Larger batches with 32GB VRAM
```

For different datasets, use different config files:
- **FAST-LIVO**: `ct_odometry_fastlivo.yaml`
- **R3LIVE**: `ct_odometry_r3live.yaml`
- **MCD**: `ct_odometry_mcd.yaml`

---

### 7. Launch Gaussian-LIC

#### Using tmux (Recommended)

```bash
# Install tmux
apt-get update && apt-get install -y tmux

# Start tmux session
tmux new -s gaussian

# Window 0: Launch Gaussian-LIC
cd /root/catkin_gaussian
source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch

# Create new window: Ctrl+B then C
# Window 1: Launch Coco-LIC (wait for "Gaussian-LIC Ready!")
cd /root/catkin_coco
source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml

# Switch windows: Ctrl+B then 0 or 1
# Detach from tmux: Ctrl+B then D
# Reattach: tmux attach -t gaussian
```

#### Using screen (Alternative)

```bash
# Terminal 1
screen -S gaussian-lic
cd /root/catkin_gaussian
source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch
# Detach: Ctrl+A then D

# Terminal 2
screen -S coco-lic
cd /root/catkin_coco
source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
# Detach: Ctrl+A then D

# Reattach: screen -r gaussian-lic or screen -r coco-lic
```

---

### 8. Monitor Progress

#### Watch GPU Usage
```bash
watch -n 1 nvidia-smi
```

Expected during processing:
- **GPU Utilization**: 80-100%
- **Memory Usage**: 12-20GB (out of 32GB)
- **Temperature**: 60-80°C
- **Power**: 250-400W

#### Check ROS Topics
```bash
rostopic list
rostopic echo /gaussian_lic/status
```

#### View Logs
```bash
# Gaussian-LIC logs
tail -f /root/.ros/log/latest/gaussian_lic-gs_mapping-*.log

# Coco-LIC logs
tail -f /root/.ros/log/latest/cocolic-*.log
```

---

### 9. Retrieve Results

Results are saved to: `/root/catkin_gaussian/src/Gaussian-LIC/result/`

#### Method A: SCP to Your Mac
```bash
# From your Mac terminal
scp -P <port> -r root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results
```

#### Method B: Via RunPod Web UI
1. Pod Dashboard → Files
2. Navigate to result folder
3. Download files

#### Method C: Using runpodctl
```bash
# From your Mac
runpodctl receive <pod-id>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results
```

---

### 10. Stop or Terminate Pod

#### Stop Pod (Keep data)
```bash
# From RunPod dashboard
Click Pod → Stop (pause icon)
```
- GPU billing stops
- Container disk: $0.10/GB/month
- Network volume: $0.07/GB/month

#### Terminate Pod (Delete everything)
```bash
# From RunPod dashboard  
Click Pod → Terminate (trash icon)
```
- **Warning**: All data in container disk is lost
- Network volume data persists

---

## RTX 5090 Optimization Tips

### 1. Increase Batch Sizes
With 32GB VRAM, you can use larger batches:

```yaml
# In config files
batch_size: 4096        # vs 2048 on 24GB cards
num_gaussians: 500000   # vs 300000 on 24GB cards
```

### 2. Higher Resolution Rendering
```yaml
image_width: 1920   # vs 1280
image_height: 1080  # vs 720
```

### 3. More Optimization Iterations
```yaml
max_iterations: 40000  # vs 30000 on smaller cards
```

### 4. Process Multiple Sequences
With extra VRAM, you can process back-to-back without restarting:

```bash
# Process multiple datasets
roslaunch cocolic odometry.launch config_path:=config/dataset1.yaml
# Wait for completion
roslaunch cocolic odometry.launch config_path:=config/dataset2.yaml
```

---

## Troubleshooting RTX 5090 Specific Issues

### Issue: GPU Not Detected
```bash
# Check NVIDIA driver
nvidia-smi

# If error, restart container
# RunPod Dashboard → Pod → Restart
```

### Issue: CUDA Out of Memory (Rare with 32GB)
```bash
# Reduce batch size in config
batch_size: 2048

# Or reduce Gaussian count
max_gaussians: 300000
```

### Issue: Slow Performance
```bash
# Check GPU clock speeds
nvidia-smi -q -d CLOCK

# Enable persistence mode
nvidia-smi -pm 1

# Check for throttling
nvidia-smi -q -d PERFORMANCE
```

---

## Cost Management for RTX 5090

### Minimize Costs
1. **Build once, reuse**: Push image to Docker Hub, don't rebuild
2. **Use Spot instances**: 30-50% cheaper (risk of interruption)
3. **Stop when idle**: $0.69/hr → $0.01/hr (storage only)
4. **Batch processing**: Process multiple datasets in one session
5. **Network volumes**: Share datasets across pods

### Example Cost Breakdown
**Weekly usage (10 datasets):**
- Processing: 10 × 8 min × $0.69/hr = **$0.92**
- Storage: 100GB × $0.07/GB = **$7/month** = $1.75/week
- **Total**: ~$2.67/week

**Monthly cost**: ~$11.68/month (vs ~$25-30 on AWS/GCP)

---

## Next Steps

- 📚 Read [QUICKSTART.md](./QUICKSTART.md) for quick commands
- 📖 Check [README_RUNPOD.md](./README_RUNPOD.md) for comprehensive guide
- 🔧 Optimize parameters for your specific datasets
- 💾 Set up automated backups of results to cloud storage
- 🚀 Scale to multiple Pods for parallel processing

---

## Support

- **Gaussian-LIC**: https://github.com/APRIL-ZJU/Gaussian-LIC/issues
- **RunPod Discord**: https://discord.gg/cUpRmau42V
- **Author**: jerry_locker@zju.edu.cn

Happy mapping with RTX 5090! 🚀✨

