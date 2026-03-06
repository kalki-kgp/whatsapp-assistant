#!/bin/bash
# WhatsApp MCP — Local test installer
#
# Syncs your local working tree (including unpushed changes) into ~/.wa/app/
# and re-runs setup steps. Assumes system deps are already installed via install.sh.
#
# Usage:
#   bash installer/test.sh            # from repo root
#   bash test.sh                      # from installer/

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WA_HOME="$HOME/.wa"
APP_DIR="$WA_HOME/app"
VENV_DIR="$WA_HOME/venv"
LOG_DIR="$WA_HOME/logs"
RUN_DIR="$WA_HOME/run"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${BLUE}[wa-test]${NC} $*"; }
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  !${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*" >&2; }
step() { echo -e "\n${BOLD}$*${NC}"; }

echo ""
echo -e "${BOLD}╭─────────────────────────────────────╮${NC}"
echo -e "${BOLD}│    WhatsApp MCP — Local Test     │${NC}"
echo -e "${BOLD}╰─────────────────────────────────────╯${NC}"
echo ""

# --- Sync local code ---

step "1/4  Syncing local code..."

log "Source: $REPO_ROOT"
mkdir -p "$WA_HOME" "$LOG_DIR" "$RUN_DIR" "$APP_DIR"

rsync -a --delete \
    --exclude '.git' \
    --exclude 'venv' \
    --exclude 'node_modules' \
    --exclude '__pycache__' \
    --exclude '.env' \
    "$REPO_ROOT/" "$APP_DIR/"

VERSION="local-$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "dev")"
echo "$VERSION" > "$WA_HOME/version"
ok "Synced ($VERSION)"

# --- Python deps ---

step "2/4  Python environment..."

if [ ! -d "$VENV_DIR" ]; then
    log "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    ok "Created venv"
else
    ok "Venv exists"
fi

log "Installing Python dependencies..."
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -r "$APP_DIR/requirements.txt" -q
ok "Python dependencies installed"

# --- Bridge deps ---

step "3/4  Bridge dependencies..."

if [ ! -d "$APP_DIR/bridge/node_modules" ]; then
    log "Installing npm dependencies..."
    (cd "$APP_DIR/bridge" && npm install --silent)
    ok "npm dependencies installed"
else
    ok "npm dependencies already installed"
fi

# --- Config ---

step "4/4  Configuration..."

ENV_FILE="$WA_HOME/.env"
if [ -f "$ENV_FILE" ] && grep -q "NEBIUS_API_KEY=." "$ENV_FILE"; then
    ln -sf "$ENV_FILE" "$APP_DIR/.env"
    ok "API key already configured"
else
    warn "No API key found. Run the full installer or create $ENV_FILE"
fi

BIN_LINK="/usr/local/bin/wa"
chmod +x "$APP_DIR/launcher/wa" 2>/dev/null || true
if [ ! -L "$BIN_LINK" ] || [ "$(readlink "$BIN_LINK")" != "$APP_DIR/launcher/wa" ]; then
    log "Installing 'wa' command..."
    if ln -sf "$APP_DIR/launcher/wa" "$BIN_LINK" 2>/dev/null; then
        ok "Installed: wa → $BIN_LINK"
    elif sudo ln -sf "$APP_DIR/launcher/wa" "$BIN_LINK" 2>/dev/null; then
        ok "Installed: wa → $BIN_LINK (via sudo)"
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$APP_DIR/launcher/wa" "$HOME/.local/bin/wa"
        ok "Installed: wa → ~/.local/bin/wa"
    fi
fi

echo ""
echo -e "${BOLD}╭─────────────────────────────────────╮${NC}"
echo -e "${BOLD}│           Ready to test!             │${NC}"
echo -e "${BOLD}╰─────────────────────────────────────╯${NC}"
echo ""
echo -e "  ${GREEN}wa${NC}              Start the app"
echo -e "  ${DIM}Source: $REPO_ROOT${NC}"
echo -e "  ${DIM}Version: $VERSION${NC}"
echo ""
