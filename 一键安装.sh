#!/usr/bin/env bash
# ============================================================
#  Kaguya 液态玻璃皮肤 · 一键安装（macOS / Linux）
#  用法：在仓库根目录执行  ./一键安装.sh
#  效果：复制皮肤包到 DSH profile + 合并挂载行（可重复运行）。
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/anime-theme"

if [[ ! -f "$PKG/package.json" ]]; then
  echo "[错误] 没有在脚本旁边找到 anime-theme 包，请把本脚本放在仓库根目录再运行。" >&2
  exit 1
fi

# 1. 定位 DSH profile 目录（可用 DSH_HOME 覆盖）
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
PROFILE="$DSH_HOME_DIR/profiles/web"

if [[ ! -d "$PROFILE" ]]; then
  echo "[错误] 找不到 DSH profile 目录：$PROFILE" >&2
  echo "请先安装 DeepSeek Harness 并成功运行过一次 dsh web（首次运行会自动创建 profile），再执行本脚本。" >&2
  exit 1
fi

# 2. 复制皮肤包（覆盖更新，幂等）
DEST="$PROFILE/node_modules/anime-theme"
mkdir -p "$DEST"
cp -R "$PKG"/. "$DEST"/
echo "[1/3] 皮肤包已安装：$DEST"

# 3. 合并挂载行（幂等：已存在则跳过；修改前自动备份）
PATCH="$PROFILE/cordis.patch.yml"
ROW=$'- insert:\n    - id: ui-anime-theme\n      name: \'anime-theme\'\n'
if [[ ! -f "$PATCH" ]]; then
  printf '%s' "$ROW" > "$PATCH"
  echo "[2/3] 已创建 cordis.patch.yml 并写入挂载行"
elif grep -q 'ui-anime-theme' "$PATCH"; then
  echo "[2/3] 挂载行已存在，跳过"
else
  cp "$PATCH" "$PATCH.bak-$(date +%Y%m%d-%H%M%S)"
  printf '\n%s' "$ROW" >> "$PATCH"
  echo "[2/3] 挂载行已追加（原文件已备份）"
fi

# 4. 完成提示
echo "[3/3] 安装完成！"
echo ""
echo "下一步：重启 dsh web，然后浏览器打开 http://127.0.0.1:3080（浅色模式）即可看到 Kaguya 皮肤。"
echo "以后更新皮肤：把新文件放进本仓库目录，再运行一次本脚本，浏览器刷新即可。"
