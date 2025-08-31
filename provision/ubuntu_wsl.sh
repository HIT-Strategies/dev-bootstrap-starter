#!/usr/bin/env bash
set -euo pipefail

# Detect WSL vs native Ubuntu
IS_WSL=0
grep -qi microsoft /proc/version && IS_WSL=1

echo "[Linux] Updating apt…"
sudo apt-get update -y
sudo apt-get install -y curl git build-essential ca-certificates

# --- asdf prerequisites ---
sudo apt-get install -y unzip libssl-dev zlib1g-dev

# --- asdf ---
if ! command -v asdf >/dev/null 2>&1; then
  echo "[Linux] Installing asdf…"
  # Install to $HOME/.asdf (official)
  if [ ! -d "${HOME}/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch v0.14.0
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
fi

# --- Git defaults (idempotent) ---
git config --global init.defaultBranch main
git config --global core.excludesfile "${HOME}/.gitignore_global"
git config --global pull.rebase false

# --- Docker ---
if ! command -v docker >/dev/null 2>&1; then
  echo "[Linux] Installing Docker Engine…"
  # Official Docker Engine install (Ubuntu)
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
  sudo apt-get install -y apt-transport-https gnupg lsb-release
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

echo "[Linux] Done."
