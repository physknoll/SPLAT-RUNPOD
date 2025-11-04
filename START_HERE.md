# 🚀 START HERE - Gaussian-LIC on RunPod

## Welcome!

You're about to run **Gaussian-LIC** (ICRA 2025) - a state-of-the-art photo-realistic SLAM system - on RunPod's cloud GPUs.

This project makes it possible to run Gaussian-LIC on your MacBook Pro by leveraging cloud GPUs (since macOS doesn't support CUDA).

---

## ⚡ Quick Decision Tree

### I want to build from my Mac terminal (API - RECOMMENDED)
→ Go to **[QUICK_API_SETUP.md](./QUICK_API_SETUP.md)** ⭐

### I want to get running FAST (after building)
→ Go to **[QUICKSTART.md](./QUICKSTART.md)**

### I want to understand the RTX 5090 setup
→ Go to **[DEPLOY_RTX5090.md](./DEPLOY_RTX5090.md)**

### I need command references
→ Go to **[CHEATSHEET.md](./CHEATSHEET.md)**

### I want complete RunPod documentation
→ Go to **[README_RUNPOD.md](./README_RUNPOD.md)**

### I want to understand the entire project
→ Go to **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)**

### I want to automate with the RunPod API/CLI
→ Go to **[RUNPOD_API.md](./RUNPOD_API.md)** (optional, advanced)

---

## 📚 Documentation Map

```
START_HERE.md (you are here)
    │
    ├─→ QUICKSTART.md ⭐ START WITH THIS
    │   └─→ Get running in 10 minutes
    │
    ├─→ DEPLOY_RTX5090.md
    │   └─→ RTX 5090 specific guide
    │       └─→ Step-by-step deployment
    │           └─→ Optimization tips
    │
    ├─→ CHEATSHEET.md
    │   └─→ Quick command reference
    │       └─→ Copy-paste ready
    │
    ├─→ README_RUNPOD.md
    │   └─→ Comprehensive RunPod guide
    │       └─→ Troubleshooting
    │           └─→ Cost optimization
    │
    ├─→ PROJECT_SUMMARY.md
    │   └─→ Technical specifications
    │       └─→ Performance metrics
    │           └─→ Architecture details
    │
    └─→ README.md
        └─→ Main project overview
```

---

## 🎯 Your Mission

**Goal**: Run Gaussian-LIC on a dataset and get photo-realistic 3D reconstruction

**Time**: ~45 minutes (including Docker build)  
**Cost**: ~$0.50-1.00 for first test  
**Result**: Beautiful 3D Gaussian Splatting maps

---

## ⚠️ IMPORTANT: Cannot Build on Mac!

**Your MacBook Pro cannot build this Docker image** because:
- ❌ No NVIDIA GPU (CUDA requires NVIDIA hardware)
- ❌ Wrong architecture (needs x86_64 with CUDA support)

**✅ Solution**: Build the image **on RunPod** (takes 30-40 min, costs $0.25-0.40)

See **[BUILD_ON_RUNPOD.md](./BUILD_ON_RUNPOD.md)** for complete instructions.

## ✅ Prerequisites Checklist

Before you start, make sure you have:

- [ ] **Docker Hub account** (for storing your image)
  - Sign up: https://hub.docker.com/signup
  - Create access token for CLI

- [ ] **RunPod account**
  - Sign up: https://www.runpod.io/console/signup
  - Add payment method
  - Load $10+ credits (recommended)

- [ ] **Dataset ready** (.bag file)
  - FAST-LIVO: https://connecthkuhk-my.sharepoint.com/:f:/g/personal/zhengcr_connect_hku_hk/EhxC2fDOlwdJiYnLQiuC3HoBZCGXhSHDRCRtCDzGTfSQAQ?e=P6N4nW
  - R3LIVE: https://github.com/ziv-lin/r3live_dataset
  - MCD: https://mcdviral.github.io/

- [ ] **SSH key** (optional but recommended)
  - Generate: `ssh-keygen -t ed25519`
  - Add to RunPod: Settings → SSH Public Keys

---

## 🚦 Three-Step Process

### Step 1: Build Docker Image (35-40 min)
```bash
cd /Users/harrisonknoll/GaussianSplat-LIC2
./build-and-push.sh YOUR_DOCKERHUB_USERNAME
```

**What happens**:
- Builds Ubuntu 20.04 + CUDA 11.7 + ROS Noetic
- Compiles OpenCV with CUDA support
- Installs Coco-LIC and Gaussian-LIC
- Pushes to Docker Hub

**Cost**: Build on RunPod = ~$0.40 (35 min × $0.69/hr)

