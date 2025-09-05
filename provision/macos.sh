#!/usr/bin/env bash
set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  echo "[macOS] Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo "[macOS] Updating Homebrew…"
brew update

# --- git ---
if ! command -v git >/dev/null 2>&1; then
  echo "[macOS] Installing git…"
  brew install git
fi

# --- neovim ---
if ! command -v nvim >/dev/null 2>&1; then
  echo "[macOS] Installing Neovim…"
  brew install neovim
fi

# --- tmux ---
if ! command -v tmux >/dev/null 2>&1; then
  echo "[macOS] Installing tmux…"
  brew install tmux
fi

# --- asdf ---
if ! command -v asdf >/dev/null 2>&1; then
  echo "[macOS] Installing asdf…"
  brew install asdf
  # Ensure asdf is loaded for future shells
  if ! grep -q 'asdf.sh' "${HOME}/.zshrc" 2>/dev/null; then
    echo -e '\n# asdf version manager\n. $(brew --prefix)/opt/asdf/libexec/asdf.sh' >> "${HOME}/.zshrc"
  fi
  # Load asdf for current session
  . $(brew --prefix)/opt/asdf/libexec/asdf.sh
fi

# --- asdf plugins (optional; use .tool-versions if present) ---
install_asdf_plugins "macOS"

# Install Go development tools after Go is available
install_go_dev_tools "macOS"

# --- Git defaults (idempotent) ---
configure_git_defaults

# --- Docker Desktop ---
if ! command -v docker >/dev/null 2>&1; then
  echo "[macOS] Installing Docker Desktop…"
  brew install --cask docker
  echo "[macOS] Launch Docker.app from /Applications on first run."
fi

# --- GitHub CLI ---
if ! command -v gh >/dev/null 2>&1; then
  echo "[macOS] Installing GitHub CLI…"
  brew install gh
fi

# --- Azure CLI ---
if ! command -v az >/dev/null 2>&1; then
  echo "[macOS] Installing Azure CLI…"
  brew install azure-cli
fi

# --- Node.js ecosystem tools ---
install_node_tools "macOS"

# --- oh-my-zsh (optional) ---
install_oh_my_zsh "macOS"

# --- Personal configurations (optional) ---
run_personal_config "macOS" "$(dirname "$0")/personal/macos.sh"

echo "[macOS] Done."
