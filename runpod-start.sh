#!/bin/bash

# RunPod startup script for Gaussian-LIC
# This script can be used as a startup command in RunPod

set -e

echo "=========================================="
echo "  Gaussian-LIC RunPod Environment Setup  "
echo "=========================================="

# Source ROS environment
source /opt/ros/noetic/setup.bash
source /root/catkin_coco/devel/setup.bash
source /root/catkin_gaussian/devel/setup.bash

# Display environment info
echo ""
echo "Environment Information:"
echo "------------------------"
echo "ROS Version: $(rosversion -d)"
echo "CUDA Version: $(nvcc --version | grep release | awk '{print $6}')"
echo "GPU Info:"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

# Create necessary directories
mkdir -p /workspace/datasets
mkdir -p /workspace/results
mkdir -p /root/catkin_gaussian/src/Gaussian-LIC/result

# Link results to workspace for easy access
ln -sf /root/catkin_gaussian/src/Gaussian-LIC/result /workspace/results/gaussian-lic

echo ""
echo "Directories:"
echo "------------"
echo "Datasets: /workspace/datasets"
echo "Results: /workspace/results"
echo "Gaussian-LIC: /root/catkin_gaussian/src/Gaussian-LIC"
echo "Coco-LIC: /root/catkin_coco/src/Coco-LIC"

echo ""
echo "=========================================="
echo "  Ready to run Gaussian-LIC!              "
echo "=========================================="
echo ""
echo "Quick Start:"
echo "1. Upload your dataset to /workspace/datasets/"
echo "2. Edit config: nano /root/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml"
echo "3. Terminal 1: cd /root/catkin_gaussian && roslaunch gaussian_lic fastlivo.launch"
echo "4. Terminal 2: cd /root/catkin_coco && roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml"
echo ""

# Start a bash shell
exec /bin/bash

