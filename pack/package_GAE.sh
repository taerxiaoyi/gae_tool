#!/bin/bash

set -u
set -o pipefail

##############################################################################
# 公共配置
##############################################################################

SRC_DIR="policy_deploy_pack"

PACKAGE_ROOT="$HOME/Mc/robot_file/GAE_release/webctrl_packages"
PACKAGE_VERSION="v1.2.0"

DATE_TIME=$(date +"%Y%m%d%H%M%S")
DATE_DAY=$(date +"%Y%m%d")
REMOTE_NAME="policy_deploy_pack_${DATE_TIME}"

##############################################################################
# 使用说明
##############################################################################

show_devices()
{
    echo "已添加的设备信息："
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "编号" "设备环境" "IP" "远端用户" "机器人类型"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "1" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "unitree_g1"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "2" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "wlrobot_o1"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "3" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "engine_pm01"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "4" "Ubuntu22 CUDA12 TRT10" "192.168.2.229" "wlrobot" "kepler_k2"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "5" "Ubuntu22 CUDA12 TRT8" "192.168.2.90" "wlrobot" "unitree_g1"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "6" "Ubuntu20 CUDA11 TRT8" "192.168.2.xxx" "wlrobot" "unitree_g1"
    printf "  %-4s %-29s %-17s %-12s %s
" \
        "7" "Ubuntu22 CUDA12 TRT10" "192.168.1.209" "mc" "unitree_g1"
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

# 未传设备编号时，只列出当前脚本中已经添加的设备信息。
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
# ROBOT_TYPE 可选：unitree_g1、wlrobot_o1、engine_pm01、kepler_k2
##############################################################################

DEVICE_ID="$1"

case "$DEVICE_ID" in
    1)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT10"
        IP="192.168.2.229"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="g1_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}"
        ROBOT_TYPE="unitree_g1"
        ;;
        
    2)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT10"
        IP="192.168.2.229"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="o1_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}"
        ROBOT_TYPE="wlrobot_o1"
        ;;

    3)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT10"
        IP="192.168.2.229"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="pm01_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}"
        ROBOT_TYPE="engine_pm01"
        ;;

    4)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT10"
        IP="192.168.2.229"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="k2_webctrl_aarch64_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}"
        ROBOT_TYPE="kepler_k2"
        ;;

    5)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT8"
        IP="192.168.2.90"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="g1_webctrl_aarch64_ubuntu22_cuda12_trt8_${PACKAGE_VERSION}"
        ROBOT_TYPE="unitree_g1"
        ;;

    6)
        DEVICE_DESC="Ubuntu20 CUDA11 TRT8"
        IP="192.168.3.77"
        REMOTE_USER="wlrobot"
        REMOTE_PASS="123"
        TARGET_FOLDER="g1_webctrl_aarch64_ubuntu20_cuda11_trt8_${PACKAGE_VERSION}"
        ROBOT_TYPE="unitree_g1"
        ;;

    7)
        DEVICE_DESC="Ubuntu22 CUDA12 TRT10"
        IP="192.168.1.209"
        REMOTE_USER="mc"
        REMOTE_PASS="3"
        TARGET_FOLDER="g1_webctrl_amd86_ubuntu22_cuda12_trt10_${PACKAGE_VERSION}"
        ROBOT_TYPE="unitree_g1"
        ;;

    -h|--help)
        show_usage
        exit 0
        ;;

    *)
        echo "错误：未知设备编号：${DEVICE_ID}"
        echo ""
        show_usage
        exit 1
        ;;
esac

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
        TASK_NAME="g1_eman"
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

REMOTE_RESOURCE_DIR="~/code/mc/resources_pack/${RESOURCE_PACK_NAME}/resources"

RELEASE_DIR="${PACKAGE_ROOT}/encry_without_shell_${PACKAGE_VERSION}_${DATE_DAY}"
OUTPUT_DIR="${RELEASE_DIR}/${TARGET_FOLDER}"
RUNTIME_CONF="${SRC_DIR}/setup/etc/runtime.conf"

