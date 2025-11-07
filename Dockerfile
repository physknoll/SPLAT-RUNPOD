# Gaussian-LIC Docker Image for RunPod
# Based on Ubuntu 20.04 with CUDA 11.7
# MUST be built on x86_64 Linux with NVIDIA GPU or on RunPod

FROM --platform=linux/amd64 nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Set up timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    cmake \
    build-essential \
    pkg-config \
    software-properties-common \
    lsb-release \
    gnupg2 \
    ca-certificates \
    python3-pip \
    python3-dev \
    python3-numpy \
    libffi-dev \
    libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Install ROS Noetic
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y \
    ros-noetic-desktop-full \
    ros-noetic-cv-bridge \
    ros-noetic-image-transport \
    ros-noetic-pcl-conversions \
    ros-noetic-pcl-ros \
    ros-noetic-eigen-conversions \
    ros-noetic-tf \
    ros-noetic-tf-conversions \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-catkin-tools \
    libpcl-dev \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update

# Source ROS setup in bashrc
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc

# Install additional OpenCV dependencies and Ceres Solver
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    gfortran \
    ffmpeg \
    libceres-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    && rm -rf /var/lib/apt/lists/*

# Create software directory
RUN mkdir -p /root/Software

# Download OpenCV 4.7.0 (cached - won't re-download if this layer succeeds)
WORKDIR /root/Software/opencv
RUN echo "Downloading OpenCV 4.7.0..." && \
    wget -q https://github.com/opencv/opencv/archive/refs/tags/4.7.0.tar.gz && \
    echo "OpenCV downloaded successfully!"

# Extract OpenCV (separate layer)
RUN echo "Extracting OpenCV..." && \
    tar -zxf 4.7.0.tar.gz && \
    rm 4.7.0.tar.gz && \
    echo "OpenCV extracted!"

# Download OpenCV Contrib (cached - separate download)
RUN echo "Downloading OpenCV Contrib..." && \
    wget -q https://github.com/opencv/opencv_contrib/archive/refs/tags/4.7.0.tar.gz && \
    echo "OpenCV Contrib downloaded successfully!"

# Extract OpenCV Contrib (separate layer)
RUN echo "Extracting OpenCV Contrib..." && \
    tar -zxf 4.7.0.tar.gz && \
    rm 4.7.0.tar.gz && \
    echo "OpenCV Contrib extracted!"

# Configure OpenCV WITHOUT CUDA (will work on Mac for downloads/cache)
WORKDIR /root/Software/opencv/opencv-4.7.0/build
RUN cmake -DCMAKE_BUILD_TYPE=RELEASE \
    -DWITH_CUDA=OFF \
    -DWITH_CUDNN=OFF \
    -DOPENCV_DNN_CUDA=OFF \
    -DOPENCV_EXTRA_MODULES_PATH="/root/Software/opencv/opencv_contrib-4.7.0/modules" \
    -DBUILD_TIFF=ON \
    -DBUILD_ZLIB=ON \
    -DBUILD_JASPER=ON \
    -DBUILD_CCALIB=ON \
    -DBUILD_JPEG=ON \
    -DWITH_FFMPEG=ON \
    -DENABLE_FAST_MATH=ON \
    ..

# Build OpenCV (this will work on Mac without CUDA)
RUN make -j$(nproc)

# Download LibTorch 2.0.1 CPU version (cached - ~2GB download)
WORKDIR /root/Software
RUN echo "Downloading LibTorch (~2GB, may take a few minutes)..." && \
    wget --progress=bar:force:noscroll https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.0.1%2Bcpu.zip && \
    echo "LibTorch downloaded successfully!"

# Extract LibTorch (separate layer so download is cached)
RUN echo "Extracting LibTorch..." && \
    unzip -q libtorch-cxx11-abi-shared-with-deps-2.0.1+cpu.zip && \
    rm libtorch-cxx11-abi-shared-with-deps-2.0.1+cpu.zip && \
    echo "LibTorch extracted!"

# Create catkin workspaces
RUN mkdir -p /root/catkin_coco/src && \
    mkdir -p /root/catkin_gaussian/src

# Clone Livox ROS Driver (cached)
WORKDIR /root/catkin_coco/src
RUN echo "Cloning Livox ROS Driver..." && \
    git clone https://github.com/Livox-SDK/livox_ros_driver.git && \
    echo "Livox cloned!"

# Build Livox driver (separate layer)
WORKDIR /root/catkin_coco
RUN echo "Building Livox driver..." && \
    /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make" && \
    echo "Livox built!"

# Clone Coco-LIC (cached)
WORKDIR /root/catkin_coco/src
RUN echo "Cloning Coco-LIC..." && \
    git clone https://github.com/APRIL-ZJU/Coco-LIC.git && \
    echo "Coco-LIC cloned!"

# Patch Coco-LIC to work with PCL 1.10 (Ubuntu 20.04 has 1.10, not 1.13)
RUN sed -i 's/find_package(PCL 1.13.0 REQUIRED)/find_package(PCL 1.10.0 REQUIRED)/g' /root/catkin_coco/src/Coco-LIC/CMakeLists.txt

# Build Coco-LIC (separate layer)
WORKDIR /root/catkin_coco
RUN echo "Building Coco-LIC..." && \
    /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make" && \
    echo "Coco-LIC built!"

# Copy Gaussian-LIC source code
COPY Gaussian-LIC /root/catkin_gaussian/src/Gaussian-LIC

# Build Gaussian-LIC
WORKDIR /root/catkin_gaussian
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make"

# Set up environment
RUN echo "source /root/catkin_gaussian/devel/setup.bash" >> /root/.bashrc && \
    echo "source /root/catkin_coco/devel/setup.bash" >> /root/.bashrc

# Create results directory
RUN mkdir -p /root/catkin_gaussian/src/Gaussian-LIC/result

# Create workspace directory for datasets
RUN mkdir -p /workspace/datasets

# Set working directory
WORKDIR /workspace

# Expose ports for ROS and visualization
EXPOSE 11311 8888

# Create entrypoint script
RUN echo '#!/bin/bash\n\
source /opt/ros/noetic/setup.bash\n\
source /root/catkin_coco/devel/setup.bash\n\
source /root/catkin_gaussian/devel/setup.bash\n\
exec "$@"' > /entrypoint.sh && \
chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]

