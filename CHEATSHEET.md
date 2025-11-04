# Gaussian-LIC on RunPod - Cheat Sheet

## 🚀 Quick Commands

### Build & Deploy
```bash
# Build Docker image (on Mac)
./build-and-push.sh YOUR_DOCKERHUB_USERNAME

# Deploy on RunPod
# GPU: RTX 5090 (32GB, $0.69/hr)
# Image: YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest
# Disk: 50GB
```

### Connect
```bash
# SSH
ssh root@<pod-ip> -p <port>

# Or use Web Terminal in RunPod dashboard
```

### Run Gaussian-LIC
```bash
# Terminal 1: Gaussian-LIC
cd /root/catkin_gaussian && source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch

# Terminal 2: Coco-LIC (after "Gaussian-LIC Ready!")
cd /root/catkin_coco && source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

### Download Results
```bash
# From Mac
scp -P <port> -r root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results
```

---

## 📁 Important Paths

| Path | Purpose |
|------|---------|
| `/workspace/datasets/` | Upload your .bag files here |
| `/root/catkin_gaussian/src/Gaussian-LIC/` | Gaussian-LIC source |
| `/root/catkin_coco/src/Coco-LIC/` | Coco-LIC source |
| `/root/catkin_gaussian/src/Gaussian-LIC/result/` | Output results |
| `/root/catkin_coco/src/Coco-LIC/config/` | Config files |

---

## 🛠️ Configuration Files

| Dataset | Config File |
|---------|-------------|
| FAST-LIVO | `ct_odometry_fastlivo.yaml` |
| R3LIVE | `ct_odometry_r3live.yaml` |
| MCD | `ct_odometry_mcd.yaml` |

**Edit config:**
```bash
nano /root/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml
```

**Key settings:**
```yaml
bag_path: "/workspace/datasets/your_dataset.bag"
max_iterations: 30000
batch_size: 4096  # Higher on RTX 5090
```

---

## 📊 Monitoring

```bash
# GPU usage
watch -n 1 nvidia-smi

# ROS topics
rostopic list
rostopic echo /gaussian_lic/status

# Logs
tail -f /root/.ros/log/latest/*.log
```

---

## 💰 Cost Calculator

**RTX 5090 @ $0.69/hr**

| Task | Time | Cost |
|------|------|------|
| Build Docker | 35 min | $0.40 |
| Process HKU2 | 8 min | $0.09 |
| Process larger dataset | 20 min | $0.23 |
| **Per hour idle** | 1 hr | **$0.01** (storage only) |

**Storage:**
- 50GB container: $5/month
- 100GB network volume: $7/month

---

## 🔧 Troubleshooting

### GPU Not Found
```bash
nvidia-smi  # Check if GPU is visible
# If not, restart Pod in dashboard
```

### Out of Memory (rare with 32GB)
```yaml
# Reduce in config:
batch_size: 2048
max_gaussians: 300000
```

### ROS Connection Issues
```bash
export ROS_MASTER_URI=http://localhost:11311
export ROS_IP=127.0.0.1
roscore &
```

### Build Failed
```bash
cd /root/catkin_gaussian
rm -rf build/ devel/
catkin_make
```

---

## 🎯 tmux Quick Reference

```bash
# Start
tmux new -s gaussian

# New window: Ctrl+B then C
# Switch windows: Ctrl+B then 0/1/2
# Detach: Ctrl+B then D
# Reattach: tmux attach -t gaussian
# List sessions: tmux ls
```

---

## 📥 Upload/Download Data

### Upload to Pod
```bash
# SCP
scp -P <port> data.bag root@<pod-ip>:/workspace/datasets/

# runpodctl
runpodctl send data.bag <pod-id>:/workspace/datasets/
```

### Download from Pod
```bash
# SCP
scp -P <port> -r root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result ./

# runpodctl
runpodctl receive <pod-id>:/root/catkin_gaussian/src/Gaussian-LIC/result ./
```

---

## 🎨 RTX 5090 Optimizations

```yaml
# Use 32GB VRAM to its fullest:
batch_size: 4096              # vs 2048 on 24GB
num_gaussians: 500000         # vs 300000 on 24GB
image_width: 1920             # vs 1280
image_height: 1080            # vs 720
max_iterations: 40000         # vs 30000
```

---

## ⚡ Power User Tips

1. **Batch Processing:**
```bash
for config in *.yaml; do
  roslaunch cocolic odometry.launch config_path:=config/$config
done
```

2. **Auto-stop after completion:**
```bash
roslaunch cocolic odometry.launch config_path:=config/dataset.yaml && \
  sudo shutdown -h now
```

3. **Persistent logs:**
```bash
roslaunch gaussian_lic fastlivo.launch 2>&1 | tee /workspace/gaussian.log
```

4. **Multiple datasets overnight:**
```bash
# Create script: process_all.sh
#!/bin/bash
datasets=("hku1.bag" "hku2.bag" "r0.bag")
for dataset in "${datasets[@]}"; do
  echo "Processing $dataset"
  # Update config with sed
  sed -i "s|bag_path:.*|bag_path: \"/workspace/datasets/$dataset\"|" config.yaml
  # Run
  roslaunch cocolic odometry.launch config_path:=config.yaml
done
```

---

## 📚 Documentation Quick Links

- **Full Guide**: [DEPLOY_RTX5090.md](./DEPLOY_RTX5090.md)
- **Quick Start**: [QUICKSTART.md](./QUICKSTART.md)
- **Comprehensive**: [README_RUNPOD.md](./README_RUNPOD.md)
- **Original Project**: https://github.com/APRIL-ZJU/Gaussian-LIC

---

## 🆘 Support

- **Issues**: GitHub Issues (original repo)
- **RunPod**: https://discord.gg/cUpRmau42V
- **Author**: jerry_locker@zju.edu.cn

---

*Last Updated: 2025*

