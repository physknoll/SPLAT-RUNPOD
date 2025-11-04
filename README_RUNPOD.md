# Running Gaussian-LIC on RunPod

This guide explains how to build and run Gaussian-LIC on RunPod using Docker.

## Prerequisites

1. A [RunPod account](https://www.runpod.io/)
2. A [Docker Hub account](https://hub.docker.com/) with access token
3. Sufficient credits in your RunPod account

## Step 1: Build and Push Docker Image Locally

If you have Docker installed locally with NVIDIA GPU support, you can build and push the image:

```bash
# Build the Docker image (this will take 30-60 minutes)
docker build -t yourusername/gaussian-lic:latest .

# Login to Docker Hub
docker login

# Push the image
docker push yourusername/gaussian-lic:latest
```

## Step 2: Deploy a RunPod Pod

1. Go to [RunPod Pods](https://www.runpod.io/console/pods)
2. Click **+ Deploy**
3. Choose **GPU** (Secure or Community Cloud)
4. Select a GPU instance:
   - **Recommended**: RTX 5090 (32GB VRAM) - Best performance/cost balance
   - **Alternatives**: RTX 4090 (24GB), L40S (48GB), or A40 (48GB)
   - **Minimum VRAM**: 24GB (32GB+ recommended for complex scenes)
5. Under **Container Image**, enter: `yourusername/gaussian-lic:latest`
6. Set **Container Disk** to at least 50GB
7. (Optional) Attach a Network Volume for persistent dataset storage
8. Click **Deploy On-Demand**

## Step 3: Connect to Your Pod

### Via Web Terminal

1. Click on your running Pod
2. Go to **Connect** tab
3. Click **Start Web Terminal**

### Via SSH

1. In the Pod details, find the SSH connection string
2. Connect from your local machine:
```bash
ssh root@<pod-ip> -p <port> -i ~/.ssh/id_ed25519
```

## Step 4: Download Dataset

Download one of the supported datasets:

```bash
cd /workspace/datasets

# Example: Download FAST-LIVO dataset (you'll need to get the actual link)
# Or upload your own .bag files
```

## Step 5: Configure Gaussian-LIC

Edit the configuration file to point to your dataset:

```bash
nano /root/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml
```

Update the `bag_path` parameter to your dataset location:
```yaml
bag_path: "/workspace/datasets/your_dataset.bag"
```

## Step 6: Run Gaussian-LIC

Open two terminals (or use tmux/screen):

### Terminal 1: Launch Gaussian-LIC
```bash
cd /root/catkin_gaussian
source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch
```

Wait until you see: **"😋 Gaussian-LIC Ready!"**

### Terminal 2: Launch Coco-LIC
```bash
cd /root/catkin_coco
source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

## Step 7: View Results

Results will be saved in:
```
/root/catkin_gaussian/src/Gaussian-LIC/result/
```

To download results to your local machine:

### Using runpodctl (from inside Pod):
```bash
runpodctl send result/ /workspace/output.tar.gz
```

### Using SCP (from your local machine):
```bash
scp -P <port> root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result/* ./local-results/
```

## Using Network Volumes

For persistent storage across Pod restarts:

1. Create a Network Volume in RunPod (e.g., 100GB)
2. Attach it to your Pod at `/workspace`
3. Store datasets and results there
4. The data persists even if you stop/restart the Pod

## Cost Optimization Tips

1. **Stop Pods when not in use**: You only pay for storage ($0.20/GB/month)
2. **Use Spot Instances**: Cheaper than on-demand, but can be interrupted
3. **Community Cloud**: Usually cheaper than Secure Cloud
4. **Right-size your GPU**: Development/testing may not need RTX 4090

## Estimated Costs (Community Cloud)

### GPU Costs
- **RTX 5090 (32GB)**: $0.69/hour ⭐ **RECOMMENDED**
- **RTX 4090 (24GB)**: $0.34/hour (budget option)
- **RTX 3090 (24GB)**: $0.22/hour (slowest, cheapest)
- **L40S (48GB)**: $0.79/hour (premium, fastest)
- **A40 (48GB)**: $0.35/hour (great value, larger VRAM)

### Storage Costs
- **Container Disk**: $0.10/GB/month (running), N/A (idle)
- **Network Volume**: $0.07/GB/month (<1TB), $0.05/GB/month (>1TB)

### Example Total Costs
**One-time setup + testing on HKU2 dataset:**
- Build image: ~35 min × $0.69 = **$0.40**
- Process dataset: ~10 min × $0.69 = **$0.12**
- Storage (50GB): ~$5/month or **$0.17/day**
- **Total for testing**: ~$0.52 + $0.17/day storage

**Regular usage (5 datasets/week):**
- Processing: 5 × 10 min × $0.69 = **$0.58/week**
- Storage: ~$5/month
- **Total**: ~$7.50/month

## Troubleshooting

### CUDA out of memory
- Use a GPU with more VRAM
- Reduce batch size in config files
- Close other GPU processes

### ROS connection issues
```bash
# Check ROS master
echo $ROS_MASTER_URI

# Restart roscore if needed
killall -9 roscore rosmaster
roscore &
```

### Build errors
```bash
# Rebuild Gaussian-LIC
cd /root/catkin_gaussian
rm -rf build/ devel/
catkin_make
```

## Advanced: Building on RunPod with Bazel

If you need to rebuild the Docker image on RunPod (useful for testing):

1. Deploy a Pod with a base CUDA image
2. Install Bazel following the RunPod Bazel tutorial
3. Build and push the image from within the Pod

## Support

- Gaussian-LIC Issues: https://github.com/APRIL-ZJU/Gaussian-LIC/issues
- RunPod Discord: https://discord.gg/cUpRmau42V
- Contact: jerry_locker@zju.edu.cn (Gaussian-LIC author)

