# ComfyUI 云端一键恢复

目标：环境一次打包好，以后每次租卡只管出图，不用再现场调环境。

原理很简单：Docker 镜像里只装 ComfyUI + 运行环境 + 启动脚本（不含大模型、不含任何密码）；容器启动时自动从你自己的 HuggingFace 私有仓下载模型。镜像是公开的，里面没秘密，放心推。

## 手机操作步骤

**第 1 步：建公开仓库**
手机打开 github.com/new，仓库名填 `comfyui-cloud`，选 Public，点创建。

**第 2 步：上传文件**
把本目录所有文件传到仓库根目录（手机上用 GitHub 网页点 Add file → Upload files，或用 GitHub App）。

**第 3 步：一键构建**
仓库页面点 Actions → 选 "Build and Push ComfyUI image" → Run workflow。云端免费构建，几十分钟后镜像自动出现在 `ghcr.io/windfocus/comfyui-env:latest`。

**第 4 步：把镜像设为公开**
第一次推送后，去 github.com/windfocus → Packages → 找到 comfyui-env → Package settings → 改成 Public。以后 Vast 拉取就不用登录了。

**第 5 步（国内用）：同步到阿里云**
阿里云控制台开容器镜像服务个人版（免费），建命名空间、建公开仓库；把仓库地址、命名空间、账号密码填进 GitHub 仓库的 Secrets（ACR_REGISTRY / ACR_NAMESPACE / ACR_USERNAME / ACR_PASSWORD），再跑一次 workflow 就自动同步过去。

**第 6 步：租卡跑图**
Vast.ai 或 AutoDL 按 `vast-autodl.md` 填：镜像地址 + 环境变量 `HF_TOKEN`（你的 HuggingFace Token）+ 端口 8188。启动后容器自动下载模型、打开 ComfyUI，浏览器访问即用。

**第 7 步：跑完删实例**
图收好后，一定要点 Destroy 删实例（只 Stop 的话存储还在计费）。模型在 HF 私有仓里，环境在镜像里，下次租卡一键恢复。

## 文件说明

| 文件 | 干嘛的 |
|---|---|
| `Dockerfile` | 环境配方：CUDA 12.4 + PyTorch + ComfyUI + ComfyUI-Manager |
| `entrypoint.sh` | 容器启动入口：先下载模型，再启动 ComfyUI |
| `download_models.sh` | 按清单下载模型，断点续传 + sha256 校验 |
| `MODELS.txt` | 模型清单模板（示例占位，定好模型后替换） |
| `.github/workflows/build-push.yml` | Actions 自动构建 + 推送 GHCR + 同步 ACR |
| `vast-autodl.md` | Vast.ai / AutoDL 启动配置详细说明 |
| `QUOTAS.md` | 各平台免费配额核实结论（含来源） |

## 安全红线

- 镜像是**公开**的：绝不往里面放模型权重、Token、密码。
- `HF_TOKEN` 只在租卡时填进环境变量，容器销毁即消失。
- 模型放你自己的 HF **私有**仓，别人看不到。
