#!/bin/bash
# Verify RunPod Setup - Quick Check Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  RunPod Setup Verification"
echo -e "==========================================${NC}"
echo ""

# Ensure PATH includes ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Check 1: runpodctl installed
echo -n "1. Checking runpodctl installation... "
if command -v runpodctl &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}   runpodctl not found!${NC}"
    echo ""
    echo "   Install it with:"
    echo "   mkdir -p ~/.local/bin"
    echo "   curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz"
    echo "   tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl"
    echo "   chmod +x ~/.local/bin/runpodctl"
    exit 1
fi

# Check 2: runpodctl version
echo -n "2. Checking runpodctl version... "
VERSION=$(runpodctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
if [[ "$VERSION" == "unknown" ]]; then
    VERSION=$(runpodctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+' | head -1 || echo "1.0")
fi

if [[ "$VERSION" == "1.0" ]] || [[ "$VERSION" =~ 1\.0\.0 ]]; then
    echo -e "${RED}✗ ($VERSION)${NC}"
    echo -e "${RED}   You have version $VERSION - this is too old!${NC}"
    echo ""
    echo "   Update with:"
    echo "   mkdir -p ~/.local/bin"
    echo "   curl -L https://github.com/runpod/runpodctl/releases/download/v1.14.4/runpodctl_1.14.4_darwin_all.tar.gz -o /tmp/runpodctl.tar.gz"
    echo "   tar -xzf /tmp/runpodctl.tar.gz -C ~/.local/bin runpodctl"
    echo "   chmod +x ~/.local/bin/runpodctl"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    exit 1
elif [[ "$VERSION" =~ v?1\.1[4-9] ]]; then
    echo -e "${GREEN}✓ ($VERSION)${NC}"
else
    echo -e "${YELLOW}⚠ ($VERSION)${NC}"
    echo -e "${YELLOW}   Version $VERSION may work, but v1.14.4+ is recommended${NC}"
fi

# Check 3: RUNPOD_API_KEY
echo -n "3. Checking RUNPOD_API_KEY... "
if [ -z "$RUNPOD_API_KEY" ]; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}   RUNPOD_API_KEY not set!${NC}"
    echo ""
    echo "   Set it with:"
    echo "   export RUNPOD_API_KEY=\"rpk_your_key_here\""
    echo ""
    echo "   Get your API key at:"
    echo "   https://www.runpod.io/console/user/settings"
    exit 1
else
    # Mask the key for security
    MASKED_KEY="${RUNPOD_API_KEY:0:7}...${RUNPOD_API_KEY: -4}"
    echo -e "${GREEN}✓ ($MASKED_KEY)${NC}"
fi

# Check 4: runpodctl configuration
echo -n "4. Checking runpodctl configuration... "
runpodctl config --apiKey "$RUNPOD_API_KEY" > /dev/null 2>&1
if runpodctl get pod > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}   Failed to connect to RunPod API${NC}"
    echo "   Your API key may be invalid"
    exit 1
fi

# Check 5: Docker Hub credentials (optional)
echo -n "5. Checking DOCKER_HUB_PASSWORD... "
if [ -z "$DOCKER_HUB_PASSWORD" ]; then
    echo -e "${YELLOW}⚠ (not set)${NC}"
    echo -e "${YELLOW}   You'll need this for the build script${NC}"
    echo "   Set it with:"
    echo "   export DOCKER_HUB_PASSWORD=\"dckr_pat_your_token\""
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 6: Required files
echo -n "6. Checking required files... "
MISSING_FILES=()
if [ ! -f "Dockerfile" ] && [ ! -f "Dockerfile.fixed" ]; then
    MISSING_FILES+=("Dockerfile or Dockerfile.fixed")
fi
if [ ! -d "Gaussian-LIC" ]; then
    MISSING_FILES+=("Gaussian-LIC directory")
fi
if [ ! -f "build-remote.sh" ]; then
    MISSING_FILES+=("build-remote.sh")
fi

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}   Missing files: ${MISSING_FILES[*]}${NC}"
    exit 1
fi

# All checks passed
echo ""
echo -e "${GREEN}=========================================="
echo "  ✨ All checks passed!"
echo -e "==========================================${NC}"
echo ""
echo "You're ready to build! Run:"
echo ""
echo -e "  ${BLUE}./build-remote.sh YOUR_DOCKERHUB_USERNAME${NC}"
echo ""
echo "Estimated time: 35-45 minutes"
echo "Estimated cost: ~\$0.25-0.40"
echo ""

