# RunPod API Usage (Optional Advanced)

> **Note**: The basic workflow in `QUICKSTART.md` uses the web interface and doesn't require an API key.

This guide is for users who want to automate Pod management via API or CLI.

---

## 🔑 Get Your API Key

1. Go to https://www.runpod.io/console/user/settings
2. Click **"API Keys"** (left sidebar)
3. Click **"+ Create API Key"**
4. Name: "Gaussian-LIC Automation"
5. Permissions: "Read & Write" (for Pods)
6. Click **"Create"** and **copy the key immediately**

⚠️ **Important**: Save it securely - you can't view it again!

---

## 💾 Store API Key Securely

### Option 1: Environment Variable (Recommended)

```bash
# Add to ~/.zshrc (or ~/.bash_profile)
echo 'export RUNPOD_API_KEY="YOUR_API_KEY_HERE"' >> ~/.zshrc

# Reload
source ~/.zshrc

# Verify
echo $RUNPOD_API_KEY
```

### Option 2: Secure Config File

```bash
# Create config directory
mkdir -p ~/.runpod
chmod 700 ~/.runpod

# Store key
echo "YOUR_API_KEY_HERE" > ~/.runpod/api_key
chmod 600 ~/.runpod/api_key

# Use in scripts
export RUNPOD_API_KEY=$(cat ~/.runpod/api_key)
```

---

## 🛠️ Using runpodctl CLI

### Install

```bash
# macOS
brew install runpodctl

# Or download directly
wget https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-darwin-amd64
chmod +x runpodctl-darwin-amd64
sudo mv runpodctl-darwin-amd64 /usr/local/bin/runpodctl
```

### Configure

```bash
# Set API key
runpodctl config --apiKey "$RUNPOD_API_KEY"

# Verify
runpodctl get pod
```

### Common Commands

```bash
# List all Pods
runpodctl get pod

# Get specific Pod info
runpodctl get pod <pod-id>

# Create a Pod
runpodctl create pod \
  --name "gaussian-lic-test" \
  --imageName "yourusername/gaussian-lic:latest" \
  --gpuType "NVIDIA RTX 5090" \
  --containerDiskSize 50 \
  --volumeSize 100

# Stop a Pod
runpodctl stop pod <pod-id>

# Start a Pod
runpodctl start pod <pod-id>

# Terminate a Pod
runpodctl remove pod <pod-id>

# Send files to Pod
runpodctl send dataset.bag <pod-id>:/workspace/datasets/

# Receive files from Pod
runpodctl receive <pod-id>:/root/catkin_gaussian/src/Gaussian-LIC/result ./results/

# SSH into Pod
runpodctl ssh <pod-id>
```

---

## 🐍 Using Python SDK

### Install

```bash
pip install runpod
```

### Basic Usage

```python
import runpod

# Set API key
runpod.api_key = "YOUR_API_KEY_HERE"

# List available GPUs
gpus = runpod.get_gpus()
print(gpus)

# Create a Pod
pod = runpod.create_pod(
    name="gaussian-lic-auto",
    image_name="yourusername/gaussian-lic:latest",
    gpu_type_id="NVIDIA RTX 5090",
    cloud_type="COMMUNITY",  # or "SECURE"
    container_disk_in_gb=50,
    volume_in_gb=100,
    ports="8888/http,11311/tcp",
    env={
        "ROS_MASTER_URI": "http://localhost:11311"
    }
)

print(f"Pod created: {pod['id']}")
print(f"Connection info: {pod}")

# Get Pod status
status = runpod.get_pod(pod['id'])
print(f"Status: {status['desiredStatus']}")

# Stop Pod
runpod.stop_pod(pod['id'])

# Terminate Pod
runpod.terminate_pod(pod['id'])
```

---

## 🤖 Automated Deployment Script

Create a script to automate the entire process:

