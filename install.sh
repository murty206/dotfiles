#!/usr/bin/env bash
# =============================================================================
# install.sh — Murty's dotfiles installer
# Run once on any new machine:
#   bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
#
# Process substitution, not `curl … | bash`. The two are not interchangeable
# here: piping makes the script itself stdin, so anything that reads from the
# terminal — the gh login prompt, a sudo password — consumes the script instead
# and runs half an installer. README.md and aliases.sh already used this form;
# this line was the odd one out.
#
# What it does:
#   1. Installs git if missing, and sets one identity if none is configured
#      (an identity that differs is reported, never overwritten)
#   2. Clones your dotfiles repo to ~/.dotfiles, and points git's mailmap.file
#      at .mailmap so every repo on the machine reads one contributor
#   3. Installs zsh and sets it as default shell
#   4. Installs zsh plugins (autosuggestions, syntax-highlighting)
#   5. Installs Starship, symlinks starship.toml from dotfiles
#   6. Installs JetBrains Mono Nerd Font
#   7. Installs Kitty terminal, symlinks kitty.conf from dotfiles
#   8. Installs fastfetch, hooks into shell
#   9. Installs tty-clock (backs the `clock` alias)
#  10. Installs GitHub CLI, then offers to run `gh auth login`
#  11. Installs Ookla Speedtest CLI (backs the `speed` alias)
#  12. Symlinks the Claude Code slash commands and the global CLAUDE.md
#  13. Hooks aliases.sh into ~/.zshrc and ~/.bashrc
# =============================================================================

set -e

REPO_URL="git@github.com:murty206/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# One git identity on every machine. Four accumulated here because each host was
# configured by hand at a different time, and `git log --format=%an` is what
# tells my commits from a collaborator's — a check no better than the name being
# one name. Override on a host that legitimately needs another:
#   GIT_NAME="..." GIT_EMAIL="..." bash install.sh
GIT_NAME="${GIT_NAME:-murty}"
GIT_EMAIL="${GIT_EMAIL:-murty206@gmail.com}"
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
# 1. Ensure git is installed, and that it commits under one identity
# -----------------------------------------------------------------------------
section "Git"
if ! command -v git &>/dev/null; then
    info "Installing git..."
    $PKG_INSTALL git
fi
success "git available"

# `git config --get` exits 1 when the key is unset, and `set -e` is on — so the
# reads are guarded or the whole installer dies on a fresh machine.
current_name="$(git config --global user.name  2>/dev/null || true)"
current_email="$(git config --global user.email 2>/dev/null || true)"

if [ -z "$current_name" ] && [ -z "$current_email" ]; then
    git config --global user.name  "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    success "git identity set to $GIT_NAME <$GIT_EMAIL>"
elif [ "$current_name" = "$GIT_NAME" ] && [ "$current_email" = "$GIT_EMAIL" ]; then
    success "git identity already $GIT_NAME <$GIT_EMAIL>"
else
    # Deliberately not overwritten. A host with a deliberate work identity is
    # the mirror image of the bug this is here to prevent, and silently
    # rewriting it would be the worse failure of the two. Say it and move on.
    warn "git identity is ${current_name:-<unset>} <${current_email:-<unset>}>, expected $GIT_NAME <$GIT_EMAIL>"
    warn "  not changed — if this host should use the standard identity, run:"
    warn "    git config --global user.name \"$GIT_NAME\" && git config --global user.email \"$GIT_EMAIL\""
fi

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

# Point git's mailmap at the repo's copy, globally. Wired here rather than in
# section 1 because the file only exists once the clone above has run.
#
# This is the half that reaches the *other* repos: the four identities are
# already in their histories and rewriting those is off the table, so the
# mapping is applied at read time instead — every repo on this machine, no
# commits in any of them.
if [ -f "$DOTFILES_DIR/.mailmap" ]; then
    current_mailmap="$(git config --global mailmap.file 2>/dev/null || true)"
    if [ "$current_mailmap" = "$DOTFILES_DIR/.mailmap" ]; then
        success "git mailmap already pointed at dotfiles"
    else
        [ -n "$current_mailmap" ] && warn "replacing mailmap.file — was $current_mailmap"
        git config --global mailmap.file "$DOTFILES_DIR/.mailmap"
        success "git mailmap pointed at $DOTFILES_DIR/.mailmap"
    fi
fi

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
# 5. Install Starship + symlink config from dotfiles
# -----------------------------------------------------------------------------
section "Starship"
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    success "Starship installed"
else
    success "Starship already installed — $(starship --version)"
fi

