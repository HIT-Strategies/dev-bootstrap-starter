# dev-bootstrap-starter

Minimal, idempotent dev environment bootstrap for macOS, Ubuntu/WSL, and Windows.
v1 installs:
- asdf (and installs plugins from `~/.tool-versions` if present)
- basic Git defaults
- Docker (Desktop on macOS/Windows; Engine on Ubuntu/WSL)

## Quick start

### macOS
```bash
chmod +x provision/macos.sh
./provision/macos.sh
```

### Ubuntu / WSL
```bash
chmod +x provision/ubuntu_wsl.sh
./provision/ubuntu_wsl.sh
```

### Windows (PowerShell as Administrator)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\provision\windows.ps1
```

## Optional
- Put a `.tool-versions` in your `$HOME` to let asdf auto-install your toolchains.
- Re-run these scripts any time; they are safe to re-run and will only install what's missing.
- Next steps (future versions): SSH key helper, direnv, chezmoi for dotfiles, VS Code/Neovim config, GitHub CLI auth.
```
