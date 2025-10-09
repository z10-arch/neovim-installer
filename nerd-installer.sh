#!/bin/bash

set -e

# Required tools
REQUIRED_TOOLS=(curl unzip fc-cache)

echo "Checking for required packages..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: '$tool' is not installed. Please install it and rerun the script."
        exit 1
    fi
done
echo "All required tools are installed."

# Variables
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
FONT_ZIP="CascadiaCode.zip"
FONT_DIR="$HOME/.local/share/fonts/CascadiaCode"

echo "Downloading CascadiaCode Nerd Font..."
curl -LO "$FONT_URL"

echo "Creating font directory at $FONT_DIR ..."
mkdir -p "$FONT_DIR"

echo "Extracting fonts..."
unzip -o "$FONT_ZIP" -d "$FONT_DIR"

echo "Updating font cache for user..."
fc-cache -fv "$HOME/.local/share/fonts"

echo "Cleaning up zip..."
rm -f "$FONT_ZIP"

echo "FiraCode Nerd Font installed to $FONT_DIR"
