#!/bin/bash

echo "🔧 Rovodev Installer Starting..."

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_TYPE="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ARCH_TYPE="arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "➡️  Detected architecture: $ARCH_TYPE"

# Download latest binary
URL="https://acli.atlassian.com/linux/latest/acli_linux_${ARCH_TYPE}/acli"
echo "⬇️  Downloading from: $URL"

curl -fsSL -o acli "$URL"

if [[ ! -f "acli" ]]; then
    echo "❌ Download failed. Check internet or URL."
    exit 1
fi

# Install binary
echo "📦 Installing to /usr/bin..."
sudo mv acli /usr/bin/
sudo chmod +x /usr/bin/acli

# Verify installation
if command -v acli >/dev/null 2>&1; then
    echo "✅ Rovodev (acli) Installed Successfully!"
    acli --version 2>/dev/null || echo "ℹ️  acli installed but version info unavailable."
else
    echo "❌ Rovodev installation failed."
    exit 1
fi
