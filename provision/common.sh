#!/usr/bin/env bash
set -euo pipefail

# Common utility functions for provisioning scripts

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install a tool if it's missing
install_if_missing() {
  local tool="$1"
  local install_cmd="$2"
  local platform_prefix="$3"
  
  if ! command_exists "$tool"; then
    echo "[$platform_prefix] Installing $tool..."
    eval "$install_cmd"
  fi
}

# Configure Git defaults (idempotent)
configure_git_defaults() {
  # Create global .gitignore if it doesn't exist
  if [ ! -f "${HOME}/.gitignore_global" ]; then
    touch "${HOME}/.gitignore_global"
  fi
  git config --global init.defaultBranch main
  git config --global core.excludesfile "${HOME}/.gitignore_global"
  git config --global pull.rebase false
}

# Install asdf plugins from .tool-versions file
install_asdf_plugins() {
  local platform_prefix="$1"
  
  if [ -f "${HOME}/.tool-versions" ]; then
    echo "[$platform_prefix] Installing asdf plugins from .tool-versions…"
    asdf plugin list || true
    awk '{print $1}' "${HOME}/.tool-versions" | while read -r plugin; do
      asdf plugin add "$plugin" || true
    done
    asdf install
  fi
}

# Install Go development tools after Go is available
install_go_dev_tools() {
  local platform_prefix="$1"
  
  if command_exists go; then
    echo "[$platform_prefix] Installing Go development tools…"
    
    # Install delve debugger
    if ! command_exists dlv; then
      echo "[$platform_prefix] Installing delve (Go debugger)…"
      go install github.com/go-delve/delve/cmd/dlv@latest
      asdf reshim golang || true
    fi
    
    # Verify tools are available
    echo "[$platform_prefix] Verifying Go development tools…"
    if ! command_exists golangci-lint; then
      echo "[$platform_prefix] golangci-lint not found in PATH, may need to restart shell or run 'asdf reshim golang'"
    fi
    if ! command_exists dlv; then
      echo "[$platform_prefix] delve (dlv) not found in PATH, may need to restart shell or run 'asdf reshim golang'"
    fi
  fi
}

# Install Node.js ecosystem tools
install_node_tools() {
  local platform_prefix="$1"
  
  # pnpm (if Node.js is available)
  if command_exists node && ! command_exists pnpm; then
    echo "[$platform_prefix] Installing pnpm…"
    npm install -g pnpm
  fi
  
  # Claude Code CLI (if pnpm is available)
  if command_exists pnpm && ! command_exists claude; then
    echo "[$platform_prefix] Installing Claude Code CLI…"
    pnpm install -g @anthropic-ai/claude-code
  fi
}

# Install oh-my-zsh and automatically switch to zsh
install_oh_my_zsh() {
  local platform_prefix="$1"
  
  if [ "${INSTALL_OHMYZSH:-}" = "1" ]; then
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
      echo "[$platform_prefix] Installing oh-my-zsh…"
      sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      echo "[$platform_prefix] oh-my-zsh installed. Switching to zsh as default shell..."
      
      # Change default shell to zsh if not already set
      if [ "${SHELL}" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        echo "[$platform_prefix] Default shell changed to zsh. Please restart your terminal or run 'exec zsh' to use the new shell."
      else
        echo "[$platform_prefix] zsh is already the default shell."
      fi
    else
      echo "[$platform_prefix] oh-my-zsh already installed."
    fi
  fi
}

# Execute personal configuration script if requested
run_personal_config() {
  local platform_prefix="$1"
  local personal_script="$2"
  
  if [ "${PERSONAL_CONFIG:-}" = "1" ]; then
    if [ -f "$personal_script" ]; then
      echo "[$platform_prefix] Running personal configurations..."
      bash "$personal_script"
    else
      echo "[$platform_prefix] Personal configuration script not found at $personal_script"
    fi
  fi
}