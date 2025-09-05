#!/usr/bin/env bash
set -euo pipefail

PLATFORM_PREFIX="${1:-Personal}"
echo "[$PLATFORM_PREFIX] Starting personal configurations..."

# --- NeoVim Go language server (gopls) ---
if command -v go >/dev/null 2>&1 && ! command -v gopls >/dev/null 2>&1; then
  echo "[$PLATFORM_PREFIX] Installing gopls (Go language server)..."
  go install golang.org/x/tools/gopls@latest
  asdf reshim golang || true
fi

# --- Additional Go development tools ---
if command -v go >/dev/null 2>&1; then
  echo "[$PLATFORM_PREFIX] Installing additional Go development tools..."
  
  # gofumpt - stricter gofmt
  if ! command -v gofumpt >/dev/null 2>&1; then
    echo "[$PLATFORM_PREFIX] Installing gofumpt..."
    go install mvdan.cc/gofumpt@latest
    asdf reshim golang || true
  fi
  
  # staticcheck - static analysis
  if ! command -v staticcheck >/dev/null 2>&1; then
    echo "[$PLATFORM_PREFIX] Installing staticcheck..."
    go install honnef.co/go/tools/cmd/staticcheck@latest
    asdf reshim golang || true
  fi
fi

# --- NeoVim configuration ---
NVIM_CONFIG_DIR="${HOME}/.config/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  echo "[$PLATFORM_PREFIX] Creating NeoVim config directory..."
  mkdir -p "$NVIM_CONFIG_DIR"
fi

# Create basic init.lua if it doesn't exist
if [ ! -f "$NVIM_CONFIG_DIR/init.lua" ]; then
  echo "[$PLATFORM_PREFIX] Creating basic NeoVim configuration..."
  cat > "$NVIM_CONFIG_DIR/init.lua" << 'EOF'
-- Basic NeoVim configuration
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true

-- Leader key
vim.g.mapleader = " "

-- Enable built-in file explorer (netrw) with tree-style listing
vim.g.netrw_liststyle = 3  -- Tree style
vim.g.netrw_banner = 0     -- Disable banner
vim.g.netrw_browse_split = 4  -- Open in previous window
vim.g.netrw_altv = 1       -- Open splits to the right
vim.g.netrw_winsize = 25   -- 25% of the screen for netrw

-- Basic keymaps
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { desc = "File explorer" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Go-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false
  end,
})
EOF
fi

# --- Tmux configuration ---
if command -v tmux >/dev/null 2>&1 && [ ! -f "${HOME}/.tmux.conf" ]; then
  echo "[$PLATFORM_PREFIX] Creating basic tmux configuration..."
  cat > "${HOME}/.tmux.conf" << 'EOF'
# Basic tmux configuration
set -g default-terminal "screen-256color"
set -g mouse on

# Prefix key
set -g prefix C-b
unbind C-a
bind C-b send-prefix

# Pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Window splitting
bind | split-window -h
bind - split-window -v

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
EOF
fi

# --- Git personal configurations ---
echo "[$PLATFORM_PREFIX] Setting up personal git configurations..."
git config --global push.default current
git config --global merge.conflictstyle diff3
git config --global rerere.enabled true

echo "[$PLATFORM_PREFIX] Personal configurations completed."