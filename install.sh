#!/bin/bash
set -euo pipefail

# ============================================================================
# install.sh — One-command Autoresearch setup
#
# Usage:
#   git clone https://github.com/danlex/autoresearch-starter.git my-research
#   cd my-research
#   bash install.sh
#
# Or with curl:
#   curl -sSL https://raw.githubusercontent.com/danlex/autoresearch-starter/main/install.sh | bash
# ============================================================================

GREEN='\033[0;32m'
AMBER='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { printf "${GREEN}[install]${RESET} %s\n" "$1"; }
warn() { printf "${AMBER}[install]${RESET} %s\n" "$1"; }
err()  { printf "${RED}[install]${RESET} %s\n" "$1" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Detect OS ---
OS="unknown"
if [[ "$(uname)" == "Darwin" ]]; then
  OS="macos"
elif [[ "$(uname)" == "Linux" ]]; then
  OS="linux"
fi
log "Detected OS: $OS"

# ============================================================================
# 1. Install system dependencies
# ============================================================================

install_macos() {
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  local missing=()
  command -v node &>/dev/null || missing+=(node)
  command -v jq &>/dev/null || missing+=(jq)
  command -v gh &>/dev/null || missing+=(gh)

  if [[ ${#missing[@]} -gt 0 ]]; then
    log "Installing: ${missing[*]}"
    brew install "${missing[@]}"
  fi
}

install_linux() {
  local missing=()
  command -v node &>/dev/null || missing+=(nodejs)
  command -v npm &>/dev/null || missing+=(npm)
  command -v jq &>/dev/null || missing+=(jq)
  command -v curl &>/dev/null || missing+=(curl)
  command -v git &>/dev/null || missing+=(git)

  if [[ ${#missing[@]} -gt 0 ]]; then
    log "Installing: ${missing[*]}"
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y -qq "${missing[@]}"
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y -q "${missing[@]}"
    elif command -v yum &>/dev/null; then
      sudo yum install -y -q "${missing[@]}"
    else
      err "Package manager not found. Install manually: ${missing[*]}"
      exit 1
    fi
  fi

  # Node.js — ensure modern version
  if ! command -v node &>/dev/null || [[ "$(node -v | sed 's/v//' | cut -d. -f1)" -lt 20 ]]; then
    log "Installing Node.js 22 via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
  fi

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    log "Installing GitHub CLI..."
    if command -v apt-get &>/dev/null; then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq gh
    else
      warn "Install GitHub CLI manually: https://cli.github.com"
    fi
  fi
}

log "Checking dependencies..."
case "$OS" in
  macos) install_macos ;;
  linux) install_linux ;;
  *) warn "Unknown OS — install node, jq, gh manually" ;;
esac

# --- Claude Code CLI ---
if ! command -v claude &>/dev/null; then
  log "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

# ============================================================================
# 2. Verify all dependencies
# ============================================================================

log "Verifying dependencies..."
deps_ok=true
for cmd in node npm jq gh git claude; do
  if command -v "$cmd" &>/dev/null; then
    printf "  ${GREEN}✓${RESET} %s (%s)\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "  ${RED}✗${RESET} %s — NOT FOUND\n" "$cmd"
    deps_ok=false
  fi
done

if [[ "$deps_ok" == "false" ]]; then
  err "Missing dependencies. Install them and re-run."
  exit 1
fi

# ============================================================================
# 3. Authentication
# ============================================================================

# GitHub CLI
if ! gh auth status &>/dev/null 2>&1; then
  log "GitHub CLI needs authentication..."
  gh auth login
fi
log "GitHub: authenticated as $(gh api user --jq '.login')"

# Claude / Anthropic
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env" 2>/dev/null || touch "$SCRIPT_DIR/.env"
  chmod 600 "$SCRIPT_DIR/.env"
fi
# shellcheck disable=SC1091
source "$SCRIPT_DIR/.env" 2>/dev/null || true

if [[ -z "${ANTHROPIC_API_KEY:-}" ]] && [[ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]]; then
  echo ""
  printf "${BOLD}Claude authentication:${RESET}\n"
  echo "  1) API key (get from https://console.anthropic.com)"
  echo "  2) OAuth token (run: claude auth login)"
  echo ""
  printf "Enter your Anthropic API key (or press Enter to use OAuth): "
  read -rsp "" api_key
  echo ""
  if [[ -n "$api_key" ]]; then
    echo "ANTHROPIC_API_KEY=$api_key" >> "$SCRIPT_DIR/.env"
    export ANTHROPIC_API_KEY="$api_key"
    log "API key saved to .env"
  else
    log "Using OAuth — make sure 'claude auth login' is done"
  fi
fi

# ============================================================================
# 4. Configure research subject
# ============================================================================

echo ""
printf "${BOLD}${CYAN}═══════════════════════════════════════════${RESET}\n"
printf "${BOLD}${CYAN}  Autoresearch — Setup${RESET}\n"
printf "${BOLD}${CYAN}═══════════════════════════════════════════${RESET}\n"
echo ""
printf "Current subject: ${BOLD}$(head -1 goal.md | sed 's/^#* *//')${RESET}\n"
echo ""
printf "Edit goal.md to change the research subject? [y/N] "
read -r edit_goal
if [[ "$edit_goal" =~ ^[Yy] ]]; then
  if command -v nano &>/dev/null; then
    nano goal.md
  elif command -v vim &>/dev/null; then
    vim goal.md
  else
    log "Edit goal.md manually, then re-run install.sh"
    exit 0
  fi
fi

# ============================================================================
# 5. Configure research.config.json
# ============================================================================

printf "\nConfigure the website? [y/N] "
read -r edit_config
if [[ "$edit_config" =~ ^[Yy] ]]; then
  local_user=$(gh api user --jq '.login' 2>/dev/null || echo "user")
  local_name=$(gh api user --jq '.name // .login' 2>/dev/null || echo "Author")

  printf "  GitHub username [${local_user}]: "
  read -r gh_user
  gh_user="${gh_user:-$local_user}"

  printf "  Your name [${local_name}]: "
  read -r author_name
  author_name="${author_name:-$local_name}"

  # Update config
  local tmp_config
  tmp_config=$(mktemp)
  jq --arg user "$gh_user" --arg name "$author_name" --arg repo "${gh_user}/autoresearch-starter" \
    '.author.name = $name | .author.github = $user | .repo = $repo | .site_url = "https://\($user).github.io/autoresearch-starter"' \
    research.config.json > "$tmp_config"
  mv "$tmp_config" research.config.json
  log "Updated research.config.json"
fi

# ============================================================================
# 6. Install site dependencies
# ============================================================================

if [[ -d "$SCRIPT_DIR/site" ]]; then
  log "Installing website dependencies..."
  (cd "$SCRIPT_DIR/site" && npm install --silent 2>&1)
fi

# ============================================================================
# 7. Generate tasks and start
# ============================================================================

echo ""
log "Running setup..."
bash start.sh

echo ""
printf "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}\n"
printf "${BOLD}${GREEN}  Setup complete!${RESET}\n"
printf "${BOLD}${GREEN}═══════════════════════════════════════════${RESET}\n"
echo ""
echo "  Start research:"
echo "    NO_JUDGES=1 bash research.sh"
echo ""
echo "  Monitor:"
echo "    bash watch.sh"
echo ""
echo "  Preview website:"
echo "    cd site && npm run dev"
echo ""
printf "Start research now? [Y/n] "
read -r start_now
if [[ ! "$start_now" =~ ^[Nn] ]]; then
  log "Starting research loop..."
  NO_JUDGES=1 nohup bash research.sh >> research.log 2>&1 &
  log "Research running in background (PID: $!)"
  log "Monitor with: tail -f research.log"
fi
