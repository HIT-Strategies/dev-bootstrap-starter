# dev-bootstrap-starter

Minimal, idempotent dev environment bootstrap for macOS and Linux.
v1 installs:
- asdf (and installs plugins from `~/.tool-versions` if present)
- basic Git defaults
- Docker (Desktop on macOS; Engine on Linux)
- GitHub CLI
- Azure CLI
- oh-my-zsh (optional)

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
