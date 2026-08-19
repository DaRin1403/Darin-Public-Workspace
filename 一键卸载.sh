#!/usr/bin/env bash
# ============================================================
#  Kaguya 液态玻璃皮肤 · 一键卸载（macOS / Linux）
#  效果：从 cordis.patch.yml 移除挂载行 + 删除皮肤包目录。
# ============================================================
set -euo pipefail

DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
PROFILE="$DSH_HOME_DIR/profiles/web"

PATCH="$PROFILE/cordis.patch.yml"
if [[ -f "$PATCH" ]] && grep -q 'ui-anime-theme' "$PATCH"; then
  cp "$PATCH" "$PATCH.bak-uninstall-$(date +%Y%m%d-%H%M%S)"
  # 删除本皮肤的挂载块（- insert: 起始的三行）
  sed -i '' $'/^- insert:$/,/name: .anime-theme./d' "$PATCH"
  echo "[1/2] 挂载行已移除（原文件已备份）"
else
  echo "[1/2] 挂载行不存在，跳过"
fi

DEST="$PROFILE/node_modules/anime-theme"
if [[ -d "$DEST" ]]; then
  rm -rf "$DEST"
  echo "[2/2] 皮肤包目录已删除"
else
  echo "[2/2] 皮肤包目录不存在，跳过"
fi

echo ""
echo "卸载完成。重启 dsh web 后恢复官方界面。"
