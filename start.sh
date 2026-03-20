#!/bin/bash
set -euo pipefail

# ============================================================================
# start.sh — One-command setup for Autoresearch
# Usage: bash start.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
AMBER='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

log() { printf "${GREEN}[autoresearch]${RESET} %s\n" "$1"; }
warn() { printf "${AMBER}[autoresearch]${RESET} %s\n" "$1"; }
err() { printf "${RED}[autoresearch]${RESET} %s\n" "$1"; }

# --- 1. Check prerequisites ---
log "Checking prerequisites..."

if ! command -v gh &>/dev/null; then
  err "GitHub CLI (gh) not found. Install: brew install gh"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  err "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  err "jq not found. Install: brew install jq"
  exit 1
fi

if ! command -v node &>/dev/null; then
  err "Node.js not found. Install: brew install node"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  err "GitHub CLI not authenticated. Run: gh auth login"
  exit 1
fi

# --- 2. Check .env ---
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    chmod 600 "$SCRIPT_DIR/.env"
    warn "Created .env from .env.example — edit it with your ANTHROPIC_API_KEY"
  fi
fi

if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]] && [[ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]]; then
  warn "No authentication found. Set ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN in .env"
  printf "  Enter your Anthropic API key (hidden): "
  read -rsp "" ANTHROPIC_API_KEY
  echo ""
  echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$SCRIPT_DIR/.env"
  chmod 600 "$SCRIPT_DIR/.env"
  export ANTHROPIC_API_KEY
  log "API key saved to .env"
else
  log "Authentication found"
fi

# --- 3. Check goal.md ---
if [[ ! -f "$SCRIPT_DIR/goal.md" ]]; then
  err "goal.md not found. Create it with your research subject first."
  exit 1
fi

log "Research subject: $(head -1 goal.md | sed 's/^#* *//')"

# --- 4. Create GitHub labels + seed tasks if needed ---
local_issues=$(gh issue list --label "task" --limit 1 --json number --jq 'length' 2>/dev/null || echo 0)
if [[ "$local_issues" == "0" ]]; then
  log "No tasks found — generating from goal.md..."
  bash seed-tasks.sh
  bash explode-goal.sh
  log "Tasks generated. Accepting high-priority tasks..."
  bash propose.sh accept high
else
  log "Tasks already exist ($(gh issue list --label "task" --json number --jq 'length' 2>/dev/null) total)"
fi

# --- 5. Install site dependencies ---
if [[ -d "$SCRIPT_DIR/site" ]] && [[ ! -d "$SCRIPT_DIR/site/node_modules" ]]; then
  log "Installing site dependencies..."
  (cd "$SCRIPT_DIR/site" && npm install --silent)
fi

# --- 6. Build site ---
if [[ -d "$SCRIPT_DIR/site" ]]; then
  log "Building website..."
  (cd "$SCRIPT_DIR/site" && npm run build 2>/dev/null) || warn "Site build failed (will retry after first research iteration)"
fi

# --- 7. Show status ---
log "Current score: $(bash autoresearch.sh 2>&1 | head -1)"
echo ""
printf "${CYAN}Ready to start research!${RESET}\n"
echo ""
echo "  To run research (auto-merge, no judges):"
echo "    NO_JUDGES=1 bash research.sh"
echo ""
echo "  To run with judges:"
echo "    bash research.sh"
echo ""
echo "  To monitor:"
echo "    bash watch.sh"
echo ""
echo "  To preview website:"
echo "    cd site && npm run dev"
echo ""