mkdir -p "$HOME/.config"
STARSHIP_LINK="$HOME/.config/starship.toml"
STARSHIP_DOTFILE="$DOTFILES_DIR/starship.toml"

if [ -f "$STARSHIP_DOTFILE" ]; then
    if [ -L "$STARSHIP_LINK" ]; then
        warn "starship.toml symlink already exists — skipping"
    elif [ -f "$STARSHIP_LINK" ]; then
        warn "Existing starship.toml found — backing up to starship.toml.bak"
        mv "$STARSHIP_LINK" "$STARSHIP_LINK.bak"
        ln -s "$STARSHIP_DOTFILE" "$STARSHIP_LINK"
        success "starship.toml symlinked from dotfiles"
    else
        ln -s "$STARSHIP_DOTFILE" "$STARSHIP_LINK"
        success "starship.toml symlinked from dotfiles"
    fi
else
    warn "starship.toml not found in dotfiles — skipping symlink"
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
font_size        10.0

# 1984 Dark Theme color scheme
foreground              #a9b1d6
background              #180b17
selection_foreground    #1a1b26
selection_background    #7aa2f7
cursor                  #c0caf5
cursor_text_color       #1a1b26

# Black
color0  #000000
color8  #000000

# Red
color1  #ff16b0
color9  #ff16b0

# Green
color2  #b3f361
color10 #b3f361

# Yellow
color3  #ffea16
color11 #ffea16

# Blue
color4  #15d4c8
color12 #40e0d0

# Magenta
color5  #f806fa
color13 #f806fa

# Cyan
color6  #59e1e3
color14 #6be4e6

# White
color7  #feffff
color15 #feffff

# URL styles
url_color #f806fa
url_style single

# Window
window_padding_width    8
background_opacity      0.85
confirm_os_window_close 0

# Scrollback
scrollback_lines        10000

# Performance
repaint_delay           10
input_delay             3
sync_to_monitor         yes

# Bell
enable_audio_bell       no

# Copy on select, paste on right click (like PowerShell)
copy_on_select                  yes
mouse_map right press ungrabbed paste_from_clipboard


# BEGIN_KITTY_THEME
# 1984 Dark
#include current-theme.conf
# END_KITTY_THEME
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
# 9. Install fastfetch
# -----------------------------------------------------------------------------
section "Fastfetch"

if command -v fastfetch &>/dev/null; then
    success "fastfetch already installed — $(fastfetch --version | head -1)"
else
    info "Installing fastfetch..."
    if command -v paru &>/dev/null; then
        paru -S --noconfirm fastfetch
    elif command -v apt &>/dev/null; then
        # fastfetch not in default Debian repos, download deb directly
        TMP_FF=$(mktemp -d)
        curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"             -o "$TMP_FF/fastfetch.deb"
        sudo dpkg -i "$TMP_FF/fastfetch.deb"
        rm -rf "$TMP_FF"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y fastfetch
    fi
    success "fastfetch installed"
fi

# Hook fastfetch into .zshrc so it runs on every terminal launch
if ! grep -q "fastfetch" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# System overview on terminal launch" >> "$HOME/.zshrc"
    echo "fastfetch" >> "$HOME/.zshrc"
    success "fastfetch hooked into ~/.zshrc"
else
    warn "fastfetch already in ~/.zshrc — skipping"
fi

# Hook fastfetch into .bashrc too
if [ -f "$HOME/.bashrc" ] && ! grep -q "fastfetch" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# System overview on terminal launch" >> "$HOME/.bashrc"
    echo "fastfetch" >> "$HOME/.bashrc"
fi

# -----------------------------------------------------------------------------
# 10. Install tty-clock (backs the `clock` alias)
# -----------------------------------------------------------------------------
section "tty-clock"

if command -v tty-clock &>/dev/null; then
    success "tty-clock already installed"
else
    info "Installing tty-clock..."
    if $PKG_INSTALL tty-clock; then
        success "tty-clock installed"
    else
        warn "tty-clock unavailable in this distro's repos — 'clock' alias will not work until it is installed manually"
    fi
fi

# -----------------------------------------------------------------------------
# 11. Install GitHub CLI
# -----------------------------------------------------------------------------
# The binary is `gh` everywhere, but Arch names the package `github-cli` — so
# the guard checks the command and each branch uses the distro's own name.
# Mirrors ensure_gh() in aliases.sh; keep the two in step.
section "GitHub CLI"

if command -v gh &>/dev/null; then
    success "gh already installed — $(gh --version | head -1)"