##############################################################################
# 基础检查
##############################################################################

for command_name in sshpass scp ssh expect sed grep; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "错误：未找到命令 ${command_name}"
        exit 1
    fi
done

if [ ! -d "$SRC_DIR" ]; then
    echo "错误：源码目录不存在：${SRC_DIR}"
    exit 1
fi

if [ ! -f "$RUNTIME_CONF" ]; then
    echo "错误：配置文件不存在：${RUNTIME_CONF}"
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
echo "资源目录   : ${REMOTE_RESOURCE_DIR}"
echo "输出目录   : ${OUTPUT_DIR}"
echo "===================================================="

##############################################################################
# 上传前清理本地源码目录
##############################################################################

echo ""
echo "[LOCAL] 清理 ${SRC_DIR} 中的构建目录..."

LOCAL_CLEAN_DIRS=(build install resources log packages)

for dir_name in "${LOCAL_CLEAN_DIRS[@]}"; do
    dir_path="${SRC_DIR}/${dir_name}"

    if [ -e "$dir_path" ] || [ -L "$dir_path" ]; then
        echo "[LOCAL] 删除：${dir_path}"
        if ! rm -rf -- "$dir_path"; then
            echo "错误：删除失败：${dir_path}"
            exit 1
        fi
    else
        echo "[LOCAL] 不存在，跳过：${dir_path}"
    fi
done

##############################################################################
# 上传前修改 runtime.conf
##############################################################################

echo ""
echo "[LOCAL] 设置 runtime.conf：TASK=${TASK_NAME}"

if grep -qE '^[[:space:]]*TASK=' "$RUNTIME_CONF"; then
    if ! sed -i -E "s|^[[:space:]]*TASK=.*$|TASK=${TASK_NAME}|" "$RUNTIME_CONF"; then
        echo "错误：修改 ${RUNTIME_CONF} 失败"
        exit 1
    fi
else
    if ! printf '\nTASK=%s\n' "$TASK_NAME" >> "$RUNTIME_CONF"; then
        echo "错误：写入 ${RUNTIME_CONF} 失败"
        exit 1
    fi
fi

echo "[LOCAL] 当前配置：$(grep -E '^[[:space:]]*TASK=' "$RUNTIME_CONF" | tail -n 1)"

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
    echo "[${IP}] 删除远端临时目录：~/code/mc/${REMOTE_NAME}"

    if sshpass -p "$REMOTE_PASS" \
        ssh \
        -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${IP}" \
        "rm -rf ~/code/mc/${REMOTE_NAME}"; then
        REMOTE_UPLOADED=0
        echo "[${IP}] 远端临时目录已删除"
        return 0
    fi

    echo "[${IP}] 警告：远端临时目录删除失败，请手动删除：~/code/mc/${REMOTE_NAME}" >&2
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
    "mkdir -p ~/code/mc && rm -rf ~/code/mc/${REMOTE_NAME}"; then
    echo "[${IP}] 远端目录准备失败"
    exit 1
fi

echo "[${IP}] 上传工程..."

REMOTE_UPLOADED=1

if ! sshpass -p "$REMOTE_PASS" \
    scp -r \
    -o StrictHostKeyChecking=no \
    "$SRC_DIR" \
    "${REMOTE_USER}@${IP}:~/code/mc/${REMOTE_NAME}"; then
    echo "[${IP}] 上传失败"
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
send "cp -r ${REMOTE_RESOURCE_DIR} ~/code/mc/${REMOTE_NAME}/\r"

expect "EXPECT_PROMPT>"
send "cd ~/code/mc/${REMOTE_NAME}\r"

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
    "${REMOTE_USER}@${IP}:~/code/mc/${REMOTE_NAME}/packages/*" \
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
