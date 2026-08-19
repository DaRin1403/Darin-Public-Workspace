#!/usr/bin/env bash
# ============================================================
#  Kaguya 液态玻璃皮肤 · 网络一键安装（macOS / Linux）
#  由用户在终端粘贴的一条命令下载并执行：
#    curl -fsSL https://raw.githubusercontent.com/DaRin1403/Darin-Public-Workspace/main/install-oneline.sh | bash
#  （国内网络可换用 jsdelivr 镜像：
#    curl -fsSL https://cdn.jsdelivr.net/gh/DaRin1403/Darin-Public-Workspace@main/install-oneline.sh | bash）
#  流程：下载最新仓库 zip → 解压到临时目录 → 执行仓库内「一键安装.sh」→ 清理。
# ============================================================
set -euo pipefail

BASE="https://github.com/DaRin1403/Darin-Public-Workspace"
URL="$BASE/archive/refs/heads/main.zip"
TMP="$(mktemp -d /tmp/kaguya-theme-install.XXXXXX)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "[1/4] 正在下载最新版皮肤仓库…"
if ! curl -fL --connect-timeout 30 -o "$TMP/repo.zip" "$URL"; then
  echo ""
  echo "[失败] 无法直连 GitHub 下载仓库。" >&2
  echo "请手动下载压缩包 Kaguya_Theme_1.1.0.zip，解压后进入目录执行 ./一键安装.sh 即可。" >&2
  exit 1
fi

echo "[2/4] 解压中…"
unzip -q "$TMP/repo.zip" -d "$TMP"
INNER="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d -name 'Darin-Public-Workspace*' | head -n 1)"
if [[ -z "$INNER" ]]; then
  echo "[失败] 解压结果里没找到仓库目录" >&2
  exit 1
fi

echo "[3/4] 开始安装…"
bash "$INNER/一键安装.sh"

echo "[4/4] 全部完成！"
echo ""
echo "最后一步：重启 dsh web，浏览器打开 http://127.0.0.1:3080（浅色模式）即可看到 Kaguya 皮肤。"
