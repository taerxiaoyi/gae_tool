#!/bin/bash

set -u
set -o pipefail

##############################################################################
# 公共配置
##############################################################################

SRC_DIR="policy_deploy"

REMOTE_PACKAGE_ROOT = "~/code/mc"

PACKAGE_ROOT="$HOME/Mc/robot_file/GAE_release/webctrl_packages"
PACKAGE_VERSION="v1.2.0"

DATE_TIME=$(date +"%Y%m%d%H%M%S")
DATE_DAY=$(date +"%Y%m%d")

##############################################################################
# 设备配置
#
# 以后新增设备时，只需要在这里增加一行 add_device。
#
# 参数顺序：
# add_device 编号 设备环境 IP 远端用户 密码 输出目录 机器人类型
##############################################################################

declare -a DEVICE_IDS=()
declare -A DEVICE_DESC_MAP=()
declare -A IP_MAP=()
declare -A REMOTE_USER_MAP=()
declare -A REMOTE_PASS_MAP=()
declare -A TARGET_FOLDER_MAP=()
declare -A ROBOT_TYPE_MAP=()

add_device()
{
    local device_id="$1"
    local device_desc="$2"
    local ip="$3"
    local remote_user="$4"
    local remote_pass="$5"
    local target_folder="$6"
    local robot_type="$7"

    # 防止编号重复。
    if [[ -n "${IP_MAP[$device_id]+x}" ]]; then
        echo "错误：设备编号重复：${device_id}" >&2
        exit 1
    fi

    DEVICE_IDS+=("$device_id")
    DEVICE_DESC_MAP["$device_id"]="$device_desc"
    IP_MAP["$device_id"]="$ip"
    REMOTE_USER_MAP["$device_id"]="$remote_user"
    REMOTE_PASS_MAP["$device_id"]="$remote_pass"
    TARGET_FOLDER_MAP["$device_id"]="$target_folder"
    ROBOT_TYPE_MAP["$device_id"]="$robot_type"
}

# 在下面添加或修改设备。
add_device "1" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "123" \
    "g1_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}" "unitree_g1"

add_device "2" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "123" \
    "o1_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}" "wlrobot_o1"

add_device "3" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "123" \
    "pm01_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}" "engine_pm01"

add_device "4" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "123" \
    "k2_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}" "kepler_k2"

add_device "5" "Ubuntu22 CUDA12 TRT8" "192.168.2.90" "wlrobot" "123" \
    "g1_webctrl_aarch64_ubuntu22_cuda12_trt8_${PACKAGE_VERSION}" "unitree_g1"

add_device "6" "Ubuntu20 CUDA11 TRT8" "192.168.3.77" "wlrobot" "123" \
    "g1_webctrl_aarch64_ubuntu20_cuda11_trt8_${PACKAGE_VERSION}" "unitree_g1"

add_device "7" "Ubuntu22 CUDA12 TRT10" "192.168.1.209" "mc" "3" \
    "g1_webctrl_amd86_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}" "unitree_g1"

##############################################################################
# 使用说明
##############################################################################

show_devices()
{
    local device_id

    echo "已添加的设备信息："
    printf "  %-6s %-27s %-15s %-14s %s\\n" \
        "编号" "设备环境" "IP" "远端用户" "机器人类型"

    for device_id in "${DEVICE_IDS[@]}"; do
        printf "  %-4s %-23s %-15s %-10s %s\\n" \
            "$device_id" \
            "${DEVICE_DESC_MAP[$device_id]}" \
            "${IP_MAP[$device_id]}" \
            "${REMOTE_USER_MAP[$device_id]}" \
            "${ROBOT_TYPE_MAP[$device_id]}"
    done
}

show_usage()
{
    echo "用法：$0 <设备编号>"
    echo ""
    show_devices
    echo ""
    echo "示例："
    echo "  $0 1"
}

# 未传设备编号时，从上面的设备配置自动生成列表。
if [ "$#" -eq 0 ]; then
    show_devices
    echo ""
    echo "请选择设备编号后执行，例如："
    echo "  $0 1"
    exit 0
fi

if [ "$#" -ne 1 ]; then
    echo "错误：只允许传入一个设备编号。"
    echo ""
    show_usage
    exit 1
fi

##############################################################################
# 根据编号选择一台设备
##############################################################################

DEVICE_ID="$1"

case "$DEVICE_ID" in
    -h|--help)
        show_usage
        exit 0
        ;;
esac

if [[ -z "${IP_MAP[$DEVICE_ID]+x}" ]]; then
    echo "错误：未知设备编号：${DEVICE_ID}"
    echo ""
    show_usage
    exit 1
fi

