#!/usr/bin/env bash
set -e
set -o pipefail

# ==========================================================
# 🧠 VPS Initial Setup Script
# Installs dev essentials: fzf, build tools, LazyGit, Go, etc.
# ==========================================================

echo "🚀 Starting VPS setup..."

# -----------------------------
# 1. Update and install base packages
# -----------------------------
echo "📦 Installing essential packages..."
sudo apt update -y
sudo apt install -y \
  fzf build-essential fontconfig curl wget tar git coreutils \
  fd-find ripgrep python3-pip ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick

echo "Installing Yazi Packages"
wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
unzip -q yazi.zip -d yazi-temp
sudo mv yazi-temp/*/{ya,yazi} /usr/local/bin
rm -rf yazi-temp yazi.zip

# -----------------------------
# 2. Python tools
# -----------------------------
echo "🐍 Installing Python packages..."
pip install ast-grep-cli || { echo "Retrying with --break-system-packages"; pip install ast-grep-cli --break-system-packages; }

# -----------------------------
# 3. Install LazyGit (latest release)
# -----------------------------
echo "🧰 Installing LazyGit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
  | grep -Po '"tag_name": *"v\K[^"]*')

curl -Lo lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm -f lazygit lazygit.tar.gz

# -----------------------------
# 4. Install Go (manually)
# -----------------------------
GO_VERSION="1.25.3"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://dl.google.com/go/${GO_TARBALL}"

echo "📦 Installing Go ${GO_VERSION}..."

# Remove any old Go installation
sudo rm -rf /usr/local/go
sudo rm -f /usr/bin/go

# Download and extract
wget -q "${GO_URL}" -O "/tmp/${GO_TARBALL}"
sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
rm -f "/tmp/${GO_TARBALL}"

# Add Go to PATH system-wide if not already
if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile >/dev/null
fi

# Reload path for current session
export PATH=$PATH:/usr/local/go/bin

# Verify installation
echo "✅ Verifying Go installation..."
go version

# -----------------------------
# 5. Final summary
# -----------------------------
echo "🎉 Setup complete!"
echo
echo "Installed tools:"
echo "  • Go $(go version | awk '{print $3}')"
echo "  • LazyGit v${LAZYGIT_VERSION}"
echo "  • fzf, fd-find, ripgrep, build-essential, python3-pip, ast-grep-cli"
echo
echo "✅ VPS environment ready to use!"

