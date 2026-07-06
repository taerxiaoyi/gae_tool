#!/usr/bin/env bash

# 不要 silent exit
set -o pipefail

# 关键：确保 */ 能正确展开
shopt -s nullglob

ROOT_DIR="$(pwd)"

total_dirs=0
processed_dirs=0
skipped_dirs=0

echo "=============================================="
echo "[INFO] Actor → TeleopTask Rename Script"
echo "[INFO] Root directory: ${ROOT_DIR}"
echo "=============================================="

for dir in */; do
  dir="${dir%/}"
  ((total_dirs++))

  echo ""
  echo "[INFO] Checking directory: ${dir}"

  actor_json="$dir/actor.json"
  actor_yaml="$dir/actor.yaml"
  actor_onnx="$dir/actor.onnx"
  actor_pt="$dir/actor.pt"

  # 必须有 actor.onnx
  if [[ ! -f "$actor_onnx" ]]; then
    echo "[SKIP] No actor.onnx found"
    ((skipped_dirs++))
    continue
  fi

  echo "[INFO] Found actor.onnx"
  ((processed_dirs++))

  # json
  if [[ -f "$actor_json" ]]; then
    echo "[INFO] Rename: actor.json -> teleopTask.json"
    mv "$actor_json" "$dir/teleopTask.json"
  else
    echo "[WARN] actor.json not found"
  fi

  # yaml
  if [[ -f "$actor_yaml" ]]; then
    echo "[INFO] Rename: actor.yaml -> teleopTask.yaml"
    mv "$actor_yaml" "$dir/teleopTask.yaml"
  else
    echo "[WARN] actor.yaml not found"
  fi

  # pt
  if [[ -f "$actor_pt" ]]; then
    echo "[INFO] Rename: actor.pt -> teleopTask.pt"
    mv "$actor_pt" "$dir/teleopTask.pt"
  else
    echo "[WARN] actor.pt not found"
  fi

  # onnx（加目录名后缀）
  # new_onnx="$dir/teleopTask_${dir}.onnx"
  new_onnx="$dir/teleopTask.onnx"
  echo "[INFO] Rename: actor.onnx -> $(basename "$new_onnx")"
  mv "$actor_onnx" "$new_onnx"

  echo "[DONE] Directory '${dir}' processed."
done

echo ""
echo "=============================================="
echo "[SUMMARY]"
echo "  Total directories scanned : ${total_dirs}"
echo "  Directories processed     : ${processed_dirs}"
echo "  Directories skipped       : ${skipped_dirs}"
echo "=============================================="
echo "[INFO] Rename finished."