DEVICE_DESC="${DEVICE_DESC_MAP[$DEVICE_ID]}"
IP="${IP_MAP[$DEVICE_ID]}"
REMOTE_USER="${REMOTE_USER_MAP[$DEVICE_ID]}"
REMOTE_PASS="${REMOTE_PASS_MAP[$DEVICE_ID]}"
TARGET_FOLDER="${TARGET_FOLDER_MAP[$DEVICE_ID]}"
ROBOT_TYPE="${ROBOT_TYPE_MAP[$DEVICE_ID]}"
REMOTE_NAME="policy_deploy_pack_${ROBOT_TYPE}_${DATE_TIME}"

# 防止忘记替换示例 IP。
if [[ "$IP" == *"xxx"* ]]; then
    echo "错误：设备 ${DEVICE_ID} 的 IP 仍是占位地址：${IP}"
    echo "请先在脚本设备配置中填写真实 IP。"
    exit 1
fi

##############################################################################
# 根据机器人类型设置 runtime.conf 中的 TASK
##############################################################################

case "$ROBOT_TYPE" in
    unitree_g1)
        TASK_NAME="g1_stable_mocap"
        RESOURCE_PACK_NAME="unitree_g1"
        ;;
    wlrobot_o1)
        TASK_NAME="o1_eman"
        RESOURCE_PACK_NAME="wlrobot_o1"
        ;;
    engine_pm01)
        TASK_NAME="pm01"
        RESOURCE_PACK_NAME="engine_pm01"
        ;;
    kepler_k2)
        TASK_NAME="k2"
        RESOURCE_PACK_NAME="kepler_k2"
        ;;
    *)
        echo "错误：不支持的机器人类型：${ROBOT_TYPE}"
        echo "支持的类型：unitree_g1、wlrobot_o1、engine_pm01、kepler_k2"
        exit 1
        ;;
esac

REMOTE_RESOURCE_DIR="${REMOTE_PACKAGE_ROOT}/resources_pack/${RESOURCE_PACK_NAME}/resources"

RELEASE_DIR="${PACKAGE_ROOT}/encry_without_shell_${PACKAGE_VERSION}_${DATE_DAY}"
OUTPUT_DIR="${RELEASE_DIR}/${TARGET_FOLDER}"
REMOTE_RUNTIME_CONF="${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}/setup/etc/runtime.conf"

##############################################################################
# 基础检查
##############################################################################

for command_name in sshpass scp ssh expect; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "错误：未找到命令 ${command_name}"
        exit 1
    fi
done

if [ ! -d "$SRC_DIR" ]; then
    echo "错误：源码目录不存在：${SRC_DIR}"
    exit 1
fi


mkdir -p "$OUTPUT_DIR"

##############################################################################
# 打印本次选择
##############################################################################

echo ""
echo "===================================================="
echo "BUILD CONFIG"
echo "===================================================="
echo "设备编号   : ${DEVICE_ID}"
echo "设备环境   : ${DEVICE_DESC}"
echo "设备地址   : ${IP}"
echo "远端用户   : ${REMOTE_USER}"
echo "机器人类型 : ${ROBOT_TYPE}"
echo "TASK       : ${TASK_NAME}"
echo "远程文件名 : ${REMOTE_NAME}"
echo "资源目录   : ${REMOTE_RESOURCE_DIR}"
echo "远端配置   : ${REMOTE_RUNTIME_CONF}"
echo "输出目录   : ${OUTPUT_DIR}"
echo "===================================================="

##############################################################################
# 本地源码保持不变
##############################################################################

echo ""
echo "[LOCAL] 不修改本地源码目录：${SRC_DIR}"
echo "[LOCAL] 目录清理和 TASK 修改将在上传完成后于远端执行"

##############################################################################
# 远端临时目录清理
##############################################################################

REMOTE_UPLOADED=0

cleanup_remote()
{
    if [ "$REMOTE_UPLOADED" -ne 1 ]; then
        return 0
    fi

    echo ""
    echo "[${IP}] 删除远端临时目录：${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}"

    if sshpass -p "$REMOTE_PASS" \
        ssh \
        -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${IP}" \
        "rm -rf ${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}"; then
        REMOTE_UPLOADED=0
        echo "[${IP}] 远端临时目录已删除"
        return 0
    fi

    echo "[${IP}] 警告：远端临时目录删除失败，请手动删除：${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}" >&2
    return 1
}

# 编译或下载中途失败时，也尽量删除已经上传的远端临时目录。
trap 'cleanup_remote || true' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

##############################################################################
# 上传
##############################################################################

echo ""
echo "[${IP}] 准备远端目录..."

if ! sshpass -p "$REMOTE_PASS" \
    ssh \
    -o StrictHostKeyChecking=no \
    "${REMOTE_USER}@${IP}" \
    "mkdir -p ${REMOTE_PACKAGE_ROOT} && rm -rf ${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}"; then
    echo "[${IP}] 远端目录准备失败"
    exit 1
