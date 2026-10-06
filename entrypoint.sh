#!/usr/bin/env bash
# 容器启动入口：先按 MODELS.txt 检查/下载模型，再启动 ComfyUI。
# 环境变量：
#   HF_TOKEN     HuggingFace Token（下载私有仓模型用，必填除非模型已在数据盘）
#   MODELS_FILE  模型清单路径（默认 /opt/MODELS.txt）
#   COMFYUI_ARGS 透传给 ComfyUI 的额外参数（默认空）
set -euo pipefail

COMFY_DIR="/opt/ComfyUI"
MODELS_FILE="${MODELS_FILE:-/opt/MODELS.txt}"

echo "[entrypoint] 检查模型清单: ${MODELS_FILE}"
if [ -f "${MODELS_FILE}" ]; then
    /opt/download_models.sh "${MODELS_FILE}" || {
        echo "[entrypoint] 警告：部分模型下载失败，ComfyUI 仍会启动（缺失模型的工作流会报错）"
    }
else
    echo "[entrypoint] 未找到模型清单，跳过模型下载"
fi

echo "[entrypoint] 启动 ComfyUI (0.0.0.0:8188)"
cd "${COMFY_DIR}"
# shellcheck disable=SC2086
exec python3 main.py --listen 0.0.0.0 --port 8188 ${COMFYUI_ARGS:-}
