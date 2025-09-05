# dev-bootstrap-starter

Comprehensive dev environment bootstrap for macOS and Linux with GitHub onboarding wizard.

## Core Tools Installed
- **asdf** - Version manager (installs plugins from `~/.tool-versions` if present)
- **Git** - Version control with sensible defaults
- **NeoVim** - Modern text editor
- **tmux** - Terminal multiplexer
- **Docker** - Container platform (Desktop on macOS; Engine on Linux)
- **GitHub CLI** - GitHub command-line interface
- **Azure CLI** - Azure command-line interface  
- **pnpm** - Fast Node.js package manager (if Node.js available)
- **Claude Code CLI** - AI coding assistant (via pnpm)
- **oh-my-zsh** - Enhanced shell (optional)

## Personal Development Tools (Optional)
- **gopls** - Go language server for NeoVim
- **gofumpt** - Stricter Go formatter
- **staticcheck** - Go static analysis tool
- Basic **NeoVim configuration** with Go support
- Basic **tmux configuration** 
- Enhanced **Git configurations**

## Prerequisites

**All platforms:**
- Internet connection
- Terminal/shell access
- `curl` available (usually pre-installed)

**Windows users:**
- WSL (Windows Subsystem for Linux) must be installed first

**Getting this bootstrap on a fresh machine:**
1. **If git is available:** `git clone https://github.com/HIT-Strategies/dev-bootstrap-starter.git`
2. **If git is not available:** Download the zip file from GitHub and extract it
3. **One-liner option:** `curl -fsSL https://raw.githubusercontent.com/HIT-Strategies/dev-bootstrap-starter/main/provision/linux.sh | bash` (Linux/WSL only)

## Fresh Windows Setup (WSL)

If you're on a brand new Windows machine:

1. **Install WSL** (run as Administrator in PowerShell):
   ```powershell
   wsl --install
   ```

2. **Restart your computer** when prompted

3. **Complete Ubuntu setup** (create username/password when prompted)

4. **IMPORTANT - Work from Linux filesystem:**
   ```bash
   cd ~  # Navigate to /home/username, NOT /mnt/c/...
   pwd   # Should show /home/yourusername
   ```

5. **Follow the Linux instructions below** (make sure you're in your Linux home directory)

## Quick Start

### Step 1: Install Core Tools

**macOS:**
```bash
chmod +x provision/macos.sh
./provision/macos.sh
```

**Linux:**
```bash
chmod +x provision/linux.sh
./provision/linux.sh
```

**With optional features:**
```bash
# Install oh-my-zsh
INSTALL_OHMYZSH=1 ./provision/macos.sh

# Install personal configurations (NeoVim, tmux, Go tools)
PERSONAL_CONFIG=1 ./provision/macos.sh

# Install both
INSTALL_OHMYZSH=1 PERSONAL_CONFIG=1 ./provision/macos.sh
```

### Step 2: GitHub Setup (Interactive Wizard)
```bash
./scripts/github-setup.sh
```
This wizard will:
- Configure Git user information
- Generate and set up SSH keys
- Add SSH key to GitHub account
- Set up GPG signing for verified commits (optional)
- Test GitHub connectivity

### Step 3: Clone Company Repository
```bash
./scripts/repo-clone.sh
```
This script will:
- Clone your company repository
- Set up the local development environment
- Install project dependencies
- Run tests to verify setup

### Windows (WSL)
Windows users should use WSL and follow the Linux instructions above.

**⚠️ WSL Important:** Always run from your Linux home directory (`/home/username`), never from Windows filesystem paths (`/mnt/c/...`).

## Manual Steps (if needed)

The GitHub setup wizard handles most authentication, but you may need:

### Authenticate Additional CLI Tools
```bash
# Azure CLI (if you use Azure)
az login

# Claude Code CLI
claude auth
```

### Create Your .tool-versions File
Create `~/.tool-versions` with your preferred language versions:
```
nodejs 20.11.0
python 3.12.1
golang 1.21.6
terraform 1.6.6
```

## Advanced Usage

### Personal Configuration Details
When using `PERSONAL_CONFIG=1`, the following are configured:
- **NeoVim**: Basic configuration with Go-specific settings
- **tmux**: Enhanced configuration with better key bindings
- **Go tools**: gopls, gofumpt, staticcheck for development
- **Git**: Additional productivity settings

### Directory Structure
```
dev-bootstrap-starter/
├── provision/
│   ├── macos.sh              # Core macOS setup
│   ├── linux.sh              # Core Linux setup
│   └── personal/
│       ├── macos.sh          # Personal macOS configurations
│       └── linux.sh          # Personal Linux configurations
└── scripts/
    ├── github-setup.sh       # GitHub authentication wizard
    └── repo-clone.sh         # Repository cloning and setup
```

### Customizing Personal Configurations
To customize the personal configurations:
1. Edit `provision/personal/macos.sh` or `provision/personal/linux.sh`
2. Add your preferred NeoVim plugins, tmux settings, or additional tools
3. Re-run with `PERSONAL_CONFIG=1` to apply changes

## Optional
- Re-run these scripts any time; they are safe to re-run and will only install what's missing.
- Future versions may include: direnv, chezmoi for dotfiles, VS Code/Neovim config.
```
