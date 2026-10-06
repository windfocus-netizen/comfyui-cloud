# Vast.ai / AutoDL 启动配置说明

## Vast.ai（海外）

**租实例时这样填**（Create Instance → Edit Image & Config）：

1. **Image**：`ghcr.io/windfocus/comfyui-env:latest`（公开镜像，无需登录）
2. **Docker Options**（关键）：
   ```
   -e HF_TOKEN=这里填你的HuggingFace_Token -e OPEN_BUTTON_PORT=8188 -p 8188:8188
   ```
   - `HF_TOKEN`：下载你 HF 私有仓模型的钥匙，**每次租卡现填，不存任何地方**
   - `OPEN_BUTTON_PORT=8188`：让 Vast 页面上的 Open 按钮直接打开 ComfyUI
   - `-p 8188:8188`：把 ComfyUI 端口映射出来
3. **Launch mode（二选一，重要）**：
   - **Entrypoint 模式（推荐）**：保留镜像自带的启动脚本，容器一启动就自动下载模型、打开 ComfyUI，全程不用管。
   - **Jupyter 模式**：Vast 会覆盖掉镜像启动脚本。想用这个模式，就在 **On-start Script** 里加一行：
     ```
     /opt/entrypoint.sh &
     ```
     效果一样，只是一个在前台、一个在后台跑。
4. **Disk**：给够模型空间（比如 60~100GB，HF_TOKEN 的私有仓里模型有多大就给多大）。
5. 启动后点 **Open** 按钮，就是 ComfyUI 界面（8188 端口）。

**计费与销毁**（已核实，见 QUOTAS.md）：
- 按秒计费，没有最低消费；GPU 只在实例 running 时计费。
- **Stop 只停 GPU，磁盘存储继续计费**；跑完一定要点 **Destroy**，才彻底不花钱。
- 模型在 HF 私有仓、环境在 GHCR 镜像里，删实例不丢任何东西，下次重租一键恢复。

## AutoDL（国内）

1. 镜像先用 workflow 同步到阿里云 ACR 个人版（公开仓库），地址形如：
   `registry.cn-hangzhou.aliyuncs.com/你的命名空间/comfyui-env:latest`
   （地域按你 ACR 实际开通的填）
2. AutoDL 创建实例 → 选**自定义镜像** → 填上面的 ACR 公网地址（公开仓库免登录）。
3. 端口映射加 `8188`；环境变量加 `HF_TOKEN=你的Token`。
4. 启动命令留空（用镜像自带的 ENTRYPOINT），容器起来后自动下载模型、启动 ComfyUI。
5. AutoDL 的关机计费规则以当时页面为准；不用时关机/释放实例，模型与环境都在云端，下次重建即恢复。

## 常见问题

- **启动后 ComfyUI 打不开**：先看容器日志，十有八九是 `HF_TOKEN` 没填或填错，模型没下载下来。
- **模型下载慢**：Vast 海外机器连 HF 很快；AutoDL 国内机器连 HF 可能慢，可考虑把模型也同步一份到阿里云 OSS（后续再加）。
- **想更新自定义节点**：进实例 `cd /opt/ComfyUI/custom_nodes/XXX && git pull`，或改 Dockerfile 重新触发构建。
