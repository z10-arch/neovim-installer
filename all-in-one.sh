#!/bin/bash

set -e

##### Helper Functions #####
apt_install() {
    PKGS=()
    for pkg in "$@"; do
        if ! command -v "$pkg" >/dev/null 2>&1 && ! dpkg -s "$pkg" >/dev/null 2>&1; then
            PKGS+=("$pkg")
        fi
    done
    if [ "${#PKGS[@]}" -gt 0 ]; then
        echo "Installing missing apt packages: ${PKGS[*]}"
        sudo apt-get update
        sudo apt-get install -y "${PKGS[@]}"
    fi
}

##### 1. Ensure basic required tools #####
REQUIRED_TOOLS=(sudo curl wget tar git realpath unzip fc-cache python3 python3-pip luarocks npm)
MISSING_TOOLS=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ "${#MISSING_TOOLS[@]}" -gt 0 ]; then
    echo "Some required tools are missing: ${MISSING_TOOLS[*]}"
    # Map tools to apt packages
    PKG_MAP=("python3:python3" "python3-pip:python3-pip" "luarocks:luarocks" "npm:npm")
    APT_PKGS=()
    for mt in "${MISSING_TOOLS[@]}"; do
        PKG="$mt"
        for mapping in "${PKG_MAP[@]}"; do
            TOOL="${mapping%%:*}"
            PKGNAME="${mapping##*:}"
            if [ "$mt" == "$TOOL" ]; then
                PKG="$PKGNAME"
                break
            fi
        done
        APT_PKGS+=("$PKG")
    done
    apt_install "${APT_PKGS[@]}"
fi

##### 2. Install CLI tools #####
APT_TOOLS=(
    ripgrep
    fzf
    fd-find
    vim-julia
    imagemagick
    ghostscript
    libmagic-dev
)
echo "Checking and installing CLI tools..."
apt_install "${APT_TOOLS[@]}"

# Handle fd/fdfind symlink
if command -v fdfind >/dev/null 2>&1 && [ ! -e /usr/local/bin/fd ]; then
    echo "Creating symlink for fd -> fdfind..."
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

##### 3. Install Python and pip packages #####
PIP_TOOLS=(ast-grep-cli pdflex lazygit)
for pkg in "${PIP_TOOLS[@]}"; do
    if ! pip show "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg via pip..."
        pip install --user "$pkg"
    else
        echo "$pkg already installed via pip."
    fi
done

##### 4. Install luarocks packages #####
LUAROCKS_TOOLS=() # Add Lua rocks packages here if needed
for pkg in "${LUAROCKS_TOOLS[@]}"; do
    if ! luarocks show "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg with luarocks..."
        luarocks install "$pkg"
    else
        echo "$pkg already installed via luarocks."
    fi
done

##### 5. Install mmdc (mermaid-cli) via npm #####
if ! command -v mmdc >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
        echo "Installing mermaid-cli (mmdc) via npm..."
        sudo npm install -g @mermaid-js/mermaid-cli
    else
        echo "npm not found, skipping mmdc install."
    fi
fi

##### 6. Download and install latest Neovim #####
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
ARCHIVE="nvim-linux-x86_64.tar.gz"
INSTALL_DIR="/opt/nvim"
EXTRACTED_DIR="/opt/nvim-linux-x86_64"
SYMLINK="/usr/local/bin/nvim"

echo "Downloading latest Neovim (x86_64)..."
curl -LO "$DOWNLOAD_URL"

echo "Removing existing Neovim binaries and directories..."
sudo rm -f /usr/bin/nvim /usr/local/bin/nvim /bin/nvim
sudo rm -rf "$INSTALL_DIR" "$EXTRACTED_DIR"

echo "Extracting Neovim..."
sudo tar -xzf "$ARCHIVE" -C /opt
sudo mv "$EXTRACTED_DIR" "$INSTALL_DIR"

echo "Creating relative symlink in /usr/local/bin..."
REL_PATH=$(realpath --relative-to=/usr/local/bin "$INSTALL_DIR/bin/nvim")
sudo ln -sf "$REL_PATH" "$SYMLINK"

echo "Cleaning up Neovim archive..."
rm -f "$ARCHIVE"

##### 7. Install Nerd Fonts #####
FONT_LIST=(
    FiraCode
    JetBrainsMono
)
FONT_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
mkdir -p "$HOME/.local/share/fonts"

for FONT in "${FONT_LIST[@]}"; do
    FONT_ZIP="${FONT}.zip"
    FONT_URL="${FONT_BASE_URL}/${FONT}.zip"
    FONT_DIR="$HOME/.local/share/fonts/${FONT}"

    echo "Downloading ${FONT} Nerd Font..."
    if curl -LO "$FONT_URL"; then
        echo "Creating font directory at $FONT_DIR ..."
        mkdir -p "$FONT_DIR"
        echo "Extracting fonts..."
        unzip -o "$FONT_ZIP" -d "$FONT_DIR"
        echo "Cleaning up zip..."
        rm -f "$FONT_ZIP"
    else
        echo "Warning: Could not download ${FONT} font from $FONT_URL, skipping."
    fi
done

echo "Updating font cache for user..."
fc-cache -fv "$HOME/.local/share/fonts"

echo "All requested Nerd Fonts installed to $HOME/.local/share/fonts"

echo "NeoVim Theme Added"
git clone https://github.com/LazyVim/starter ~/.config/nvim

echo "NeoVim Installtion Complated"

#!/bin/bash

PLUGIN_DIR="$HOME/.config/nvim/lua/plugins"
SEARCH_FILE="$PLUGIN_DIR/search.lua"

# Create the plugins directory if it doesn't exist
mkdir -p "$PLUGIN_DIR"

# Write the Lua plugin config
cat > "$SEARCH_FILE" <<'EOF'
return {
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "ibhagwan/fzf-lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
}
EOF

echo "✅ Created $SEARCH_FILE with Telescope + fzf-lua config."

# Run Lazy sync in headless mode
echo "📦 Installing plugins..."
nvim --headless "+Lazy! sync" +qa

echo "✅ Plugins installed. You can now use :Telescope colorscheme or :FzfLua colorschemes."



##### 8. Final Output #####
echo "Neovim and all CLI tools installed successfully!"
nvim --version

echo "Setup complete! Start nvim"
