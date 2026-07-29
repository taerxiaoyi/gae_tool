#!/bin/bash
# Time: 2025-11-14 v1.0.0
# ==========================================================
# 🔍 Jetson 软件环境检测脚本 (dpkg + fallback)
# 适用于 Jetson Orin / Xavier / Nano
# ==========================================================

echo "=================================================="
echo "🔍 Detecting Jetson Environment via dpkg"
echo "=================================================="

# ---------- 1. 检测硬件型号 ----------
if [ -f /proc/device-tree/model ]; then
    MODEL=$(tr -d '\0' </proc/device-tree/model)
else
    MODEL="Unknown"
fi
echo "🤖 Jetson Model: $MODEL"

# ---------- 2. 检测 Ubuntu 版本 ----------
UBUNTU_VER=$(lsb_release -rs 2>/dev/null | cut -d'.' -f1)
echo "🧩 Ubuntu Version: $UBUNTU_VER"

# ---------- 3. 检测 JetPack 版本 ----------
JP_VER=$(dpkg -l | grep nvidia-jetpack | awk '{print $3}' | head -n1)
if [ -n "$JP_VER" ]; then
    echo "🚀 JetPack Version: $JP_VER (from dpkg)"
else
    # fallback
    if [ -f /etc/nv_tegra_release ]; then
        JP_VER=$(grep -oP '(?<=R)[0-9]+\.[0-9]+' /etc/nv_tegra_release)
        echo "🚀 JetPack Version: $JP_VER (from /etc/nv_tegra_release)"
    else
        JP_VER="Unknown"
        echo "🚀 JetPack Version: not found"
    fi
fi

# ---------- 4. 检测 CUDA 版本 ----------
CUDA_VER=$(dpkg -l | grep "cuda-toolkit-" | awk '{print $2}' | sed 's/cuda-toolkit-//' | head -n1)
if [ -n "$CUDA_VER" ]; then
    echo "⚙️  CUDA Version: $CUDA_VER (from dpkg)"
else
    if command -v nvcc >/dev/null 2>&1; then
        CUDA_VER=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d',' -f1)
        echo "⚙️  CUDA Version: $CUDA_VER (from nvcc)"
    else
        CUDA_VER="Unknown"
        echo "⚙️  CUDA not found"
    fi
fi

# ---------- 5. 检测 cuDNN 版本 ----------
CUDNN_VER=$(dpkg -l | grep "libcudnn" | awk '{print $2, $3}' | head -n1)
if [ -n "$CUDNN_VER" ]; then
    echo "🧬 cuDNN Package: $CUDNN_VER"
else
    echo "🧬 cuDNN not found"
fi

# ---------- 6. 检测 TensorRT 版本 ----------
TRT_VER=$(dpkg -l | grep "libnvinfer" | awk '{print $3}' | head -n1)
if [ -n "$TRT_VER" ]; then
    echo "🧠 TensorRT Version: $TRT_VER (from dpkg)"
else
    # fallback: header check
    if [ -f /usr/include/NvInferVersion.h ]; then
        TRT_MAJOR=$(grep "#define NV_TENSORRT_MAJOR" /usr/include/NvInferVersion.h | awk '{print $3}')
        TRT_MINOR=$(grep "#define NV_TENSORRT_MINOR" /usr/include/NvInferVersion.h | awk '{print $3}')
        TRT_PATCH=$(grep "#define NV_TENSORRT_PATCH" /usr/include/NvInferVersion.h | awk '{print $3}')
        TRT_VER="${TRT_MAJOR}.${TRT_MINOR}.${TRT_PATCH}"
        echo "🧠 TensorRT Version: $TRT_VER (from header)"
    else
        TRT_VER="Unknown"
        echo "🧠 TensorRT not found"
    fi
fi

# ---------- 7. 汇总 ----------
echo "--------------------------------------------------"
echo "📋 Summary:"
echo "  Jetson Model: $MODEL"
echo "  Ubuntu:       $UBUNTU_VER"
echo "  JetPack:      $JP_VER"
echo "  CUDA:         $CUDA_VER"
echo "  TensorRT:     $TRT_VER"
echo "--------------------------------------------------"

# ---------- 8. 自动推断配置 ----------
CUDA_MAJOR=$(echo "$CUDA_VER" | grep -oE '^[0-9]+')
TRT_MAJOR=$(echo "$TRT_VER" | grep -oE '^[0-9]+')
TOOLCHAIN="cuda${CUDA_MAJOR}_trt${TRT_MAJOR}"

ARCH=$(uname -m)
SUFFIX="${ARCH}_ubuntu${UBUNTU_VER}_${TOOLCHAIN}"
echo "🧩 Recommended Build Suffix: ${SUFFIX}"
echo "=================================================="
