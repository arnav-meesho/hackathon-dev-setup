# Meesho Hackathon — Windows dev environment bootstrap
# Usage: setup.ps1 [-DryRun]
#   -DryRun  Print commands instead of executing them (used in CI)
#Requires -Version 5.1
[CmdletBinding()]
param([switch]$DryRun)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Elevation check ───────────────────────────────────────────────────────────
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[setup] Not running as Administrator — relaunching elevated..." -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" `
        -Verb RunAs
    exit
}

# ── Colour helpers ────────────────────────────────────────────────────────────
function Info { param([string]$Msg) Write-Host "  $Msg" -ForegroundColor Green }
function Step { param([string]$Msg) Write-Host "`n▶ $Msg" -ForegroundColor Green }
function Warn { param([string]$Msg) Write-Host "  [warn] $Msg" -ForegroundColor Yellow }

# Runs a command, or just prints it when -DryRun is set.
function Invoke-Step {
    param([string]$Label, [scriptblock]$Block)
    if ($DryRun) {
        Write-Host "  [dry-run] $Label" -ForegroundColor Cyan
    } else {
        & $Block
    }
}

# ── winget availability ───────────────────────────────────────────────────────
Step "Verifying winget is available"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[setup] winget not found. Install 'App Installer' from the Microsoft Store and re-run." -ForegroundColor Red
    exit 1
}
Info "winget found: $(winget --version)"

# ── Helper: install or skip a winget package ──────────────────────────────────
function Install-WingetPackage {
    param([string]$PackageId, [string]$DisplayName)
    Step "Installing $DisplayName"
    if ($DryRun) {
        Write-Host "  [dry-run] winget install --id $PackageId --exact --silent ..." -ForegroundColor Cyan
        return
    }
    $listed = winget list --id $PackageId --exact 2>&1
    if ($LASTEXITCODE -eq 0 -and ($listed -match [regex]::Escape($PackageId))) {
        Info "$DisplayName is already installed — skipping."
        return
    }
    winget install --id $PackageId --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Warn "$DisplayName install returned exit code $LASTEXITCODE (may need a reboot to take effect)."
    } else {
        Info "$DisplayName installed."
    }
}

# ── Git ───────────────────────────────────────────────────────────────────────
Install-WingetPackage -PackageId 'Git.Git' -DisplayName 'Git'

# ── mise ──────────────────────────────────────────────────────────────────────
Install-WingetPackage -PackageId 'jdx.mise' -DisplayName 'mise'

# Refresh PATH so mise is usable immediately.
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

# ── Node.js 24 and Go (global via mise) ───────────────────────────────────────
Step "Installing Node.js 24 via mise (global)"
Invoke-Step "mise use --global node@24" { mise use --global node@24 }
if (-not $DryRun) { Info "Node: $(mise exec node -- node --version)   npm: $(mise exec node -- npm --version)" }

Step "Installing Go via mise (global)"
Invoke-Step "mise use --global go@latest" { mise use --global go@latest }
if (-not $DryRun) { Info "Go: $(mise exec go -- go version)" }

# ── Wire mise into PowerShell profile ────────────────────────────────────────
Step "Configuring mise in PowerShell profile"
$activateLine = 'mise activate pwsh | Out-String | Invoke-Expression'
Invoke-Step "Add '$activateLine' to `$PROFILE" {
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    if (-not (Test-Path $PROFILE))    { New-Item -ItemType File      -Path $PROFILE    -Force | Out-Null }
    if (Select-String -Path $PROFILE -Pattern 'mise activate' -Quiet) {
        Info "mise activation already present in PowerShell profile — skipping."
    } else {
        Add-Content -Path $PROFILE -Value "`n# Added by hackathon-dev-setup`n$activateLine"
        Info "Added mise activation to $PROFILE"
    }
}

# ── Docker Desktop ────────────────────────────────────────────────────────────
Install-WingetPackage -PackageId 'Docker.DockerDesktop' -DisplayName 'Docker Desktop'

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Meesho Hackathon — Setup Complete                " -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed tools:" -ForegroundColor White

if ($DryRun) {
    Write-Host "  [dry-run] skipping version checks — nothing was installed" -ForegroundColor Cyan
} else {
    $checks = @(
        @{ Label = 'Git';    Cmd = 'git';  Args = '--version' },
        @{ Label = 'Node.js';Cmd = 'node'; Args = '--version' },
        @{ Label = 'npm';    Cmd = 'npm';  Args = '--version' },
        @{ Label = 'Go';     Cmd = 'go';   Args = 'version'   },
        @{ Label = 'mise';   Cmd = 'mise'; Args = '--version' }
    )
    foreach ($t in $checks) {
        $ver = & $t.Cmd $t.Args 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host ("    {0,-8}: {1}" -f $t.Label, $ver) -ForegroundColor Green
        } else {
            Warn "$($t.Label) not on PATH yet — open a new terminal after setup."
        }
    }
}

Write-Host ""
Write-Host "  Port reference:" -ForegroundColor White
Write-Host "    Frontend  ->  http://localhost:9080" -ForegroundColor Green
Write-Host "    Backend   ->  http://localhost:8090" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Launch Docker Desktop and complete first-run setup."
Write-Host "    2. Open a NEW terminal so mise activates in your shell."
Write-Host "    3. Configure Git with your GitHub credentials when prompted."
Write-Host ""
