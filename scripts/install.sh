#!/bin/bash
set -e

REPO="javimosch/machin-tinystats"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BINARY="tinystats"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ASSET="tinystats-linux-amd64" ;;
  aarch64|arm64) ASSET="tinystats-linux-arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

mkdir -p "$INSTALL_DIR"

LATEST_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_URL=$(curl -s "$LATEST_URL" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4 | grep "$ASSET")

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not find binary download URL for $ARCH"
  exit 1
fi

echo "Downloading $DOWNLOAD_URL ..."
curl -fsSL "$DOWNLOAD_URL" -o "$INSTALL_DIR/$BINARY"
chmod +x "$INSTALL_DIR/$BINARY"

echo "Installed to $INSTALL_DIR/$BINARY"
echo "Run: tinystats server --port 9094"
