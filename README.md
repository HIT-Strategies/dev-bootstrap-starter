# dev-bootstrap-starter

Minimal, idempotent dev environment bootstrap for macOS and Linux.
v1 installs:
- asdf (and installs plugins from `~/.tool-versions` if present)
- basic Git defaults
- Docker (Desktop on macOS; Engine on Linux)
- GitHub CLI
- Azure CLI
- pnpm (if Node.js is available via asdf)
- Claude Code CLI (via pnpm)
- oh-my-zsh (optional)

## Prerequisites

**All platforms:**
- Internet connection
- Terminal/shell access
- `curl` available (usually pre-installed)

**Windows users:**
- WSL (Windows Subsystem for Linux) must be installed first

**Getting this bootstrap on a fresh machine:**
1. **If git is available:** `git clone https://github.com/your-username/dev-bootstrap-starter.git`
2. **If git is not available:** Download the zip file from GitHub and extract it
3. **One-liner option:** `curl -fsSL https://raw.githubusercontent.com/your-username/dev-bootstrap-starter/main/provision/linux.sh | bash` (Linux/WSL only)

## Fresh Windows Setup (WSL)

If you're on a brand new Windows machine:

1. **Install WSL** (run as Administrator in PowerShell):
   ```powershell
   wsl --install
   ```

2. **Restart your computer** when prompted

3. **Complete Ubuntu setup** (create username/password when prompted)

4. **Follow the Linux instructions below**

## Quick start

### macOS
```bash
chmod +x provision/macos.sh
./provision/macos.sh
```

To also install oh-my-zsh:
```bash
INSTALL_OHMYZSH=1 ./provision/macos.sh
```

### Linux
```bash
chmod +x provision/linux.sh
./provision/linux.sh
```

To also install oh-my-zsh:
```bash
INSTALL_OHMYZSH=1 ./provision/linux.sh
```

### Windows (use WSL)
Windows users should use WSL (Windows Subsystem for Linux) and follow the Linux instructions above.

## Next Steps (Manual Setup)

After running the bootstrap, you'll need to set up your personal credentials and preferences:

### 1. SSH Keys for GitHub
```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard (macOS)
pbcopy < ~/.ssh/id_ed25519.pub

# Copy public key to clipboard (Linux)
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
```

Then add the public key to your GitHub account: **GitHub → Settings → SSH and GPG keys → New SSH key**

### 2. Authenticate CLI Tools
```bash
# GitHub CLI
gh auth login

# Azure CLI (if you use Azure)
az login

# Claude Code CLI
claude auth
```

### 3. Configure Git Identity
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Create Your .tool-versions File
Create `~/.tool-versions` with your preferred language versions:
```
nodejs 20.11.0
python 3.12.1
golang 1.21.6
terraform 1.6.6
```

## Optional
- Re-run these scripts any time; they are safe to re-run and will only install what's missing.
- Future versions may include: direnv, chezmoi for dotfiles, VS Code/Neovim config.
```
