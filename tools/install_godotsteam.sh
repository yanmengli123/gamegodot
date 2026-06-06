#!/bin/bash
# GodotSteam 一键安装脚本（Linux/macOS）
# 用法：bash install_godotsteam.sh
# Windows 用户：用 PowerShell 版本

set -e

GODOT_VERSION="4.6.3"
GODOTSTEAM_REPO="https://github.com/Grashopr/godot_steam"
ADDON_DIR="$(dirname "$0")/../demo/addons/godotsteam"

echo "=== GodotSteam Installer ==="
echo "Godot version: $GODOT_VERSION"
echo "Addon dir: $ADDON_DIR"

# 创建 addon 目录
mkdir -p "$ADDON_DIR"

# 临时下载
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "Downloading latest GodotSteam release..."
LATEST_URL=$(curl -sL "https://api.github.com/repos/Grashopr/godot_steam/releases/latest" | grep "browser_download_url" | head -1 | cut -d '"' -f 4)
if [ -z "$LATEST_URL" ]; then
  echo "Failed to find latest release URL. Visit $GODOTSTEAM_REPO/releases manually."
  exit 1
fi

echo "Latest: $LATEST_URL"
curl -L -o godotsteam.zip "$LATEST_URL"
unzip -q godotsteam.zip

# 复制 gdsteam 目录
if [ -d "gdsteam" ]; then
  cp -r gdsteam/* "$ADDON_DIR/"
  echo "✅ GodotSteam installed to $ADDON_DIR"
else
  echo "❌ gdsteam/ not found in archive"
  exit 1
fi

# 清理
cd /
rm -rf "$TMPDIR"

echo ""
echo "Next: restart Godot and enable plugin in Project Settings > Plugins"
