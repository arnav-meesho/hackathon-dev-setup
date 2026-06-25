#!/usr/bin/env bash
# Meesho Hackathon — macOS dev environment bootstrap
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

info() { echo -e "${GREEN}${BOLD}[setup]${RESET} $*"; }
step() { echo -e "\n${GREEN}${BOLD}▶ $*${RESET}"; }

# ── Sudo keep-alive ───────────────────────────────────────────────────────────
step "Requesting sudo privileges (needed for some installers)"
sudo -v
while true; do sudo -n true; sleep 55; kill -0 "$$" 2>/dev/null || exit; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ── Homebrew ──────────────────────────────────────────────────────────────────
step "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  info "Homebrew not found — installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  info "Homebrew installed."
else
  info "Homebrew already installed — updating..."
  brew update --quiet
fi

# ── Git ───────────────────────────────────────────────────────────────────────
step "Installing Git"
if brew list git &>/dev/null; then
  info "Git already installed: $(git --version)"
else
  brew install git
  info "Git installed: $(git --version)"
fi

# ── mise ──────────────────────────────────────────────────────────────────────
step "Installing mise"
if brew list mise &>/dev/null; then
  info "mise already installed: $(mise --version)"
else
  brew install mise
  info "mise installed: $(mise --version)"
fi

# Activate mise in shell rc files so it's available in every new terminal.
MISE_ACTIVATE_ZSH='eval "$(mise activate zsh)"'
MISE_ACTIVATE_BASH='eval "$(mise activate bash)"'

for RC_PAIR in "$HOME/.zshrc:$MISE_ACTIVATE_ZSH" "$HOME/.bashrc:$MISE_ACTIVATE_BASH"; do
  RC="${RC_PAIR%%:*}"
  LINE="${RC_PAIR#*:}"
  if [[ -f "$RC" ]] && grep -qF 'mise activate' "$RC"; then
    info "mise activation already present in $RC — skipping."
  else
    {
      echo ""
      echo "# Added by hackathon-dev-setup"
      echo "$LINE"
    } >> "$RC"
    info "Added mise activation to $RC"
  fi
done

# Activate mise for the rest of this script.
eval "$(mise activate bash --shims)"

# ── Node.js 24 (global via mise) ──────────────────────────────────────────────
step "Installing Node.js 24 via mise (global)"
mise use --global node@24
info "Node: $(mise exec node -- node --version)   npm: $(mise exec node -- npm --version)"

# ── Go (global via mise) ──────────────────────────────────────────────────────
step "Installing Go via mise (global)"
mise use --global go@latest
info "Go: $(mise exec go -- go version)"

# ── Docker Desktop ────────────────────────────────────────────────────────────
step "Installing Docker Desktop"
if brew list --cask docker &>/dev/null; then
  info "Docker Desktop already installed."
else
  brew install --cask docker
  info "Docker Desktop installed. Launch it from Applications to complete first-run setup."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  Meesho Hackathon — Setup Complete                ${RESET}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Installed tools:${RESET}"
echo -e "    Git     : $(git --version)"
echo -e "    Node.js : $(mise exec node -- node --version)"
echo -e "    npm     : $(mise exec node -- npm --version)"
echo -e "    Go      : $(mise exec go -- go version | awk '{print $3}')"
echo -e "    mise    : $(mise --version)"
echo ""
echo -e "  ${BOLD}Port reference:${RESET}"
echo -e "    Frontend  →  ${GREEN}http://localhost:9080${RESET}"
echo -e "    Backend   →  ${GREEN}http://localhost:8090${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "    1. Open Docker Desktop from Applications and finish first-run setup."
echo -e "    2. Restart your terminal (or run: source ~/.zshrc) so mise activates."
echo -e "    3. Configure Git with your GitHub credentials when prompted."
echo ""
