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

## Optional
- Put a `.tool-versions` in your `$HOME` to let asdf auto-install your toolchains.
- Re-run these scripts any time; they are safe to re-run and will only install what's missing.
- Next steps (future versions): SSH key helper, direnv, chezmoi for dotfiles, VS Code/Neovim config, GitHub CLI auth.
```
