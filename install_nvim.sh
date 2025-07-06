#!/bin/bash

set -e  # Exit on any error

# Required tools
REQUIRED_TOOLS=(curl wget tar git realpath)

echo "Checking for required packages..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: '$tool' is not installed. Please install it first and rerun the script."
        exit 1
    fi
done

echo "All required tools are installed."

# Variables
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
ARCHIVE="nvim-linux-x86_64.tar.gz"
INSTALL_DIR="/opt/nvim"
SYMLINK="/usr/local/bin/nvim"

echo "Downloading latest Neovim (x86_64)..."
curl -LO "$DOWNLOAD_URL"

echo "Removing any existing Neovim installation..."
sudo rm -rf "$INSTALL_DIR"

echo "Extracting Neovim..."
sudo tar -xzf "$ARCHIVE" -C /opt
# Extracts as nvim-linux64 even if archive is x86_64
sudo mv /opt/nvim-linux64 "$INSTALL_DIR"

echo "Creating relative symlink in /usr/local/bin..."
# Remove existing symlink if it exists
sudo rm -f "$SYMLINK"

# Create relative symlink to binary
REL_PATH=$(realpath --relative-to=/usr/local/bin "$INSTALL_DIR/bin/nvim")
sudo ln -s "$REL_PATH" "$SYMLINK"

echo "Cleaning up archive..."
rm -f "$ARCHIVE"

echo "Neovim installed successfully!"
nvim --version