### Step 2: Deploy on RunPod (2-3 min)
1. Go to https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. Select **RTX 5090** (32GB, $0.69/hr)
4. Container Image: `YOUR_DOCKERHUB_USERNAME/gaussian-lic:latest`
5. Container Disk: 50GB
6. Click **Deploy On-Demand**

**Cost**: Deployment is instant, you pay per second of usage

### Step 3: Run Gaussian-LIC (8-10 min)
```bash
# Terminal 1: Launch Gaussian-LIC
cd /root/catkin_gaussian && source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch

# Terminal 2: Launch Coco-LIC
cd /root/catkin_coco && source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

**Cost**: Processing = ~$0.09 (8 min × $0.69/hr)

---

## 💰 Cost Breakdown

| Item | Time | Cost |
|------|------|------|
| Build Docker | 35 min | $0.40 |
| Process HKU2 dataset | 8 min | $0.09 |
| Storage (per day) | - | $0.17 |
| **TOTAL (first day)** | **~45 min** | **~$0.66** |

**Monthly usage (10 datasets/week)**: ~$15-20

---

## 🎓 Learning Path

### Beginner (Just want it to work)
1. Read `QUICKSTART.md`
2. Follow steps exactly
3. Use `CHEATSHEET.md` for commands

**Time**: 1 hour to first result

### Intermediate (Want to understand)
1. Read `README.md` for overview
2. Read `DEPLOY_RTX5090.md` for details
3. Experiment with config parameters
4. Try multiple datasets

**Time**: 2-3 hours to mastery

### Advanced (Customize and optimize)
1. Read `PROJECT_SUMMARY.md` for architecture
2. Read `README_RUNPOD.md` for all options
3. Modify Dockerfile for custom needs
4. Set up batch processing
5. Optimize for your specific use case

**Time**: 1-2 days for full customization

---

## 🆘 Common Issues

### "Docker build is taking forever"
✅ **Normal**: 30-60 minutes is expected  
💡 **Tip**: Build on RunPod, not your Mac (faster GPUs)

### "Can't find RTX 5090 on RunPod"
✅ **Try**: Community Cloud instead of Secure Cloud  
💡 **Alternative**: Use RTX 4090 or L40S

### "CUDA out of memory"
✅ **Rare** with 32GB RTX 5090  
💡 **Fix**: Reduce batch_size in config files

### "ROS connection failed"
✅ **Fix**: `export ROS_MASTER_URI=http://localhost:11311`  
💡 **Prevention**: Use provided startup scripts

**More help**: See troubleshooting in `DEPLOY_RTX5090.md`

---

## 🎯 What You'll Get

### Outputs
- **3D Gaussian maps** (.ply files)
- **Camera trajectories** (with poses)
- **Point clouds** (colored)
- **Rendering results** (images/video)

### Saved to
- `/root/catkin_gaussian/src/Gaussian-LIC/result/`

### Download with
```bash
scp -P <port> -r root@<pod-ip>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results
```

---

## 🌟 Why This Setup is Great

✅ **No local GPU needed** - Your MacBook Pro can't run CUDA  
✅ **Cost-effective** - Pay only when processing ($0.09/dataset)  
✅ **Scalable** - Process 100s of datasets in parallel  
✅ **Latest hardware** - RTX 5090 with 32GB VRAM  
✅ **Complete environment** - Everything pre-configured  
✅ **Open source** - Modify and customize freely

---

## 🎬 Ready to Start?

### Fastest Path (Recommended)
```bash
# 1. Build (from this directory)
./build-and-push.sh YOUR_DOCKERHUB_USERNAME

# 2. Deploy on RunPod
# https://www.runpod.io/console/pods
# Select RTX 5090 + your Docker image

# 3. Run (inside Pod)
# See QUICKSTART.md for exact commands
```

### Need Help?
- **Quick questions**: Check `CHEATSHEET.md`
- **Deployment issues**: Read `DEPLOY_RTX5090.md`
- **RunPod questions**: `README_RUNPOD.md`
- **Stuck?**: RunPod Discord or GitHub issues

---

## 📞 Support

- **Gaussian-LIC Issues**: https://github.com/APRIL-ZJU/Gaussian-LIC/issues
- **RunPod Discord**: https://discord.gg/cUpRmau42V
- **Email Author**: jerry_locker@zju.edu.cn

---

## 🎉 You're All Set!

Everything you need is in this repository. Start with `QUICKSTART.md` and you'll be processing datasets in under an hour.

**Total cost for your first test**: ~$0.50-1.00  
**Time to first result**: ~45 minutes  
**Satisfaction**: Priceless 😊

---

**→ Next Step: Open [QUICKSTART.md](./QUICKSTART.md)**

---

*Happy mapping! 🗺️✨*  
*Built with ❤️ for the SLAM community*