else
    info "Installing gh..."
    if command -v paru &>/dev/null;    then paru -S --noconfirm github-cli
    elif command -v apt &>/dev/null;   then sudo apt install -y gh
    elif command -v dnf &>/dev/null;   then sudo dnf install -y gh
    fi
    if command -v gh &>/dev/null; then
        success "gh installed"
    else
        warn "gh unavailable in this distro's repos — install it manually"
    fi
fi

if command -v gh &>/dev/null && ! gh auth status &>/dev/null; then
    warn "gh is installed but not authenticated."
    echo "    GitHub.com → SSH. Skip the key upload if your key is already on the account."

    # Ask rather than only advise. This is the one step in the whole installer
    # that cannot be automated — it needs a device code and a browser — and a
    # line printed here scrolls off before the run finishes.
    #
    # Read from /dev/tty, never stdin: under `curl … | bash` stdin *is* the
    # script, and a plain `read` would swallow the rest of it and run half an
    # installer. Both reads are guarded because `set -e` is on and `read`
    # returns non-zero on EOF.
    if [ -r /dev/tty ]; then
        printf "    Log in now? [Y/n] " > /dev/tty
        read -r gh_answer < /dev/tty || gh_answer="n"
        case "${gh_answer:-y}" in
            [Nn]*)
                warn "Skipped — run 'gh auth login' when you are ready."
                ;;
            *)
                gh auth login < /dev/tty || warn "gh auth login did not finish — run it again later."
                ;;
        esac
    else
        warn "No terminal to ask on — run: gh auth login"
    fi
fi

# -----------------------------------------------------------------------------
# 12. Install Ookla Speedtest CLI (backs the `speed` alias)
# -----------------------------------------------------------------------------
# In no distro's repos, so the vendor's static binary is fetched directly — same
# route as Starship and fastfetch above. Installed as `ookla-speedtest` because
# Debian's speedtest-cli package also ships /usr/bin/speedtest and ~/.local/bin
# wins the PATH, so the short name would shadow it silently. Ookla publishes no
# checksum, hence the pinned hash. Mirrors ensure_speedtest() in aliases.sh;
# keep the two in step — version, architecture map and hash alike.
section "Ookla Speedtest CLI"

if command -v ookla-speedtest &>/dev/null; then
    success "ookla-speedtest already installed — $(ookla-speedtest --version | head -1)"
else
    SPEEDTEST_VER="1.2.0"
    case "$(uname -m)" in
        x86_64)  ST_ARCH="x86_64"
                 ST_SUM="5690596c54ff9bed63fa3732f818a05dbc2db19ad36ed68f21ca5f64d5cfeeb7" ;;
        aarch64) ST_ARCH="aarch64"; ST_SUM="" ;;
        armv7l)  ST_ARCH="armhf";   ST_SUM="" ;;
        i686)    ST_ARCH="i386";    ST_SUM="" ;;
        *)       ST_ARCH="" ;;
    esac

    if [ -z "$ST_ARCH" ]; then
        warn "No Ookla build for $(uname -m) — 'speed' alias will not work"
    else
        info "Downloading Ookla Speedtest CLI $SPEEDTEST_VER ($ST_ARCH)..."
        TMP_ST=$(mktemp -d)
        ST_URL="https://install.speedtest.net/app/cli/ookla-speedtest-${SPEEDTEST_VER}-linux-${ST_ARCH}.tgz"

        if ! curl -fsSL "$ST_URL" -o "$TMP_ST/ookla.tgz"; then
            warn "Download failed — 'speed' alias will not work until it is installed manually"
        elif [ -n "$ST_SUM" ] && ! printf '%s  %s\n' "$ST_SUM" "$TMP_ST/ookla.tgz" | sha256sum -c --status -; then
            warn "Checksum mismatch — not installing. Verify the download by hand before trusting it"
        elif ! tar xzf "$TMP_ST/ookla.tgz" -C "$TMP_ST" speedtest 2>/dev/null; then
            warn "Tarball did not contain the expected binary — not installing"
        else
            [ -z "$ST_SUM" ] && warn "No pinned checksum for $ST_ARCH — skipped verification"
            mkdir -p "$HOME/.local/bin"
            mv "$TMP_ST/speedtest" "$HOME/.local/bin/ookla-speedtest"
            chmod +x "$HOME/.local/bin/ookla-speedtest"
            success "ookla-speedtest installed to ~/.local/bin"
        fi
        rm -rf "$TMP_ST"
    fi

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) warn "~/.local/bin is not on PATH — add it or 'speed' will not find the binary" ;;
    esac
fi

# -----------------------------------------------------------------------------
# 13. Symlink Claude Code slash commands
# -----------------------------------------------------------------------------
# Unlike claude-statusline.sh, these need no settings.json edit — a file in
# ~/.claude/commands/ is picked up by its name alone — so there is no reason to
# leave them manual. Symlinked, not copied: editing the repo copy changes the
# live command with no reinstall.
section "Claude Code commands"

