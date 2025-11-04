# GitHub Actions Setup - The Better Solution

## Why GitHub Actions Instead of RunPod for Building?

After discovering that RunPod's CLI doesn't support arbitrary shell commands or reliable file transfers, **GitHub Actions is the superior solution** for building Docker images:

✅ **Free** (for public repos, 2,000 minutes/month for private)  
✅ **Has CUDA support** (can build CUDA images)  
✅ **Fully automated** (trigger on push or manually)  
✅ **Built-in caching** (faster subsequent builds)  
✅ **No RunPod complexity** (no SSH, SCP, or file transfer issues)  
✅ **Integrated with your workflow** (Git → Build → Docker Hub → RunPod)  

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Add Docker Hub Secrets to GitHub

1. Go to your GitHub repo: https://github.com/YOUR_USERNAME/GaussianSplat-LIC2
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

**Secret 1:**
- Name: `DOCKER_USERNAME`
- Value: `your-dockerhub-username`

**Secret 2:**
- Name: `DOCKER_TOKEN`
- Value: `dckr_pat_your_docker_hub_token`

(Get Docker Hub token at: https://hub.docker.com/settings/security)

---

### Step 2: Push the Workflow File to GitHub

The workflow file has been created at `.github/workflows/build-docker-image.yml`

```bash
# Push to GitHub
cd /Users/harrisonknoll/GaussianSplat-LIC2
git add .github/workflows/build-docker-image.yml
git commit -m "Add GitHub Actions workflow for Docker builds"
git push origin main
```

---

### Step 3: Trigger the Build

**Option A: Automatic (on push)**
```bash
# Any push to main with changes to Dockerfile or Gaussian-LIC/ triggers build
git push origin main
```

**Option B: Manual (on-demand)**
1. Go to: https://github.com/YOUR_USERNAME/GaussianSplat-LIC2/actions
2. Click **Build Gaussian-LIC Docker Image**
3. Click **Run workflow**
4. Optionally specify a tag (default: `latest`)
5. Click **Run workflow**

---

## 📊 What Happens During Build

1. **Checkout code** from GitHub
2. **Set up Docker Buildx** (advanced Docker builder)
3. **Login to Docker Hub** (using your secrets)
4. **Build the image** (takes 30-40 minutes)
   - Automatically caches layers for faster subsequent builds
   - Uses GitHub's powerful build machines
5. **Push to Docker Hub** (your image: `your-username/gaussian-lic:latest`)
6. **Summary** shows success and next steps

---

## 💰 Cost Comparison

| Method | Build Time | Cost | Complexity |
|--------|------------|------|------------|
| **GitHub Actions** | 35-45 min | **$0.00** (public repo) | ⭐ Low |
| RunPod RTX 3090 | 35-45 min | ~$0.25 | ⭐⭐⭐ High |
| RunPod RTX 5090 | 30-35 min | ~$0.35 | ⭐⭐⭐ High |

**Winner: GitHub Actions** - Free, easier, and just as fast!

---

## 🎯 Complete Workflow

### Build Image (GitHub Actions)
```bash
# 1. Make changes to code
vim Gaussian-LIC/src/gaussian.cpp

# 2. Commit and push
git add .
git commit -m "Update gaussian rendering"
git push origin main

# 3. GitHub automatically builds and pushes to Docker Hub
# Watch progress at: https://github.com/YOUR_USERNAME/repo/actions
```

### Deploy on RunPod (Manual)
1. Go to: https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. **Custom Template** → **Use Custom Image**
4. Image: `your-dockerhub-username/gaussian-lic:latest`
5. Select GPU (RTX 5090 recommended)
6. Click **Deploy**
7. Your pod starts with the image ready to use!

---

## 🔧 Advanced Usage

### Build Multiple Tags

```bash
# Trigger manual build with specific tag
# In GitHub Actions UI:
# - Run workflow
# - docker_tag: v1.0.0
```

This creates: `your-username/gaussian-lic:v1.0.0`

### Build on Pull Request (Optional)

Add to `.github/workflows/build-docker-image.yml`:
```yaml
on:
  pull_request:
    branches: [main]
```

### Speed Up Builds with Layer Caching

Already enabled! GitHub Actions automatically caches Docker layers:
- First build: ~40 minutes
- Subsequent builds with no Dockerfile changes: ~5 minutes
- Subsequent builds with minor changes: ~10-15 minutes

---

## 🆘 Troubleshooting

### "Secret not found" Error

Make sure you added `DOCKER_USERNAME` and `DOCKER_TOKEN` to GitHub secrets (Step 1).

### Build Fails on OpenCV

The Dockerfile disables CUDA for OpenCV to work on non-NVIDIA builders. If you need CUDA OpenCV, modify the Dockerfile:

```dockerfile
# Change from:
-DWITH_CUDA=OFF

# To:
-DWITH_CUDA=ON
```

But this may require self-hosted runners with NVIDIA GPUs.

### Build Times Out

GitHub Actions has a 6-hour timeout. If your build exceeds this:
1. Optimize Dockerfile layers
2. Use multi-stage builds
3. Pre-build base images

### Want to Build Locally for Testing?

```bash
# Test build locally (without pushing)
docker build -t test-gaussian-lic .

# If it works, push to trigger GitHub Actions
git push origin main
```

---

## 📚 Alternative: Use RunPod with Git Clone

If you prefer using RunPod (e.g., for private repos not on GitHub):

1. Push code to Git (GitHub/GitLab/Bitbucket)
2. Create RunPod pod
3. In web terminal:
```bash
git clone https://github.com/your-username/GaussianSplat-LIC2
cd GaussianSplat-LIC2
docker build -t your-username/gaussian-lic:latest .
docker login
docker push your-username/gaussian-lic:latest
```

But GitHub Actions is still easier!

---

## ✨ Benefits of This Approach

1. **No Mac limitations** - GitHub's Linux runners have everything
2. **No RunPod file transfer issues** - Code comes from Git
3. **Free** - No build costs
4. **Automated** - Push and forget
5. **Versioned** - Git tags = Docker tags
6. **Fast iteration** - Layer caching speeds up rebuilds
7. **CI/CD ready** - Can add tests, linting, etc.

---

## 🎯 Recommended Next Steps

1. ✅ Add GitHub secrets (Step 1)
2. ✅ Push workflow file to GitHub (Step 2)
3. ✅ Trigger first build (Step 3)
4. ✅ Wait 35-45 minutes
5. ✅ Deploy pod on RunPod with your image
6. ✅ Profit! 🚀

---

**This is how professional teams do CUDA Docker builds.** GitHub Actions + Docker Hub + RunPod is the standard workflow.

Your `build-remote.sh` script **cannot work** due to RunPod CLI limitations. This is the proper solution.