fi

echo "[${IP}] 上传工程..."

REMOTE_UPLOADED=1

if ! sshpass -p "$REMOTE_PASS" \
    scp -r \
    -o StrictHostKeyChecking=no \
    "$SRC_DIR" \
    "${REMOTE_USER}@${IP}:${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}"; then
    echo "[${IP}] 上传失败"
    exit 1
fi

##############################################################################
# 上传完成后整理远端工程
##############################################################################

echo "[${IP}] 清理远端工程并设置 TASK=${TASK_NAME}..."

if ! sshpass -p "$REMOTE_PASS" \
    ssh \
    -o StrictHostKeyChecking=no \
    "${REMOTE_USER}@${IP}" \
    "REMOTE_DIR=${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}; \
     RUNTIME_CONF=\"\${REMOTE_DIR}/setup/etc/runtime.conf\"; \
     if [ ! -d \"\${REMOTE_DIR}\" ]; then \
         echo \"错误：远端工程目录不存在：\${REMOTE_DIR}\"; exit 1; \
     fi; \
     for dir_name in build install resources log packages; do \
         dir_path=\"\${REMOTE_DIR}/\${dir_name}\"; \
         if [ -e \"\${dir_path}\" ] || [ -L \"\${dir_path}\" ]; then \
             echo \"[REMOTE] 删除：\${dir_path}\"; \
             rm -rf -- \"\${dir_path}\" || exit 1; \
         else \
             echo \"[REMOTE] 不存在，跳过：\${dir_path}\"; \
         fi; \
     done; \
     if [ ! -f \"\${RUNTIME_CONF}\" ]; then \
         echo \"错误：远端配置文件不存在：\${RUNTIME_CONF}\"; exit 1; \
     fi; \
     if grep -qE '^[[:space:]]*TASK=' \"\${RUNTIME_CONF}\"; then \
         sed -i -E 's|^[[:space:]]*TASK=.*$|TASK=${TASK_NAME}|' \"\${RUNTIME_CONF}\" || exit 1; \
     else \
         printf '\\nTASK=%s\\n' '${TASK_NAME}' >> \"\${RUNTIME_CONF}\" || exit 1; \
     fi; \
     echo '[REMOTE] 当前配置：'; \
     grep -E '^[[:space:]]*TASK=' \"\${RUNTIME_CONF}\" | tail -n 1"; then
    echo "[${IP}] 远端工程整理失败"
    exit 1
fi

##############################################################################
# 编译
##############################################################################

echo "[${IP}] 开始编译..."

if ! expect << EOF
set timeout -1

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${IP}

expect "password:"
send "${REMOTE_PASS}\r"

expect "\\$ "
send "export PS1='EXPECT_PROMPT>'\r"

expect "EXPECT_PROMPT>"
send "cp -r ${REMOTE_RESOURCE_DIR} ${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}/\r"

expect "EXPECT_PROMPT>"
send "cd ${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}\r"

expect "EXPECT_PROMPT>"
send "./build_and_install.sh\r"

set robot_type "${ROBOT_TYPE}"

# 只有 wlrobot_o1 需要先回答一次 n。
if {\$robot_type eq "wlrobot_o1"} {
    expect "y/n"
    send "n\r"
}

expect "y/n"
send "y\r"

expect "y/n"
send "y\r"

expect "EXPECT_PROMPT>"
send "./compress_install.sh\r"

expect "y/n"
send "y\r"

expect "EXPECT_PROMPT>"
send "exit\r"

expect eof
EOF
then
    echo "[${IP}] 编译失败"
    exit 1
fi

##############################################################################
# 下载
##############################################################################

echo "[${IP}] 下载 packages..."

if ! sshpass -p "$REMOTE_PASS" \
    scp -r \
    -o StrictHostKeyChecking=no \
    "${REMOTE_USER}@${IP}:${REMOTE_PACKAGE_ROOT}/${REMOTE_NAME}/packages/*" \
    "$OUTPUT_DIR/"; then
    echo "[${IP}] 下载 packages 失败"
    exit 1
fi

##############################################################################
# 下载成功后删除远端打包目录
##############################################################################

if ! cleanup_remote; then
    echo "[${IP}] packages 已下载，但远端临时目录清理失败"
    exit 1
fi

trap - EXIT INT TERM

##############################################################################
# 完成
##############################################################################

echo ""
echo "===================================================="
echo "BUILD SUCCESS"
echo "===================================================="
echo "设备编号：${DEVICE_ID}"
echo "机器人类型：${ROBOT_TYPE}"
echo "输出目录："
echo "$OUTPUT_DIR"