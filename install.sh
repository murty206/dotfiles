#!/usr/bin/env bash
# =============================================================================
# install.sh — Murty's dotfiles installer
# Run once on any new machine:
#   curl -fsSL https://raw.githubusercontent.com/<you>/dotfiles/main/install.sh | bash
#
# What it does:
#   1. Installs git if missing
#   2. Clones your dotfiles repo to ~/.dotfiles
#   3. Hooks aliases.sh into ~/.zshrc and/or ~/.bashrc
#   4. Reloads the current shell
# =============================================================================

set -e

REPO_URL="https://github.com/<your-username>/dotfiles.git"   # ← update this
DOTFILES_DIR="$HOME/.dotfiles"
ALIAS_LINE="[ -f \"\$HOME/.dotfiles/aliases.sh\" ] && source \"\$HOME/.dotfiles/aliases.sh\""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}→${NC} $1"; }
warn()    { echo -e "${YELLOW}!${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }

# -----------------------------------------------------------------------------
# 1. Ensure git is installed
# -----------------------------------------------------------------------------
if ! command -v git &>/dev/null; then
    warn "git not found. Installing..."
    if command -v apt &>/dev/null;   then sudo apt install -y git
    elif command -v dnf &>/dev/null; then sudo dnf install -y git
    elif command -v paru &>/dev/null; then paru -S --noconfirm git
    else error "Cannot install git. Install it manually and re-run."
    fi
fi
success "git available"

# -----------------------------------------------------------------------------
# 2. Clone or update dotfiles repo
# -----------------------------------------------------------------------------
if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles repo already exists. Pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
else
    info "Cloning dotfiles repo to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi
success "Dotfiles ready at $DOTFILES_DIR"

# -----------------------------------------------------------------------------
# 3. Hook aliases.sh into shell config(s)
# -----------------------------------------------------------------------------
hook_shell() {
    local rc="$1"
    if [ -f "$rc" ]; then
        if grep -qF ".dotfiles/aliases.sh" "$rc"; then
            warn "Already hooked in $rc — skipping."
        else
            echo "" >> "$rc"
            echo "# Dotfiles aliases" >> "$rc"
            echo "$ALIAS_LINE" >> "$rc"
            success "Hooked into $rc"
        fi
    fi
}

hook_shell "$HOME/.zshrc"
hook_shell "$HOME/.bashrc"

# -----------------------------------------------------------------------------
# 4. Done
# -----------------------------------------------------------------------------
echo ""
success "Install complete."
echo ""
echo "  Reload your shell or run:"
echo "    source ~/.zshrc   (zsh)"
echo "    source ~/.bashrc  (bash)"
echo ""
echo "  From now on, run 'update' in any terminal to pull latest aliases."
