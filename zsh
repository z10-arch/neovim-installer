#!/usr/bin/env sh
set -eu

echo "==> Zsh bootstrap starting"

# ----------------------------
# OS check (Linux + apt)
# ----------------------------
if ! command -v apt >/dev/null 2>&1; then
  echo "This script currently supports apt-based systems only"
  exit 1
fi

# ----------------------------
# Base packages
# ----------------------------
echo "==> Installing base packages"
sudo apt update
sudo apt install -y \
  zsh \
  git \
  curl \
  fzf \
  bat \
  eza \
  locales

# ----------------------------
# Set locale
# ----------------------------
sudo locale-gen en_US.UTF-8

# ----------------------------
# Set zsh as default shell
# ----------------------------
ZSH_PATH="$(command -v zsh)"

if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "==> Registering zsh shell"
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "==> Setting zsh as default shell"
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
# Install Starship
# ----------------------------
if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing Starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ----------------------------
# Plugin list
# ----------------------------
echo "==> Writing plugin list"
cat > "$HOME/.zsh_plugins.txt" <<'EOF'
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-completions
EOF

# ----------------------------
# .zshrc
# ----------------------------
echo "==> Writing .zshrc"
cat > "$HOME/.zshrc" <<'EOF'
# ==================================================
# Zsh – clean, fast, no framework
# ==================================================

# Antidote
if [ -f "$HOME/.antidote/antidote.zsh" ]; then
  source "$HOME/.antidote/antidote.zsh"
  antidote load
fi

# Completion
autoload -Uz compinit
compinit -d "$HOME/.zcompdump"

# Starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

# Keybindings
bindkey -e

# Environment
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# PATH
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Behavior
setopt AUTO_CD CORRECT INTERACTIVE_COMMENTS NO_BEEP EXTENDED_GLOB PROMPT_SUBST

# Aliases
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -l --icons --git"
  alias la="eza -la --icons"
else
  alias ll="ls -lh"
  alias la="ls -la"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
fi

# Safety
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# DevOps
alias k="kubectl"
alias tf="terraform"
alias tg="terragrunt"
alias d="docker"
alias dc="docker compose"

# FZF
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi
EOF

echo "==> Bootstrap complete"
echo "Log out and back in, or run: exec zsh"
