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
if [ -f "${HOME}/.tool-versions" ]; then
  echo "[macOS] Installing asdf plugins from .tool-versions…"
  asdf plugin list || true
  awk '{print $1}' "${HOME}/.tool-versions" | while read -r plugin; do
    asdf plugin add "$plugin" || true
  done
  asdf install
  
  # Install Go development tools after Go is available
  if command -v go >/dev/null 2>&1; then
    echo "[macOS] Installing Go development tools…"
    
    # Install delve debugger
    if ! command -v dlv >/dev/null 2>&1; then
      echo "[macOS] Installing delve (Go debugger)…"
      go install github.com/go-delve/delve/cmd/dlv@latest
      asdf reshim golang || true
    fi
    
    # Verify tools are available
    echo "[macOS] Verifying Go development tools…"
    if ! command -v golangci-lint >/dev/null 2>&1; then
      echo "[macOS] golangci-lint not found in PATH, may need to restart shell or run 'asdf reshim golang'"
    fi
    if ! command -v dlv >/dev/null 2>&1; then
      echo "[macOS] delve (dlv) not found in PATH, may need to restart shell or run 'asdf reshim golang'"
    fi
  fi
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

# --- pnpm (if Node.js is available) ---
if command -v node >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
  echo "[macOS] Installing pnpm…"
  npm install -g pnpm
fi

# --- Claude Code CLI (if pnpm is available) ---
if command -v pnpm >/dev/null 2>&1 && ! command -v claude >/dev/null 2>&1; then
  echo "[macOS] Installing Claude Code CLI…"
  pnpm install -g @anthropic-ai/claude-code
fi

# --- oh-my-zsh (optional) ---
if [ "${INSTALL_OHMYZSH:-}" = "1" ]; then
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo "[macOS] Installing oh-my-zsh…"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "[macOS] oh-my-zsh installed. Consider switching to zsh with 'chsh -s \$(which zsh)'"
  else
    echo "[macOS] oh-my-zsh already installed."
  fi
fi

# --- Personal configurations (optional) ---
if [ "${PERSONAL_CONFIG:-}" = "1" ]; then
  PERSONAL_SCRIPT="$(dirname "$0")/personal/macos.sh"
  if [ -f "$PERSONAL_SCRIPT" ]; then
    echo "[macOS] Running personal configurations..."
    bash "$PERSONAL_SCRIPT"
  else
    echo "[macOS] Personal configuration script not found at $PERSONAL_SCRIPT"
  fi
fi

echo "[macOS] Done."