CLAUDE_CMD_SRC="$DOTFILES_DIR/claude-commands"
CLAUDE_CMD_DIR="$HOME/.claude/commands"

if [ -d "$CLAUDE_CMD_SRC" ]; then
    mkdir -p "$CLAUDE_CMD_DIR"
    for cmd in "$CLAUDE_CMD_SRC"/*.md; do
        [ -e "$cmd" ] || continue
        target="$CLAUDE_CMD_DIR/$(basename "$cmd")"
        if [ -L "$target" ]; then
            warn "$(basename "$cmd") symlink already exists — skipping"
        elif [ -f "$target" ]; then
            warn "Existing $(basename "$cmd") found — backing up to $(basename "$cmd").bak"
            mv "$target" "$target.bak"
            ln -s "$cmd" "$target"
            success "$(basename "$cmd") symlinked from dotfiles"
        else
            ln -s "$cmd" "$target"
            success "$(basename "$cmd") symlinked from dotfiles"
        fi
    done
else
    warn "claude-commands/ not found in dotfiles — skipping"
fi

# Global CLAUDE.md — loaded in every project, on every machine. Symlinked for
# the same reason as the commands: no settings.json edit needed, so there is no
# reason to keep it manual.
CLAUDE_GLOBAL_SRC="$DOTFILES_DIR/claude-global.md"
CLAUDE_GLOBAL_LINK="$HOME/.claude/CLAUDE.md"

if [ -f "$CLAUDE_GLOBAL_SRC" ]; then
    mkdir -p "$HOME/.claude"
    if [ -L "$CLAUDE_GLOBAL_LINK" ]; then
        warn "CLAUDE.md symlink already exists — skipping"
    elif [ -f "$CLAUDE_GLOBAL_LINK" ]; then
        warn "Existing ~/.claude/CLAUDE.md found — backing up to CLAUDE.md.bak"
        mv "$CLAUDE_GLOBAL_LINK" "$CLAUDE_GLOBAL_LINK.bak"
        ln -s "$CLAUDE_GLOBAL_SRC" "$CLAUDE_GLOBAL_LINK"
        success "global CLAUDE.md symlinked from dotfiles"
    else
        ln -s "$CLAUDE_GLOBAL_SRC" "$CLAUDE_GLOBAL_LINK"
        success "global CLAUDE.md symlinked from dotfiles"
    fi
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
# Reports what is actually on the machine, not what the script attempted.
# Several steps above end in a warning rather than an install — gh and
# speedtest have "not in this distro's repos" paths — and a summary that ticks
# them anyway is worse than no summary: it is the one screen that gets believed.
have() {  # a binary on PATH
    if command -v "$1" &>/dev/null; then echo "    ✓ $2"
    else                                 echo "    · $2 — NOT installed"
    fi
}
present() {  # a path that should exist
    if [ -e "$1" ]; then echo "    ✓ $2"
    else                 echo "    · $2 — NOT installed"
    fi
}

echo "  What was set up:"
echo "    ✓ git identity + mailmap (one contributor across every repo)"
have    zsh                                        "zsh (default shell)"
present "${ZSH_CUSTOM:-$HOME/.zsh}/zsh-autosuggestions" "zsh-autosuggestions + zsh-syntax-highlighting"
have    starship                                   "Starship prompt (symlinked from dotfiles)"
present "$HOME/.local/share/fonts"                 "JetBrains Mono Nerd Font"
have    kitty                                      "Kitty terminal (Tokyo Night, symlinked config)"
have    fastfetch                                  "Fastfetch (system overview on launch)"
have    tty-clock                                  "tty-clock (terminal clock — run 'clock')"
have    gh                                         "GitHub CLI"
have    ookla-speedtest                            "Ookla Speedtest CLI (run 'speed')"
present "$HOME/.claude/CLAUDE.md"                  "Claude Code slash commands + global CLAUDE.md"
present "$DOTFILES_DIR/aliases.sh"                 "Dotfiles aliases"
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

# Re-checked here rather than trusted from section 11: the offer up there can be
# declined, or the login can be started and abandoned. This is the last thing on
# screen when the installer ends, which is the only place a reminder survives.
if command -v gh &>/dev/null && ! gh auth status &>/dev/null; then
    warn "Still to do — gh is installed but not logged in:"
    echo "    gh auth login"
    echo "    → GitHub.com → SSH; 'update' will keep saying so until it is done"
    echo ""
fi
