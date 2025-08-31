#!/usr/bin/env bash
set -euo pipefail

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
if [ -f "${HOME}/.tool-versions" ]; then
  echo "[macOS] Installing asdf plugins from .tool-versions…"
  asdf plugin list || true
  awk '{print $1}' "${HOME}/.tool-versions" | while read -r plugin; do
    asdf plugin add "$plugin" || true
  done
  asdf install
fi

# --- Git defaults (idempotent) ---
# Create global .gitignore if it doesn't exist
if [ ! -f "${HOME}/.gitignore_global" ]; then
  touch "${HOME}/.gitignore_global"
fi
git config --global init.defaultBranch main
git config --global core.excludesfile "${HOME}/.gitignore_global"
git config --global pull.rebase false

# --- Docker Desktop ---
if ! command -v docker >/dev/null 2>&1; then
  echo "[macOS] Installing Docker Desktop…"
  brew install --cask docker
  echo "[macOS] Launch Docker.app from /Applications on first run."
fi

echo "[macOS] Done."