```bash
#!/bin/bash
# deploy-gaussian-lic.sh

set -e

# Configuration
RUNPOD_API_KEY="${RUNPOD_API_KEY}"
DOCKER_IMAGE="yourusername/gaussian-lic:latest"
POD_NAME="gaussian-lic-$(date +%Y%m%d-%H%M%S)"
DATASET_PATH="$1"

if [ -z "$RUNPOD_API_KEY" ]; then
    echo "Error: RUNPOD_API_KEY not set"
    exit 1
fi

if [ -z "$DATASET_PATH" ]; then
    echo "Usage: $0 <path-to-dataset.bag>"
    exit 1
fi

echo "🚀 Deploying Gaussian-LIC Pod..."

# Create Pod
POD_ID=$(runpodctl create pod \
    --name "$POD_NAME" \
    --imageName "$DOCKER_IMAGE" \
    --gpuType "NVIDIA RTX 5090" \
    --containerDiskSize 50 \
    --volumeSize 100 \
    --output json | jq -r '.id')

echo "✅ Pod created: $POD_ID"
echo "⏳ Waiting for Pod to be ready..."

# Wait for Pod to be running
while true; do
    STATUS=$(runpodctl get pod "$POD_ID" --output json | jq -r '.desiredStatus')
    if [ "$STATUS" = "RUNNING" ]; then
        break
    fi
    sleep 5
done

echo "✅ Pod is running"
echo "📤 Uploading dataset..."

# Upload dataset
runpodctl send "$DATASET_PATH" "$POD_ID:/workspace/datasets/"

echo "✅ Dataset uploaded"
echo "🎯 Pod ready at: $POD_ID"
echo ""
echo "Next steps:"
echo "1. SSH: runpodctl ssh $POD_ID"
echo "2. Or Web Terminal: https://www.runpod.io/console/pods"
echo ""
echo "To download results:"
echo "runpodctl receive $POD_ID:/root/catkin_gaussian/src/Gaussian-LIC/result ./results"
echo ""
echo "To clean up:"
echo "runpodctl remove pod $POD_ID"
```

**Usage:**
```bash
chmod +x deploy-gaussian-lic.sh
./deploy-gaussian-lic.sh path/to/dataset.bag
```

---

## 🔄 REST API Usage

### Using cURL

```bash
# List Pods
curl -X GET "https://rest.runpod.io/v1/pods" \
  -H "Authorization: Bearer $RUNPOD_API_KEY"

# Create Pod
curl -X POST "https://rest.runpod.io/v1/pods" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gaussian-lic",
    "imageName": "yourusername/gaussian-lic:latest",
    "gpuTypeId": "NVIDIA RTX 5090",
    "cloudType": "COMMUNITY",
    "containerDiskInGb": 50,
    "volumeInGb": 100
  }'

# Stop Pod
curl -X POST "https://rest.runpod.io/v1/pods/<pod-id>/stop" \
  -H "Authorization: Bearer $RUNPOD_API_KEY"

# Terminate Pod
curl -X DELETE "https://rest.runpod.io/v1/pods/<pod-id>" \
  -H "Authorization: Bearer $RUNPOD_API_KEY"
```

---

## 🔐 Security Best Practices

### ✅ DO:
- Store API keys in environment variables or secure config files
- Use file permissions (chmod 600) for key files
- Rotate keys periodically
- Use separate keys for different projects
- Revoke unused keys

### ❌ DON'T:
- Commit API keys to Git
- Share keys in public forums
- Use the same key across multiple machines
- Store keys in plain text files with broad permissions

### Git Protection

```bash
# Add to .gitignore
echo ".runpod/" >> .gitignore
echo "*.key" >> .gitignore
echo ".env" >> .gitignore
```

---

## 🎯 When to Use API vs Web Interface

### Use Web Interface When:
- Learning and experimenting
- One-off deployments
- Visual monitoring preferred
- Quick manual adjustments

### Use API/CLI When:
- Automating workflows
- CI/CD pipelines
- Batch processing multiple datasets
- Programmatic Pod management
- Integration with other tools

---

## 📚 Additional Resources

- **RunPod API Docs**: https://docs.runpod.io/api-reference
- **runpodctl GitHub**: https://github.com/runpod/runpodctl
- **Python SDK**: https://github.com/runpod/runpod-python
- **API Reference**: https://rest.runpod.io/v1/openapi.json

---

## 🆘 Troubleshooting

### "Unauthorized" error
```bash
# Check if key is set
echo $RUNPOD_API_KEY

# Reconfigure runpodctl
runpodctl config --apiKey "$RUNPOD_API_KEY"
```

### "Invalid API key" error
- Key might be expired or revoked
- Generate a new key at https://www.runpod.io/console/user/settings
- Make sure no extra whitespace in key

### Permission errors
```bash
# Check key permissions
curl -X GET "https://rest.runpod.io/v1/user" \
  -H "Authorization: Bearer $RUNPOD_API_KEY"
```

---

**Remember**: Most users should start with the web interface (`QUICKSTART.md`). Use the API only when you need automation!

