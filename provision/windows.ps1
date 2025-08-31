# Run in an elevated PowerShell (Admin)
Set-ExecutionPolicy Bypass -Scope Process -Force

# --- winget available? ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "[Windows] winget not found. Please install App Installer from Microsoft Store, then re-run."
  exit 1
}

# --- git ---
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
  winget install --id Git.Git -e --source winget
}

# --- asdf (Windows port via Scoop) ---
if (-not (Test-Path "$env:USERPROFILE\.asdf\asdf.ps1")) {
  Write-Host "[Windows] Installing asdf (windows)…"
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    iwr get.scoop.sh -UseBasicParsing | iex
  }
  scoop install git
  scoop bucket add extras
  scoop install asdf
}

# Ensure asdf is loaded in PowerShell profile
$ProfilePath = $PROFILE
if (-not (Test-Path $ProfilePath)) {
  $ProfileDir = Split-Path -Path $ProfilePath -Parent
  if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
  }
  New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}
$asdfLine = 'if (Test-Path "$env:USERPROFILE\.asdf\asdf.ps1") { . "$env:USERPROFILE\.asdf\asdf.ps1" }'
if (-not (Select-String -Path $ProfilePath -Pattern '\.asdf\\asdf\.ps1' -Quiet)) {
  Add-Content -Path $ProfilePath -Value "`n# asdf version manager`n$asdfLine"
}

# --- Docker Desktop ---
if (-not (Get-Command docker.exe -ErrorAction SilentlyContinue)) {
  winget install --id Docker.DockerDesktop -e --source winget
  Write-Host "[Windows] Docker Desktop installed. Launch it once to finish setup."
}

# --- Git defaults (idempotent) ---
# Create global .gitignore if it doesn't exist
$GitIgnoreGlobal = "$env:USERPROFILE\.gitignore_global"
if (-not (Test-Path $GitIgnoreGlobal)) {
  New-Item -ItemType File -Path $GitIgnoreGlobal -Force | Out-Null
}
git config --global init.defaultBranch main
git config --global core.excludesfile "$env:USERPROFILE\.gitignore_global"
git config --global pull.rebase false

Write-Host "[Windows] Done."
