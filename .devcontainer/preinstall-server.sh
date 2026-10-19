#!/bin/bash
set -e
COMMIT_ID="${VSCODE_COMMIT_ID:-}"
[ -z "$COMMIT_ID" ] && { echo "无 VSCODE_COMMIT_ID，跳过预装"; exit 0; }

TARGET="$HOME/.vscode-server/bin/${COMMIT_ID}"
[ -f "$TARGET/0" ] && { echo "已存在，跳过"; exit 0; }

case "$(uname -m)" in
  x86_64)  ARCH=linux-x64 ;;
  aarch64) ARCH=linux-arm64 ;;
  *) echo "不支持的架构"; exit 0 ;;
esac

mkdir -p "$TARGET"
curl -fsSL "https://update.code.visualstudio.com/commit:${COMMIT_ID}/server-${ARCH}/stable" \
  | tar -xz -C "$TARGET" --strip-components 1
touch "$TARGET/0"
