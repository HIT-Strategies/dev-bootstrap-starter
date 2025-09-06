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

# --- Docker via Colima ---
if ! command -v docker >/dev/null 2>&1; then
  echo "[macOS] Installing Docker via Colima…"
  brew install docker docker-compose
  brew install colima
  
  # Ensure clean Docker config for Colima (remove Docker Desktop credential store)
  mkdir -p "${HOME}/.docker"
  if [ -f "${HOME}/.docker/config.json" ] && grep -q '"credsStore": "desktop"' "${HOME}/.docker/config.json"; then
    echo "[macOS] Removing Docker Desktop credential store from config..."
    sed -i '' '/"credsStore": "desktop"/d' "${HOME}/.docker/config.json"
  fi
  
  echo "[macOS] Docker installed. Start with 'colima start' then use 'docker' and 'docker-compose' commands normally."
  echo "[macOS] Colima provides a lightweight Docker runtime without Docker Desktop."
elif ! command -v colima >/dev/null 2>&1; then
  echo "[macOS] Installing Colima (Docker already present)…"
  brew install colima
  
  # Clean up Docker Desktop credential store when switching to Colima
  if [ -f "${HOME}/.docker/config.json" ] && grep -q '"credsStore": "desktop"' "${HOME}/.docker/config.json"; then
    echo "[macOS] Removing Docker Desktop credential store from config..."
    sed -i '' '/"credsStore": "desktop"/d' "${HOME}/.docker/config.json"
  fi
  
  echo "[macOS] Colima installed. You can switch from Docker Desktop by stopping it and running 'colima start'."
fi

# --- Docker Compose (if Docker exists but Compose doesn't) ---
if command -v docker >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
  echo "[macOS] Installing docker-compose…"
  brew install docker-compose
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
