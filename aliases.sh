# =============================================================================
# aliases.sh — Murty's portable shell aliases
# Repo:   https://github.com/<your-username>/dotfiles  ← update this
# Usage:
#   Managed automatically by install.sh.
#   To install on a new machine:
#     curl -fsSL https://raw.githubusercontent.com/<you>/dotfiles/main/install.sh | bash
#   To update aliases on any machine:
#     update
# =============================================================================

DOTFILES_DIR="$HOME/.dotfiles"

# -----------------------------------------------------------------------------
# Self-update
# -----------------------------------------------------------------------------
# Pull latest from git repo and reload shell config
function update() {
    echo "→ Pulling latest dotfiles..."
    git -C "$DOTFILES_DIR" pull --ff-only && \
    source "$DOTFILES_DIR/aliases.sh" && \
    echo "✓ Aliases updated and reloaded."
}


# -----------------------------------------------------------------------------
# Navigation
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lah'
alias ls='ls --color=auto'
alias grep='grep --color=auto'


# -----------------------------------------------------------------------------
# System
# -----------------------------------------------------------------------------
alias cls='clear'
alias reload='source ~/.zshrc 2>/dev/null || source ~/.bashrc'
alias path='echo $PATH | tr ":" "\n"'
alias hist='history | grep'                  # usage: hist <keyword>
alias ports='ss -tulnp'
alias myip='curl ifconfig.me'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias watch='watch -n 1'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'


# -----------------------------------------------------------------------------
# Package management (auto-detects distro)
# -----------------------------------------------------------------------------
alias als='alias'

if command -v paru &>/dev/null; then
    # Arch Linux
    alias up='paru && paru -c'
    alias i='paru -S --noconfirm'
    alias rm-pkg='paru -Rns'
    alias search='paru -Ss'
    alias pkg-info='paru -Qi'
elif command -v apt &>/dev/null; then
    # Debian / Ubuntu
    alias up='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
    alias i='sudo apt install -y'
    alias rm-pkg='sudo apt remove --purge -y'
    alias search='apt search'
    alias pkg-info='apt show'
elif command -v dnf &>/dev/null; then
    # Fedora / RHEL
    alias up='sudo dnf upgrade -y && sudo dnf autoremove -y'
    alias i='sudo dnf install -y'
    alias rm-pkg='sudo dnf remove -y'
    alias search='dnf search'
    alias pkg-info='dnf info'
fi


# -----------------------------------------------------------------------------
# Power / reboot
# -----------------------------------------------------------------------------
alias r='systemctl reboot -i'
alias poweroff='systemctl poweroff -i'
alias poweroff-timer-on='sudo systemctl enable --now poweroff-daily.timer'
alias poweroff-timer-off='sudo systemctl disable --now poweroff-daily.timer'


# -----------------------------------------------------------------------------
# Systemd
# -----------------------------------------------------------------------------
alias svs='sudo systemctl status'
alias sr='sudo systemctl restart'
alias sS='sudo systemctl start'
alias st='sudo systemctl stop'
alias sl='systemctl list-units --type=service --state=running'
alias jl='sudo journalctl -xe'
alias jf='sudo journalctl -fu'              # usage: jf <service>


# -----------------------------------------------------------------------------
# Editor
# -----------------------------------------------------------------------------
alias e='nano '
alias _='sudo '


# -----------------------------------------------------------------------------
# Python
# -----------------------------------------------------------------------------
alias py='python'
alias py3='python3'
alias activate='source .venv/bin/activate'
alias pipi='pip install --break-system-packages'
alias pipr='pip install -r requirements.txt --break-system-packages'


# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'


# -----------------------------------------------------------------------------
# CAN bus / embedded dev (STM32 / UAKBSCSD)
# -----------------------------------------------------------------------------
alias candown='sudo ip link set can0 down'
alias canlog='candump can0'
alias canstat='ip -details link show can0'


# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
alias pingg='ping -c 4 8.8.8.8'
alias flushdns='resolvectl flush-caches 2>/dev/null || sudo systemd-resolve --flush-caches'


# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Cheat sheet lookup: cs tar, cs python, etc.
function cs() { curl -m 7 "http://cheat.sh/$1"; }

# Make directory and cd into it
function mkcd() { mkdir -p "$1" && cd "$1"; }

# Create and activate venv (skips creation if .venv already exists)
function venv() {
    [ ! -d .venv ] && python -m venv .venv
    source .venv/bin/activate
}

# Bring up CAN interface — usage: canup [iface] [bitrate]
# defaults: can0, 500000
function canup() {
    local iface=${1:-can0}
    local baud=${2:-500000}
    sudo ip link set "$iface" up type can bitrate "$baud"
    echo "CAN: $iface up at $baud bps"
}

# Extract any archive
function extract() {
    case "$1" in
        *.tar.bz2)  tar xjf "$1"   ;;
        *.tar.gz)   tar xzf "$1"   ;;
        *.tar.xz)   tar xJf "$1"   ;;
        *.zip)      unzip "$1"      ;;
        *.7z)       7z x "$1"       ;;
        *.gz)       gunzip "$1"     ;;
        *.rar)      unrar x "$1"    ;;
        *)          echo "Unknown format: $1" ;;
    esac
}

# Quick backup of a file
function bak() { cp "$1" "$1.bak"; }

# =============================================================================
