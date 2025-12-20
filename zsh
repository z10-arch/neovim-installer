#!/usr/bin/env sh
set -eu

echo "==> Bootstrapping zsh environment"

# Detect OS
OS="$(uname -s)"

# ----------------------------
# Install zsh
# ----------------------------
if ! command -v zsh >/dev/null 2>&1; then
  echo "==> Installing zsh"
  case "$OS" in
    Darwin)
      brew install zsh
      ;;
    Linux)
      if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y zsh curl git
      else
        echo "Unsupported Linux distro (need apt)"
        exit 1
      fi
      ;;
    *)
      echo "Unsupported OS"
      exit 1
      ;;
  esac
fi

# ----------------------------
# Set zsh as default shell
# ----------------------------
ZSH_PATH="$(command -v zsh)"

if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "==> Setting zsh as default shell"
  if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "$ZSH_PATH"
fi

# ----------------------------
# Install Antidote
# ----------------------------
if [ ! -d "$HOME/.antidote" ]; then
  echo "==> Installing Antidote"
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi

# ----------------------------
# Install fzf (required for fzf-tab)
# ----------------------------
if ! command -v fzf >/dev/null 2>&1; then
  echo "==> Installing fzf"
  case "$OS" in
    Darwin)
      brew install fzf
      ;;
    Linux)
      sudo apt install -y fzf
      ;;
  esac
fi

# ----------------------------
# Install starship
# ----------------------------
if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ----------------------------
# Write plugin list
# ----------------------------
echo "==> Writing plugin list"
cat > "$HOME/.zsh_plugins.txt" <<'EOF'
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-completions
EOF

# ----------------------------
# Write .zshrc (idempotent)
# ----------------------------
echo "==> Writing .zshrc"
cat > "$HOME/.zshrc" <<'EOF'
# ---- Antidote ----
source "$HOME/.antidote/antidote.zsh"
antidote load

# ---- Starship ----
eval "$(starship init zsh)"

# ---- Basic defaults ----
export EDITOR=vim
export PAGER=less
EOF

echo "==> Done"
echo "Restart your terminal or log out to start using zsh"
