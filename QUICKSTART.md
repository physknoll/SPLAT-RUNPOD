# Gaussian-LIC on RunPod - Quick Start Guide

## 🚀 Fast Track: Get Running in 10 Minutes

### Option 1: Use Pre-built Image (Coming Soon)
```
Image: yourusername/gaussian-lic:latest
```

### Option 2: Build Your Own Image

#### Step 1: Build and Push Docker Image

From your Mac (or any machine with Docker):

```bash
# Clone and navigate to the project
cd /Users/harrisonknoll/GaussianSplat-LIC2

# Build and push (replace 'yourusername' with your Docker Hub username)
./build-and-push.sh yourusername
```

**Note**: Building will take 30-60 minutes. Grab a coffee! ☕

#### Step 2: Deploy on RunPod

1. Go to https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. Select:
   - **GPU**: RTX 5090 (32GB VRAM) - **RECOMMENDED**
   - **Container Image**: `yourusername/gaussian-lic:latest`
   - **Container Disk**: 50GB minimum
   - **Volume**: Optional (recommended for large datasets)
   - **Alternatives**: RTX 4090, A40, or L40S if 5090 unavailable
4. Click **Deploy On-Demand**

#### Step 3: Connect and Run

**Option A: Web Terminal** (Easiest)
1. Click your Pod → **Connect** tab
2. Click **Start Web Terminal**
3. You're in!

**Option B: SSH** (More flexible)
1. Add your SSH key in RunPod settings
2. Use the SSH command from Pod details:
```bash
ssh root@<pod-ip> -p <port>
```

#### Step 4: Prepare Dataset

```bash
# Inside your RunPod terminal
cd /workspace/datasets

# Upload your .bag file or download dataset
# Example: Using runpodctl to receive files
runpodctl receive your-dataset.bag
```

#### Step 5: Configure

```bash
nano /root/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml
```

Update the `bag_path`:
```yaml
bag_path: "/workspace/datasets/your-dataset.bag"
```

#### Step 6: Launch Gaussian-LIC

**Terminal 1:**
```bash
cd /root/catkin_gaussian
source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch
```

Wait for: `😋 Gaussian-LIC Ready!`

**Terminal 2:**
```bash
cd /root/catkin_coco
source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

#### Step 7: Get Results

Results are in `/root/catkin_gaussian/src/Gaussian-LIC/result/`

**Download to your Mac:**
```bash
# From your Mac terminal
scp -P <port> -r root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results
```

---

## 💰 Cost Estimates (Community Cloud)

| GPU | VRAM | Cost/Hour | Build Time | Run Time (HKU2) | Notes |
|-----|------|-----------|------------|-----------------|-------|
| **RTX 5090** ⭐ | **32GB** | **$0.69** | **35-40 min** | **~8-10 min** | **Best value** |
| RTX 4090 | 24GB | $0.34 | 40-50 min | ~10-12 min | Good alternative |
| RTX 3090 | 24GB | $0.22 | 50-60 min | ~12-15 min | Budget option |
| L40S | 48GB | $0.79 | 30-35 min | ~7-10 min | Premium option |
| A40 | 48GB | $0.35 | 35-45 min | ~8-12 min | Great value |

**Storage**: 
- Container Disk: $0.10/GB/month (running)
- Network Volume: $0.07/GB/month (under 1TB), $0.05/GB/month (over 1TB)

---

## 🎯 Supported Datasets

- **FAST-LIVO Dataset**: HKU1, HKU2, FAST sequences
- **R3LIVE Dataset**: Various indoor/outdoor scenes  
- **MCD Dataset**: Multi-sensor datasets

Download links:
- [FAST-LIVO](https://connecthkuhk-my.sharepoint.com/:f:/g/personal/zhengcr_connect_hku_hk/EhxC2fDOlwdJiYnLQiuC3HoBZCGXhSHDRCRtCDzGTfSQAQ?e=P6N4nW)
- [R3LIVE](https://github.com/ziv-lin/r3live_dataset)
- [MCD](https://mcdviral.github.io/)

---

## 🛠️ Troubleshooting

### CUDA Out of Memory
```bash
# Choose larger GPU or reduce batch size
# Edit config files to reduce memory usage
```

### ROS Master Not Found
```bash
export ROS_MASTER_URI=http://localhost:11311
export ROS_IP=127.0.0.1
roscore &
```

### Can't Connect to Pod
- Check Pod status (should be "Running")
- Verify SSH key is added in RunPod settings
- Try Web Terminal instead

---

## 💡 Pro Tips

1. **Use tmux/screen**: Manage multiple terminals easily
   ```bash
   apt-get update && apt-get install -y tmux
   tmux new -s gaussian
   # Ctrl+B then C to create new window
   # Ctrl+B then 0/1/2 to switch windows
   ```

2. **Network Volume for Datasets**: Attach a persistent volume to `/workspace`
   - Datasets persist across Pod restarts
   - Share datasets between different Pods

3. **Snapshot Your Configuration**: Once working, save a Pod snapshot for quick re-deployment

4. **Monitor GPU Usage**:
   ```bash
   watch -n 1 nvidia-smi
   ```

5. **Save Costs**: Stop Pod when not in use (data in Network Volume persists)

---

## 📚 Next Steps

- Read full documentation: [README_RUNPOD.md](./README_RUNPOD.md)
- Original project: https://github.com/APRIL-ZJU/Gaussian-LIC
- Paper: https://arxiv.org/pdf/2404.06926
- Project page: https://xingxingzuo.github.io/gaussian_lic/

---

## 🆘 Need Help?

- **Gaussian-LIC Issues**: GitHub Issues on original repo
- **RunPod Support**: https://discord.gg/cUpRmau42V
- **Contact**: jerry_locker@zju.edu.cn

Happy mapping! 🗺️✨

