#!/usr/bin/env bash
# =============================================================================
# install.sh — Murty's dotfiles installer
# Run once on any new machine:
#   curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh | bash
#
# What it does:
#   1. Installs git if missing
#   2. Clones your dotfiles repo to ~/.dotfiles
#   3. Installs zsh and sets it as default shell
#   4. Installs zsh plugins (autosuggestions, syntax-highlighting)
#   5. Installs Starship prompt
#   6. Hooks aliases.sh into ~/.zshrc and ~/.bashrc
# =============================================================================

set -e

REPO_URL="https://github.com/murty206/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
ALIAS_LINE="[ -f \"\$HOME/.dotfiles/aliases.sh\" ] && source \"\$HOME/.dotfiles/aliases.sh\""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}→${NC} $1"; }
warn()    { echo -e "${YELLOW}!${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${GREEN}== $1 ==${NC}"; }

# Detect package manager
if command -v paru &>/dev/null;     then PKG_INSTALL="paru -S --noconfirm"
elif command -v apt &>/dev/null;    then PKG_INSTALL="sudo apt install -y"
elif command -v dnf &>/dev/null;    then PKG_INSTALL="sudo dnf install -y"
else error "No supported package manager found (paru/apt/dnf)."
fi

# -----------------------------------------------------------------------------
# 1. Ensure git is installed
# -----------------------------------------------------------------------------
section "Git"
if ! command -v git &>/dev/null; then
    info "Installing git..."
    $PKG_INSTALL git
fi
success "git available"

# -----------------------------------------------------------------------------
# 2. Clone or update dotfiles repo
# -----------------------------------------------------------------------------
section "Dotfiles"
if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Dotfiles already cloned. Pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
else
    info "Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi
success "Dotfiles ready at $DOTFILES_DIR"

# -----------------------------------------------------------------------------
# 3. Install zsh
# -----------------------------------------------------------------------------
section "Zsh"
if ! command -v zsh &>/dev/null; then
    info "Installing zsh..."
    $PKG_INSTALL zsh
else
    info "zsh already installed — $(zsh --version)"
fi

# Set zsh as default shell if it isn't already
if [ "$SHELL" != "$(which zsh)" ]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell changed to zsh (takes effect on next login)"
else
    success "zsh is already the default shell"
fi

# Create ~/.zshrc if it doesn't exist
[ ! -f "$HOME/.zshrc" ] && touch "$HOME/.zshrc" && info "Created ~/.zshrc"

# -----------------------------------------------------------------------------
# 4. Install zsh plugins
# -----------------------------------------------------------------------------
section "Zsh plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.zsh}"
mkdir -p "$ZSH_CUSTOM"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
else
    success "zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/zsh-syntax-highlighting" ]; then
    info "Installing zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
else
    success "zsh-syntax-highlighting already installed"
fi

# Hook plugins into .zshrc
PLUGIN_LINES='source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"'

if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Zsh plugins" >> "$HOME/.zshrc"
    echo "$PLUGIN_LINES" >> "$HOME/.zshrc"
    success "Plugins hooked into ~/.zshrc"
else
    warn "Plugins already in ~/.zshrc — skipping"
fi

# -----------------------------------------------------------------------------
# 5. Install Starship prompt
# -----------------------------------------------------------------------------
section "Starship"
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    success "Starship installed"
else
    success "Starship already installed — $(starship --version)"
fi

# Hook Starship into .zshrc
if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Starship prompt" >> "$HOME/.zshrc"
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    success "Starship hooked into ~/.zshrc"
else
    warn "Starship already in ~/.zshrc — skipping"
fi

# Hook Starship into .bashrc too (fallback)
if [ -f "$HOME/.bashrc" ] && ! grep -q "starship init bash" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Starship prompt" >> "$HOME/.bashrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

# -----------------------------------------------------------------------------
# 6. Hook aliases.sh into shell configs
# -----------------------------------------------------------------------------
section "Aliases"

hook_shell() {
    local rc="$1"
    if [ -f "$rc" ]; then
        if grep -qF ".dotfiles/aliases.sh" "$rc"; then
            warn "Already hooked in $rc — skipping"
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
# Done
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Install complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Next steps:"
echo "    1. Log out and back in (or open a new terminal) to start using zsh"
echo "    2. Run 'update' anytime to pull the latest aliases from GitHub"
echo ""
warn "If this is a fresh machine, you may want to set up your SSH key:"
echo "    ssh-keygen -t ed25519 -C \"your@email.com\""
echo "    cat ~/.ssh/id_ed25519.pub  # paste this into GitHub → Settings → SSH keys"
echo ""
