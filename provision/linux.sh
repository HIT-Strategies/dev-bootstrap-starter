#!/usr/bin/env bash
set -euo pipefail

# Detect WSL vs native Ubuntu
IS_WSL=0
grep -qi microsoft /proc/version && IS_WSL=1

echo "[Linux] Updating apt…"
sudo apt-get update -y
sudo apt-get install -y curl git build-essential ca-certificates

# --- neovim ---
if ! command -v nvim >/dev/null 2>&1; then
  echo "[Linux] Installing Neovim…"
  sudo apt-get install -y neovim
fi

# --- tmux ---
if ! command -v tmux >/dev/null 2>&1; then
  echo "[Linux] Installing tmux…"
  sudo apt-get install -y tmux
fi

# --- asdf prerequisites ---
sudo apt-get install -y unzip libssl-dev zlib1g-dev

# --- asdf ---
if ! command -v asdf >/dev/null 2>&1; then
  echo "[Linux] Installing asdf…"
  # Install to $HOME/.asdf (official)
  if [ ! -d "${HOME}/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf"
    cd "${HOME}/.asdf"
    git checkout "$(git describe --abbrev=0 --tags)"
  fi
  # Shell integration (zsh OR bash)
  if [ -n "${ZSH_VERSION-}" ]; then
    RC="${HOME}/.zshrc"
  else
    RC="${HOME}/.bashrc"
  fi
  if ! grep -q 'asdf.sh' "$RC"; then
    {
      echo ''
      echo '# asdf version manager'
      echo '. "$HOME/.asdf/asdf.sh"'
      echo '. "$HOME/.asdf/completions/asdf.bash"'
    } >> "$RC"
  fi
  # Load asdf now for this session
  . "${HOME}/.asdf/asdf.sh"
fi

# --- asdf plugins from .tool-versions (if present) ---
if [ -f "${HOME}/.tool-versions" ]; then
  echo "[Linux] Installing asdf plugins from .tool-versions…"
  asdf plugin list || true
  awk '{print $1}' "${HOME}/.tool-versions" | while read -r plugin; do
    asdf plugin add "$plugin" || true
  done
  asdf install
  
  # Install Go development tools after Go is available
  if command -v go >/dev/null 2>&1; then
    echo "[Linux] Installing Go development tools…"
    
    # Install delve debugger
    if ! command -v dlv >/dev/null 2>&1; then
      echo "[Linux] Installing delve (Go debugger)…"
      go install github.com/go-delve/delve/cmd/dlv@latest
      asdf reshim golang || true
    fi
    
    # Verify tools are available
    echo "[Linux] Verifying Go development tools…"
    if ! command -v golangci-lint >/dev/null 2>&1; then
      echo "[Linux] golangci-lint not found in PATH, may need to restart shell or run 'asdf reshim golang'"
    fi
    if ! command -v dlv >/dev/null 2>&1; then
      echo "[Linux] delve (dlv) not found in PATH, may need to restart shell or run 'asdf reshim golang'"
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

# --- Docker ---
if ! command -v docker >/dev/null 2>&1; then
  echo "[Linux] Installing Docker Engine…"
  # Official Docker Engine install (Ubuntu)
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
  sudo apt-get install -y apt-transport-https gnupg lsb-release
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo         "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu         $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Post-install: allow running docker without sudo
  if ! getent group docker >/dev/null; then
    sudo groupadd docker
  fi
  sudo usermod -aG docker "$USER"
  echo "[Linux] You may need to log out/in (or restart WSL) for docker group to take effect."
fi

# WSL note: prefer Docker Desktop on Windows + enable WSL integration
if [ "$IS_WSL" -eq 1 ]; then
  echo "[WSL] Tip: Using Docker Desktop for Windows with WSL integration is recommended."
fi

# --- GitHub CLI ---
if ! command -v gh >/dev/null 2>&1; then
  echo "[Linux] Installing GitHub CLI…"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
fi

# --- Azure CLI ---
if ! command -v az >/dev/null 2>&1; then
  echo "[Linux] Installing Azure CLI…"
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# --- pnpm (if Node.js is available) ---
if command -v node >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
  echo "[Linux] Installing pnpm…"
  npm install -g pnpm
fi

# --- Claude Code CLI (if pnpm is available) ---
if command -v pnpm >/dev/null 2>&1 && ! command -v claude >/dev/null 2>&1; then
  echo "[Linux] Installing Claude Code CLI…"
  pnpm install -g @anthropic-ai/claude-code
fi

# --- oh-my-zsh (optional) ---
if [ "${INSTALL_OHMYZSH:-}" = "1" ]; then
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo "[Linux] Installing oh-my-zsh…"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "[Linux] oh-my-zsh installed. Consider switching to zsh with 'chsh -s \$(which zsh)'"
  else
    echo "[Linux] oh-my-zsh already installed."
  fi
fi

# --- Personal configurations (optional) ---
if [ "${PERSONAL_CONFIG:-}" = "1" ]; then
  PERSONAL_SCRIPT="$(dirname "$0")/personal/linux.sh"
  if [ -f "$PERSONAL_SCRIPT" ]; then
    echo "[Linux] Running personal configurations..."
    bash "$PERSONAL_SCRIPT"
  else
    echo "[Linux] Personal configuration script not found at $PERSONAL_SCRIPT"
  fi
fi

echo "[Linux] Done."
