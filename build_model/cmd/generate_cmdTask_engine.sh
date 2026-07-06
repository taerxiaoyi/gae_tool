#!/bin/bash
# =====================================================
# 🧠 TensorRT Engine Auto Generator
# 作用：在每个子文件夹下，若存在 .onnx 文件且没有 cmdTask.engine，
#       则自动调用 trtexec 生成对应的 cmdTask.engine。
# =====================================================

# 获取脚本启动时间
start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "🚀 [START] TensorRT Engine Auto Generation"
echo "🕐  Start Time: $start_time"
echo "📂  Working Directory: $(pwd)"
echo "-------------------------------------------"

# 遍历所有子目录
for d in */; do
    echo "📁 Checking folder: $d"

    # 查找 .onnx 文件
    onnx=$(find "$d" -maxdepth 1 -name "cmdTask.onnx" | head -n 1)
    eng="${d%/}/cmdTask.engine"

    # 若没有找到 .onnx
    if [ -z "$onnx" ]; then
        echo "⚠️  No ONNX file found in $d"
        echo "-------------------------------------------"
        continue
    fi

    # 若已有 cmdTask.engine，跳过
    if [ -f "$eng" ]; then
        echo "⏩ Engine already exists: $eng"
        echo "-------------------------------------------"
        continue
    fi

    # 显示详细构建信息
    echo "🧩 Building engine for:"
    echo "   🗂  ONNX Path: $onnx"
    echo "   💾 Output:    $eng"
    echo "   ⚙️  Command:    ~/libs/TensorRT-10.13.0.35/bin/trtexec --onnx=\"$onnx\" --saveEngine=\"$eng\" "
    echo "-------------------------------------------"

    # 执行构建
    ~/libs/TensorRT-10.13.0.35/bin/trtexec --onnx="$onnx" --saveEngine="$eng"
    # 检查结果
    if [ -f "$eng" ]; then
        echo "✅ [SUCCESS] Engine created: $eng"
    else
        echo "❌ [FAIL] Engine creation failed for $onnx"
    fi
    echo "-------------------------------------------"
done

# 脚本结束
end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "🎯 [DONE] All folders processed."
echo "🕒  End Time:   $end_time"
echo "📍 Log saved from $start_time → $end_time"
echo "====================================================="

