# Gaussian-LIC on RunPod with RTX 5090

> Real-Time Photo-Realistic SLAM with Gaussian Splatting and LiDAR-Inertial-Camera Fusion  
> Optimized Docker deployment for RunPod GPU cloud platform

## 🎯 Overview

This repository contains a **production-ready Docker setup** for deploying [Gaussian-LIC](https://github.com/APRIL-ZJU/Gaussian-LIC) (ICRA 2025) on RunPod's cloud GPU infrastructure. Run photo-realistic SLAM with NVIDIA RTX 5090 GPUs at **$0.69/hour**.

### Why This Repo?

❌ **Can't run on MacBook Pro** - Requires CUDA, only available on NVIDIA GPUs  
✅ **RunPod provides cloud GPUs** - RTX 5090 with 32GB VRAM  
✅ **Complete Docker environment** - Everything pre-configured  
✅ **Cost-effective** - Pay only when processing ($0.09/dataset)

---

## 🚀 Quick Start

### ⚠️ Important: Build on RunPod, Not Mac!

**Your Mac cannot build this image** (no NVIDIA GPU/CUDA support).

**✅ Solution**: Build on RunPod in 30-40 minutes for $0.25-0.40

See **[BUILD_ON_RUNPOD.md](./BUILD_ON_RUNPOD.md)** for complete build instructions.

### 1. Build Docker Image on RunPod
```bash
# On a RunPod GPU Pod (RTX 3090/4090):
cd /workspace
git clone <your-repo-with-dockerfile>
./build-on-runpod.sh YOUR_DOCKERHUB_USERNAME
```

### 2. Deploy on RunPod
1. Go to [RunPod Pods](https://www.runpod.io/console/pods)
2. Click **Deploy** → Select **RTX 5090** → Use image: `YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest`
3. Set **Container Disk**: 50GB

### 3. Run
```bash
# Terminal 1
cd /root/catkin_gaussian && source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch

# Terminal 2 (wait for "Gaussian-LIC Ready!")
cd /root/catkin_coco && source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

**Full details**: See [QUICKSTART.md](./QUICKSTART.md)

---

## 📋 What's Included

### Docker Image Contains:
- ✅ Ubuntu 20.04 + CUDA 11.7 + cuDNN 8
- ✅ ROS Noetic (fully configured)
- ✅ OpenCV 4.7.0 (built with CUDA support)
- ✅ LibTorch 2.0.1 (PyTorch C++ API)
- ✅ Coco-LIC (LiDAR-Inertial-Camera odometry)
- ✅ Gaussian-LIC (3D Gaussian Splatting SLAM)

### Files in This Repo:
- `Dockerfile` - Complete build configuration
- `build-and-push.sh` - Automated build & push script
- `QUICKSTART.md` - 10-minute deployment guide
- `DEPLOY_RTX5090.md` - Comprehensive RTX 5090 guide
- `README_RUNPOD.md` - Full RunPod documentation
- `CHEATSHEET.md` - Quick command reference

---

## 💰 Pricing (Community Cloud)

### RTX 5090 (Recommended)
- **GPU**: $0.69/hour
- **Storage**: $0.10/GB/month (running), $0.01/GB/month (stopped)
- **Network Volume**: $0.07/GB/month

### Example Costs:
| Task | Time | Cost |
|------|------|------|
| Build Docker image | 35 min | $0.40 |
| Process HKU2 dataset | 8 min | $0.09 |
| Process 10 datasets | ~80 min | $0.90 |
| **Monthly (10 datasets/week)** | - | **~$8-12** |

### Alternatives:
- **RTX 4090** (24GB): $0.34/hr - Budget option
- **RTX 3090** (24GB): $0.22/hr - Cheapest (slower)
- **L40S** (48GB): $0.79/hr - Premium performance
- **A40** (48GB): $0.35/hr - Great value

---

## 🎯 GPU Comparison

| GPU | VRAM | Cost/hr | Build Time | Process HKU2 | Best For |
|-----|------|---------|------------|--------------|----------|
| **RTX 5090** ⭐ | **32GB** | **$0.69** | **35 min** | **8 min** | **Best overall** |
| RTX 4090 | 24GB | $0.34 | 40 min | 10 min | Budget choice |
| RTX 3090 | 24GB | $0.22 | 50 min | 15 min | Testing |
| L40S | 48GB | $0.79 | 30 min | 7 min | Complex scenes |
| A40 | 48GB | $0.35 | 40 min | 10 min | Large datasets |

**Why RTX 5090?**
- 32GB VRAM = Handle larger, more complex scenes
- Latest Ada Lovelace architecture
- 33% more memory than 4090 for only $0.35/hr more
- Future-proof for upcoming Gaussian-LIC2

---

## 📦 Installation Requirements

### On Your Local Machine (Mac/Linux/Windows):
- Docker (for building the image)
- Docker Hub account
- Git

### On RunPod:
- Nothing! Just deploy the pre-built image
- RunPod account with credits

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[QUICKSTART.md](./QUICKSTART.md)** | Get running in 10 minutes |
| **[DEPLOY_RTX5090.md](./DEPLOY_RTX5090.md)** | Complete RTX 5090 deployment guide |
| **[README_RUNPOD.md](./README_RUNPOD.md)** | Full RunPod documentation |
| **[CHEATSHEET.md](./CHEATSHEET.md)** | Quick command reference |

---

## 🗺️ Supported Datasets

- **[FAST-LIVO Dataset](https://connecthkuhk-my.sharepoint.com/:f:/g/personal/zhengcr_connect_hku_hk/EhxC2fDOlwdJiYnLQiuC3HoBZCGXhSHDRCRtCDzGTfSQAQ?e=P6N4nW)**
  - HKU1, HKU2, FAST sequences
  - LiDAR + IMU + Camera

- **[R3LIVE Dataset](https://github.com/ziv-lin/r3live_dataset)**
  - Indoor/outdoor scenes
  - RGB-LiDAR fusion

- **[MCD Dataset](https://mcdviral.github.io/)**
  - Multi-sensor SLAM
  - Various environments

---

## 🔧 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your MacBook Pro                      │
│  (Build Docker image & push to Docker Hub)              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Docker Hub                           │
│  (Store your custom Gaussian-LIC image)                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  RunPod RTX 5090 Pod                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │  ROS Noetic + CUDA 11.7 + cuDNN 8                  │ │
│  │  ┌──────────────┐       ┌──────────────┐          │ │
│  │  │  Coco-LIC    │──────▶│ Gaussian-LIC │          │ │
│  │  │  (Odometry)  │ poses │  (Mapping)   │          │ │
│  │  └──────────────┘       └──────────────┘          │ │
│  │         │                       │                  │ │
│  │         ▼                       ▼                  │ │
│  │  .bag dataset           3D Gaussian map           │ │
│  └────────────────────────────────────────────────────┘ │
│                    32GB GPU Memory                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 Download Results to Mac                  │
│  (Photo-realistic 3D reconstructions)                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🎨 Sample Results

Gaussian-LIC produces photo-realistic 3D reconstructions:

- **Point clouds** with color information
- **3D Gaussian maps** for real-time rendering
- **Camera trajectories** with accurate poses
- **Novel view synthesis** capabilities

Example datasets: HKU campus, indoor labs, outdoor streets

---

## 🛠️ Advanced Features

### RTX 5090 Optimizations
With 32GB VRAM, you can:
- Increase batch size to 4096 (vs 2048 on 24GB cards)
- Process 500K+ Gaussians (vs 300K limit)
- Higher resolution rendering (1920×1080 vs 1280×720)
- More optimization iterations (40K vs 30K)

### Batch Processing
Process multiple datasets automatically:
```bash
for dataset in *.bag; do
  # Auto-process each dataset
done
```

### Network Volumes
Persistent storage that survives Pod restarts:
- Share datasets across multiple Pods
- Keep results accessible
- Cost: $0.07/GB/month

---

## 🆘 Troubleshooting

### Common Issues:

**Docker build fails**
- Increase Docker memory allocation (8GB+)
- Ensure stable internet connection
- Build time: 30-60 minutes is normal

**CUDA out of memory**
- RTX 5090 has 32GB - rare issue
- Reduce batch_size in config files
- Close other processes

**ROS connection errors**
```bash
export ROS_MASTER_URI=http://localhost:11311
roscore &
```

**Full troubleshooting**: [DEPLOY_RTX5090.md](./DEPLOY_RTX5090.md)

---

## 🌟 Why Gaussian-LIC?

- **Real-time performance**: Process datasets in minutes
- **Photo-realistic**: Better than traditional SLAM point clouds
- **Multi-sensor fusion**: LiDAR + IMU + Camera
- **State-of-the-art**: ICRA 2025 publication
- **Open source**: GPL-3 license

### Research Applications:
- Autonomous driving
- Robotics navigation
- 3D scene reconstruction
- AR/VR content creation
- Digital twins

---

## 📄 License

This Docker setup is provided under MIT License.

Original Gaussian-LIC is under [GNU GPL-3](https://www.gnu.org/licenses/gpl-3.0.txt).

---

## 🙏 Acknowledgments

- **Gaussian-LIC**: [APRIL-ZJU](https://github.com/APRIL-ZJU/Gaussian-LIC)
- **Authors**: Xiaolei Lang et al.
- **Paper**: [arXiv:2404.06926](https://arxiv.org/pdf/2404.06926)
- **Project Page**: [xingxingzuo.github.io/gaussian_lic](https://xingxingzuo.github.io/gaussian_lic/)

Based on:
- [3D Gaussian Splatting](https://github.com/graphdeco-inria/gaussian-splatting)
- [Taming-3DGS](https://github.com/humansensinglab/taming-3dgs)
- [Photo-SLAM](https://github.com/HuajianUP/Photo-SLAM)
- [Coco-LIC](https://github.com/APRIL-ZJU/Coco-LIC)

---

## 📞 Support

- **Gaussian-LIC Issues**: [GitHub Issues](https://github.com/APRIL-ZJU/Gaussian-LIC/issues)
- **RunPod Discord**: [discord.gg/cUpRmau42V](https://discord.gg/cUpRmau42V)
- **Email**: jerry_locker@zju.edu.cn

---

## 🚀 Get Started Now

```bash
# 1. Clone this repo
git clone <this-repo-url>
cd GaussianSplat-LIC2

# 2. Build and push Docker image
./build-and-push.sh YOUR_DOCKERHUB_USERNAME

# 3. Deploy on RunPod with RTX 5090
# Visit: https://www.runpod.io/console/pods

# 4. Start mapping!
```

**Total cost for first test**: ~$0.50 (build + process one dataset)

---

*Built with ❤️ for the SLAM community*  
*Optimized for RunPod RTX 5090 | November 2025*

