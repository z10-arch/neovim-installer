#!/usr/bin/env bash
set -e

echo "===== LazyVim VPS Bootstrap (final) ====="

ARCH=$(uname -m)

have() {
  command -v "$1" >/dev/null 2>&1
}

# -------------------------------------------------
# 1. System update + base tools
# -------------------------------------------------
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  git curl wget unzip ca-certificates \
  build-essential gcc g++ make \
  software-properties-common \
  fontconfig file jq fzf p7zip-full \
  poppler-utils fd-find ffmpeg zsh sqlite3 eza aria2 tmux fc-cache unzip

# NERD Font installation
if fc-list | grep -qiE 'Cascadia Code|CaskaydiaCove'; then
    echo "Cascadia Code Nerd Font already installed. Skipping."
else
    echo "Cascadia Code Nerd Font not found. Installing..."

    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR" || exit 1
    cd "$FONT_DIR" || exit 1

    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip &&
    unzip -o CascadiaCode.zip &&
    fc-cache -fv
fi


# fd command fix
if ! have fd; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# -------------------------------------------------
# 2. Python (system-safe)
# -------------------------------------------------
sudo apt install -y \
  python3 python3-pip python3-venv python3-dev pipx

pipx ensurepath

# uv (astral)
if ! have uv; then
  curl -Ls https://astral.sh/uv/install.sh | sh
  sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv
fi

# -------------------------------------------------
# 3. Go (latest official, skip if installed)
# -------------------------------------------------
if have go; then
  echo "Go already installed: $(go version)"
else
  echo "Installing latest Go..."

  GO_ARCH=""
  case "$ARCH" in
    x86_64) GO_ARCH="amd64" ;;
    aarch64|arm64) GO_ARCH="arm64" ;;
    *)
      echo "Unsupported architecture for Go: $ARCH"
      exit 1
      ;;
  esac

  GO_VERSION="$(curl -fsSL https://go.dev/VERSION?m=text | sed -n '1p')"

  if [ -z "$GO_VERSION" ]; then
    echo "Failed to detect latest Go version"
    exit 1
  fi

  GO_TARBALL="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  GO_URL="https://go.dev/dl/${GO_TARBALL}"

  echo "Downloading ${GO_VERSION} (${GO_ARCH})"

  cd /tmp
  curl -fLO "$GO_URL"

  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$GO_TARBALL"

  rm -f "$GO_TARBALL"

  # Environment setup (system-wide)
  sudo tee /etc/profile.d/go.sh >/dev/null <<'EOF'
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF

  sudo chmod 644 /etc/profile.d/go.sh

  # Load immediately for current shell
  export GOROOT=/usr/local/go
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"

  echo "Go installed successfully: $(go version)"
fi

# -------------------------------------------------
# 4. Node.js LTS
# -------------------------------------------------
if ! have node; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# -------------------------------------------------
# 5. Neovim (latest stable via PPA)
# -------------------------------------------------
if ! have nvim; then
  sudo add-apt-repository ppa:neovim-ppa/stable -y
  sudo apt update
  sudo apt install -y neovim
fi

# -------------------------------------------------
# 6. ripgrep (latest, .deb for amd64)
# -------------------------------------------------
if ! have rg; then
  RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)

  if [ "$ARCH" = "x86_64" ]; then
    RG_DEB="ripgrep_${RG_VERSION}-1_amd64.deb"
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/${RG_DEB}"
    sudo dpkg -i "$RG_DEB"
    rm -f "$RG_DEB"
  else
    echo "ripgrep: non-amd64 detected, using apt fallback"
    sudo apt install -y ripgrep
  fi
fi

# -------------------------------------------------
# 7. ast-grep (zip install)
# -------------------------------------------------
if ! have sg; then
  ASG_VERSION=$(curl -s https://api.github.com/repos/ast-grep/ast-grep/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)

  case "$ARCH" in
    x86_64) ASG_ZIP="app-x86_64-unknown-linux-gnu.zip" ;;
    aarch64|arm64) ASG_ZIP="app-aarch64-unknown-linux-gnu.zip" ;;
    *) echo "Unsupported arch for ast-grep"; exit 1 ;;
  esac

  cd /tmp
  curl -LO "https://github.com/ast-grep/ast-grep/releases/download/${ASG_VERSION}/${ASG_ZIP}"
  unzip -o "$ASG_ZIP"
  sudo install -m 755 sg /usr/local/bin/sg
  rm -f "$ASG_ZIP" sg ast-grep
fi

# -------------------------------------------------
# 8. zoxide
# -------------------------------------------------
if ! have zoxide; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  sudo ln -sf "$HOME/.local/bin/zoxide" /usr/local/bin/zoxide
fi

# -------------------------------------------------
# 9. Yazi (zip install, FIXED)
# -------------------------------------------------
if ! have yazi; then
  YAZI_VERSION=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f 4)

  case "$ARCH" in
    x86_64)
      YAZI_ZIP="yazi-x86_64-unknown-linux-gnu.zip"
      YAZI_DIR="yazi-x86_64-unknown-linux-gnu"
      ;;
    aarch64|arm64)
      YAZI_ZIP="yazi-aarch64-unknown-linux-gnu.zip"
      YAZI_DIR="yazi-aarch64-unknown-linux-gnu"
      ;;
    *) echo "Unsupported arch for Yazi"; exit 1 ;;
  esac

  cd /tmp
  curl -LO "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/${YAZI_ZIP}"
  unzip -o "$YAZI_ZIP"

  sudo install -m 755 "$YAZI_DIR/yazi" /usr/local/bin/yazi
  sudo install -m 755 "$YAZI_DIR/ya" /usr/local/bin/ya

  rm -rf "$YAZI_ZIP" "$YAZI_DIR"
fi

# -------------------------------------------------
# 10. Tectonic (official installer)
# -------------------------------------------------
if ! have tectonic; then
  cd /tmp
  curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh
  sudo mv tectonic /usr/local/bin/tectonic
  sudo chmod +x /usr/local/bin/tectonic
fi

# -------------------------------------------------
# 11. LazyVim installation
# -------------------------------------------------
NVIM_CONFIG="$HOME/.config/nvim"

if [ ! -d "$NVIM_CONFIG" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
  rm -rf "$NVIM_CONFIG/.git"
fi

mkdir -p "$HOME/.local/share/nvim" "$HOME/.cache/nvim"

# -------------------------------------------------
# 12. Post-install verification
# -------------------------------------------------
echo ""
echo "===== Verification ====="

for cmd in nvim rg sg yazi ya zoxide node python3 go tectonic; do
  if have "$cmd"; then
    echo "OK: $cmd -> $(command -v $cmd)"
  else
    echo "MISSING: $cmd"
  fi
done

echo ""
echo "Bootstrap complete."
echo "Next:"
echo "  1) Set your LOCAL terminal font to a Nerd Font"
echo "  2) Run: nvim"
echo "  3) Wait for plugins, then restart nvim"
