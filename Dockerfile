# ComfyUI 云端一键恢复镜像
# 设计原则：
#   1. 镜像只装环境（ComfyUI + CUDA 依赖 + 自定义节点 + 启动脚本），不装模型权重
#   2. 不含任何密钥 / Token，运行时通过环境变量传入
#   3. 公开仓库可放心推送（ghcr.io 公开包存储/流量免费，见 QUOTAS.md）
ARG CUDA_VERSION=12.4.1
FROM nvidia/cuda:${CUDA_VERSION}-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    HF_HUB_ENABLE_HF_TRANSFER=1

# 系统依赖（libgl/libglib 是 OpenCV 类库需要的）
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip git curl ca-certificates \
        libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# PyTorch（CUDA 12.4 版，与基础镜像对应）
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu124 && \
    pip3 install --no-cache-dir huggingface_hub hf_transfer

# ComfyUI 本体
WORKDIR /opt
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /opt/ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# 自定义节点：用 git clone，方便以后在运行实例里直接 git pull 更新
WORKDIR /opt/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    pip3 install --no-cache-dir -r ComfyUI-Manager/requirements.txt
# 下面是可选常用节点，需要就取消注释，重新触发构建即可
# RUN git clone https://github.com/cubiq/ComfyUI_essentials.git
# RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git

# 启动脚本与模型清单（模型权重本身不在这里，启动时按清单下载）
COPY entrypoint.sh download_models.sh MODELS.txt /opt/
RUN chmod +x /opt/entrypoint.sh /opt/download_models.sh

EXPOSE 8188
ENTRYPOINT ["/opt/entrypoint.sh"]
