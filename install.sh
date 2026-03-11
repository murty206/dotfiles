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
#   5. Installs Starship, applies Tokyo Night preset
#   6. Installs JetBrains Mono Nerd Font
#   7. Installs Kitty terminal, symlinks kitty.conf from dotfiles
#   8. Hooks aliases.sh into ~/.zshrc and ~/.bashrc
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
# 5. Install Starship + Tokyo Night preset
# -----------------------------------------------------------------------------
section "Starship"
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    success "Starship installed"
else
    success "Starship already installed — $(starship --version)"
fi
STARSHIP_CONFIG="$HOME/.config/starship.toml"
mkdir -p "$HOME/.config"
if ! grep -q "tokyo-night" "$STARSHIP_CONFIG" 2>/dev/null; then
    info "Applying Tokyo Night preset..."
    starship preset tokyo-night -o "$STARSHIP_CONFIG"
    # Remove hardcoded apple logo from Tokyo Night preset
    sed -i '/bg:#a3aed2 fg:#090c0c/d' "$STARSHIP_CONFIG"
    success "Tokyo Night preset applied"
else
    warn "Starship config already exists — skipping preset"
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
# 6. Install JetBrains Mono Nerd Font
# -----------------------------------------------------------------------------
section "JetBrains Mono Nerd Font"

FONT_DIR="$HOME/.local/share/fonts"
FONT_CHECK="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"

if [ -f "$FONT_CHECK" ]; then
    success "JetBrains Mono Nerd Font already installed"
else
    info "Downloading JetBrains Mono Nerd Font..."
    mkdir -p "$FONT_DIR"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    TMP_DIR=$(mktemp -d)
    curl -fsSL "$FONT_URL" -o "$TMP_DIR/JetBrainsMono.tar.xz"
    tar -xf "$TMP_DIR/JetBrainsMono.tar.xz" -C "$TMP_DIR"
    cp "$TMP_DIR"/*.ttf "$FONT_DIR/" 2>/dev/null || true
    cp "$TMP_DIR"/*.otf "$FONT_DIR/" 2>/dev/null || true
    rm -rf "$TMP_DIR"
    fc-cache -f "$FONT_DIR"
    success "JetBrains Mono Nerd Font installed"
fi

# -----------------------------------------------------------------------------
# 7. Install Kitty + symlink config
# -----------------------------------------------------------------------------
section "Kitty terminal"

if ! command -v kitty &>/dev/null; then
    info "Installing Kitty..."
    if command -v paru &>/dev/null;     then paru -S --noconfirm kitty
    elif command -v apt &>/dev/null;    then sudo apt install -y kitty
    elif command -v dnf &>/dev/null;    then sudo dnf install -y kitty
    fi
    success "Kitty installed"
else
    success "Kitty already installed — $(kitty --version)"
fi

# Symlink kitty.conf from dotfiles
KITTY_CONFIG_DIR="$HOME/.config/kitty"
KITTY_CONFIG="$KITTY_CONFIG_DIR/kitty.conf"
DOTFILES_KITTY="$DOTFILES_DIR/kitty.conf"

mkdir -p "$KITTY_CONFIG_DIR"

if [ ! -f "$DOTFILES_KITTY" ]; then
    warn "kitty.conf not found in dotfiles repo — creating default config..."
    cat > "$DOTFILES_KITTY" << 'EOF'
# =============================================================================
# kitty.conf — Murty's Kitty terminal config
# Managed via dotfiles. Edit here, push to GitHub, run 'update' to sync.
# =============================================================================

# Font
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size        12.0

# Tokyo Night color scheme
foreground              #a9b1d6
background              #1a1b26
selection_foreground    #1a1b26
selection_background    #7aa2f7
cursor                  #c0caf5
cursor_text_color       #1a1b26

# Black
color0  #414868
color8  #414868

# Red
color1  #f7768e
color9  #f7768e

# Green
color2  #9ece6a
color10 #9ece6a

# Yellow
color3  #e0af68
color11 #e0af68

# Blue
color4  #7aa2f7
color12 #7aa2f7

# Magenta
color5  #bb9af7
color13 #bb9af7

# Cyan
color6  #7dcfff
color14 #7dcfff

# White
color7  #c0caf5
color15 #c0caf5

# Window
window_padding_width    8
background_opacity      0.95
confirm_os_window_close 0

# Scrollback
scrollback_lines        10000

# Performance
repaint_delay           10
input_delay             3
sync_to_monitor         yes

# Bell
enable_audio_bell       no
EOF
    success "Default kitty.conf created in dotfiles"
fi

if [ -L "$KITTY_CONFIG" ]; then
    warn "kitty.conf symlink already exists — skipping"
elif [ -f "$KITTY_CONFIG" ]; then
    warn "Existing kitty.conf found — backing up to kitty.conf.bak"
    mv "$KITTY_CONFIG" "$KITTY_CONFIG.bak"
    ln -s "$DOTFILES_KITTY" "$KITTY_CONFIG"
    success "kitty.conf symlinked from dotfiles"
else
    ln -s "$DOTFILES_KITTY" "$KITTY_CONFIG"
    success "kitty.conf symlinked from dotfiles"
fi

# -----------------------------------------------------------------------------
# 8. Hook aliases.sh into shell configs
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
echo "  What was set up:"
echo "    ✓ zsh (default shell)"
echo "    ✓ zsh-autosuggestions + zsh-syntax-highlighting"
echo "    ✓ Starship prompt (Tokyo Night + distro logo)"
echo "    ✓ JetBrains Mono Nerd Font"
echo "    ✓ Kitty terminal (Tokyo Night, symlinked config)"
echo "    ✓ Dotfiles aliases"
echo ""
echo "  Next steps:"
echo "    1. Log out and back in to start using zsh + Kitty"
echo "    2. Open Kitty — font and colors are ready"
echo "    3. Run 'update' anytime to sync latest changes from GitHub"
echo ""
warn "Fresh machine? Set up your SSH key for GitHub:"
echo "    ssh-keygen -t ed25519 -C \"your@email.com\""
echo "    cat ~/.ssh/id_ed25519.pub"
echo "    → paste into: GitHub → Settings → SSH and GPG keys"
echo ""
