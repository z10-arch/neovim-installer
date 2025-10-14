#!/bin/bash

set -e

# Check for sudo access
if ! sudo -v >/dev/null 2>&1; then
    echo "Error: This script requires sudo privileges."
    exit 1
fi

apt install fzf fontconfig -y

# Required tools
REQUIRED_TOOLS=(curl wget tar git realpath)

echo "Checking for required packages..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: '$tool' is not installed. Please install it and rerun the script."
        exit 1
    fi
done
echo "All required tools are installed."

# Variables
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
ARCHIVE="nvim-linux-x86_64.tar.gz"
INSTALL_DIR="/opt/nvim"
EXTRACTED_DIR="/opt/nvim-linux-x86_64"
SYMLINK="/usr/local/bin/nvim"

echo "Downloading latest Neovim (x86_64)..."
curl -LO "$DOWNLOAD_URL"

echo "Removing existing Neovim binaries and directories..."
sudo rm -f /usr/bin/nvim /usr/local/bin/nvim /bin/nvim
sudo rm -rf "$INSTALL_DIR"
sudo rm -rf "$EXTRACTED_DIR"

echo "Extracting Neovim..."
sudo tar -xzf "$ARCHIVE" -C /opt
sudo mv "$EXTRACTED_DIR" "$INSTALL_DIR"

echo "Creating relative symlink in /usr/local/bin..."
REL_PATH=$(realpath --relative-to=/usr/local/bin "$INSTALL_DIR/bin/nvim")
sudo ln -sf "$REL_PATH" "$SYMLINK"

echo "Cleaning up archive..."
rm -f "$ARCHIVE"

echo "Neovim installed successfully!"
nvim --version
