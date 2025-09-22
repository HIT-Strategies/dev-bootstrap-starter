#!/usr/bin/env bash
set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

# Configuration variables
ASDF_VERSION="${ASDF_VERSION:-v0.18.0}"

# Detect WSL vs native Ubuntu
IS_WSL=0
grep -qi microsoft /proc/version && IS_WSL=1

echo "[Linux] Updating apt…"
sudo apt-get update -y
sudo apt-get install -y curl git build-essential ca-certificates make

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

# Additional dependencies for specific asdf plugins
echo "[Linux] Installing additional dependencies for asdf plugins…"
# For Node.js
sudo apt-get install -y dirmngr gpg
# For Golang builds
sudo apt-get install -y pkg-config
# For Terraform (typically works out of the box)

# --- asdf ---
if ! command -v asdf >/dev/null 2>&1; then
  echo "[Linux] Installing asdf ${ASDF_VERSION}…"

  # Remove any existing installation
  rm -rf "${HOME}/.asdf"

  # For WSL/Windows, install from source with build dependencies
  if [ "$IS_WSL" -eq 1 ]; then
    echo "[WSL] Installing asdf from source for better Windows/WSL compatibility…"

    # Ensure git is available
    if ! command -v git >/dev/null 2>&1; then
      echo "[WSL] Installing git (required for asdf source installation)…"
      sudo apt-get install -y git
    fi

    # Check if Go is needed for building asdf and install temporarily if necessary
    TEMP_GO_INSTALLED=0
    if ! command -v go >/dev/null 2>&1; then
      echo "[WSL] Installing Go temporarily for asdf build…"
      sudo apt-get install -y golang-go
      TEMP_GO_INSTALLED=1
    fi

    # Clone and checkout specific version
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch "${ASDF_VERSION}"

    # Build asdf from source
    cd "${HOME}/.asdf"
    make build

    # Copy the binary to a directory in PATH
    sudo mkdir -p /usr/local/bin
    sudo cp asdf /usr/local/bin/asdf
    sudo chmod +x /usr/local/bin/asdf

    # Verify the binary is in PATH
    if command -v asdf >/dev/null 2>&1; then
      echo "[WSL] asdf binary successfully installed to /usr/local/bin"
    else
      echo "[WSL] Warning: asdf binary not found in PATH after installation"
    fi
    cd -

    # Clean up temporary Go installation if we installed it
    if [ "$TEMP_GO_INSTALLED" -eq 1 ]; then
      echo "[WSL] Removing temporary Go installation (will be managed by asdf)…"
      sudo apt-get remove -y golang-go
      sudo apt-get autoremove -y
    fi
  else
    # Regular Linux installation (non-WSL)
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch "${ASDF_VERSION}"
  fi

  # Shell integration (zsh OR bash)
  if [ -n "${ZSH_VERSION-}" ]; then
    RC="${HOME}/.zshrc"
  else
    RC="${HOME}/.bashrc"
  fi

  # Remove any existing asdf lines first
  if [ -f "$RC" ]; then
    sed -i '/asdf/d' "$RC"
  fi

  # Add fresh asdf configuration
  {
    echo ''
    echo '# asdf version manager'
    echo '. "$HOME/.asdf/asdf.sh"'
    if [ -n "${ZSH_VERSION-}" ]; then
      echo 'fpath=(${ASDF_DIR}/completions $fpath)'
      echo 'autoload -Uz compinit && compinit'
    else
      echo '. "$HOME/.asdf/completions/asdf.bash"'
    fi
  } >> "$RC"

  # Load asdf now for this session
  . "${HOME}/.asdf/asdf.sh"

  echo "[Linux] asdf ${ASDF_VERSION} installed successfully"
fi

# --- asdf plugins from .tool-versions (if present) ---
install_asdf_plugins "Linux"

# Install Go development tools after Go is available
install_go_dev_tools "Linux"

# --- Git defaults (idempotent) ---
configure_git_defaults

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

# --- Node.js ecosystem tools ---
install_node_tools "Linux"

# --- oh-my-zsh (optional) ---
install_oh_my_zsh "Linux"

# --- Personal configurations (optional) ---
run_personal_config "Linux" "$(dirname "$0")/personal/linux.sh"

echo "[Linux] Done."
