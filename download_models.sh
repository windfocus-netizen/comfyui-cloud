#!/usr/bin/env bash
# 按 MODELS.txt 清单下载模型到 ComfyUI/models/ 下。
# 特性：已存在且 sha256 匹配则跳过；下载支持断点续传（huggingface_hub）。
# 用法：download_models.sh [清单路径]   （默认 /opt/MODELS.txt）
# 需要环境变量 HF_TOKEN（私有仓下载用）。
set -euo pipefail

MODELS_FILE="${1:-/opt/MODELS.txt}"
MODELS_DIR="/opt/ComfyUI/models"

if [ -z "${HF_TOKEN:-}" ]; then
    echo "[download] 未设置 HF_TOKEN：只能下载公开模型，私有仓会失败" >&2
fi

python3 - "$MODELS_FILE" "$MODELS_DIR" <<'PYEOF'
import hashlib, os, sys

manifest, models_dir = sys.argv[1], sys.argv[2]
token = os.environ.get("HF_TOKEN")

try:
    from huggingface_hub import snapshot_download
except ImportError:
    sys.exit("[download] 缺少 huggingface_hub，请检查 Dockerfile")

def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8 * 1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def parse_manifest(path):
    items = []
    with open(path, encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < 3:
                print(f"[download] 第{lineno}行格式不对，已跳过: {raw.strip()}")
                continue
            repo_id, filename, subdir = parts[0], parts[1], parts[2]
            sha = parts[3] if len(parts) > 3 and parts[3] else None
            items.append((repo_id, filename, subdir, sha))
    return items

failed = []
for repo_id, filename, subdir, sha in parse_manifest(manifest):
    dest_dir = os.path.join(models_dir, subdir)
    dest = os.path.join(dest_dir, filename)
    os.makedirs(dest_dir, exist_ok=True)

    if os.path.isfile(dest):
        if sha:
            if sha256_of(dest).lower() == sha.lower():
                print(f"[download] 已存在且校验通过，跳过: {subdir}/{filename}")
                continue
            print(f"[download] 校验不通过，重新下载: {subdir}/{filename}")
            os.remove(dest)
        else:
            print(f"[download] 已存在（无校验值），跳过: {subdir}/{filename}")
            continue

    print(f"[download] 下载 {repo_id} -> {subdir}/{filename}")
    try:
        snapshot_download(
            repo_id=repo_id,
            allow_patterns=[filename],
            local_dir=dest_dir,
            local_dir_use_symlinks=False,
            token=token,
            resume_download=True,
        )
    except Exception as e:  # noqa: BLE001
        print(f"[download] 失败 {repo_id}/{filename}: {e}")
        failed.append(f"{repo_id}/{filename}")
        continue

    if not os.path.isfile(dest):
        print(f"[download] 下载完成但文件不在预期位置: {dest}")
        failed.append(f"{repo_id}/{filename}")
        continue
    if sha and sha256_of(dest).lower() != sha.lower():
        print(f"[download] 下载后校验不通过: {subdir}/{filename}")
        failed.append(f"{repo_id}/{filename}")

if failed:
    print(f"[download] 以下 {len(failed)} 个模型未就绪:")
    for x in failed:
        print(f"  - {x}")
    sys.exit(1)
print("[download] 全部模型就绪")
PYEOF
