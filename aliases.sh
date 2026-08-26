# =============================================================================
# aliases.sh — Murty's portable shell aliases
# Repo:   https://github.com/murty206/dotfiles
# Usage:
#   Managed automatically by install.sh.
#   To install on a new machine:
#     bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
#   To update aliases on any machine:
#     update
# =============================================================================

DOTFILES_DIR="$HOME/.dotfiles"

# -----------------------------------------------------------------------------
# Zsh history
# -----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY       # append to history file, don't overwrite
setopt SHARE_HISTORY        # share history between all open terminals
setopt HIST_IGNORE_DUPS     # don't save duplicate commands
setopt HIST_IGNORE_SPACE    # don't save commands starting with a space

# -----------------------------------------------------------------------------
# Self-update
# -----------------------------------------------------------------------------
function update() {
    echo "→ Pulling latest dotfiles..."
    git -C "$DOTFILES_DIR" pull --rebase || return 1

    # Ensure symlinks are in place
    if [ -f "$DOTFILES_DIR/kitty.conf" ] && [ ! -L "$HOME/.config/kitty/kitty.conf" ]; then
        ln -sf "$DOTFILES_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
        echo "→ kitty.conf symlinked"
    fi

    if [ -f "$DOTFILES_DIR/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
        echo "→ starship.toml symlinked"
    fi

    # Pull in anything install.sh would have set up but this machine is missing
    ensure_tty_clock

    source "$DOTFILES_DIR/aliases.sh"
    echo "✓ Aliases updated and reloaded."
}

# -----------------------------------------------------------------------------
# Dependency bootstrap — mirrors install.sh, re-checked on every `update`
# -----------------------------------------------------------------------------

# tty-clock backs the `clock` alias. Installs it only when missing.
function ensure_tty_clock() {
    command -v tty-clock &>/dev/null && return 0

    echo "→ tty-clock not found — installing (needed by 'clock')..."
    if command -v paru &>/dev/null;    then paru -S --noconfirm tty-clock
    elif command -v apt &>/dev/null;   then sudo apt install -y tty-clock
    elif command -v dnf &>/dev/null;   then sudo dnf install -y tty-clock
    else
        echo "! No supported package manager — install tty-clock manually."
        return 1
    fi
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
alias clock='tty-clock -c -B'                # centered terminal clock, blinking colon
alias countdown='bash "$DOTFILES_DIR/countdown.sh"'   # countdown to a wall-clock time

# -----------------------------------------------------------------------------
# Package management (auto-detects distro)
# -----------------------------------------------------------------------------
alias als='alias'

# Must happen before the if/elif below, not inside it. bash parses that whole
# compound command before running any of it, so an `up` alias left over from a
# previous source would still be live when `up() {` is parsed — and bash expands
# aliases in a function definition's name, which is a syntax error that kills
# the rest of this file.
unalias up 2>/dev/null

if command -v paru &>/dev/null; then
    # Arch Linux
    alias up='paru --noconfirm && paru -c --noconfirm'
    alias i='paru -S --noconfirm'
    alias rm-pkg='paru -Rns --noconfirm'
    alias search='paru -Ss'
    alias pkg-info='paru -Qi'
elif command -v apt &>/dev/null; then
    # Debian / Ubuntu
    # A function rather than an alias, because `apt autoremove -y` is the one
    # step of a routine upgrade that can delete something you still need.
    # Anything no longer in the archive looks like garbage to it — an
    # interpreter kept alive for a venv, a library some hand-built binary links
    # against. So print the plan and ask instead of assuming.
    #
    # Set UP_KEEP in local.sh to an extended regex of package names that must
    # never be autoremoved on this machine; a match turns the prompt into a
    # refusal. Example:
    #   UP_KEEP='python3\.11|libav|libvpx'
    up() {
        sudo apt update && sudo apt upgrade -y || return
        local plan hits reply
        plan=$(apt-get --dry-run --purge autoremove 2>/dev/null \
               | awk '/^(Remv|Purg) /{print $2}')
        if [ -z "$plan" ]; then
            echo "autoremove: nothing to remove"
            return 0
        fi
        echo
        echo "autoremove wants to remove $(printf '%s\n' "$plan" | wc -l) package(s):"
        printf '%s\n' "$plan" | sed 's/^/  /'
        if [ -n "${UP_KEEP:-}" ]; then
            hits=$(printf '%s\n' "$plan" | grep -E "$UP_KEEP")
            if [ -n "$hits" ]; then
                echo
                echo "refusing — these match UP_KEEP:"
                printf '%s\n' "$hits" | sed 's/^/  /'
                echo "nothing removed. Find out why they went orphaned first."
                return 1
            fi
        fi
        echo
        printf 'remove them? [y/N] '
        read -r reply
        case "$reply" in
            [yY]|[yY][eE][sS]) sudo apt autoremove -y ;;
            *) echo "skipped — run 'sudo apt autoremove' by hand if you want them gone" ;;
        esac
    }
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
# CAN bus / embedded dev (STM32)
# -----------------------------------------------------------------------------

# Bring up CAN interface — usage: canup [iface] [bitrate]
# defaults: can0, 500000
function canup() {
    local iface=${1:-can0}
    local baud=${2:-500000}
    sudo ip link set "$iface" up type can bitrate "$baud"
    echo "CAN: $iface up at $baud bps"
}

# Bring down CAN interface — usage: candown [iface]
function candown() {
    local iface=${1:-can0}
    sudo ip link set "$iface" down
    echo "CAN: $iface down"
}

# Dump live CAN traffic — usage: canlog [iface] [id]
function canlog() {
    local iface=${1:-can0}
    local id=$2

    if [ -n "$id" ]; then
        candump "$iface,$id:7FF"
    else
        candump "$iface"
    fi
}

# Show CAN interface details — usage: canstat [iface]
function canstat() {
    local iface=${1:-can0}
    ip -details link show "$iface"
}


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

# Extract any archive with timer and status report
function extract() {
    local start_time=$SECONDS
    local green='\033[0;32m'
    local red='\033[0;31m'
    local blue='\033[0;34m'
    local nc='\033[0m'

    if [[ ! -f "$1" ]]; then
        echo -e "${red}Error:${nc} '$1' is not a valid file."
        return 1
    fi

    local exit_code=0
    case "${1:l}" in
        *.tar.bz2|*.tbz2) tar xjf "$1"  || exit_code=$? ;;
        *.tar.gz|*.tgz)   tar xzf "$1"  || exit_code=$? ;;
        *.tar.xz|*.txz)   tar xJf "$1"  || exit_code=$? ;;
        *.tar)             tar xf "$1"   || exit_code=$? ;;
        *.bz2)             bunzip2 "$1"  || exit_code=$? ;;
        *.rar)             unrar x "$1"  || exit_code=$? ;;
        *.gz)              gunzip "$1"   || exit_code=$? ;;
        *.zip)             unzip "$1"    || exit_code=$? ;;
        *.7z)              7z x "$1"     || exit_code=$? ;;
        *.xz)              xz -d "$1"   || exit_code=$? ;;
        *)
            echo -e "${red}Error:${nc} Unknown format '$1'"
            return 1
            ;;
    esac

    local elapsed=$(( SECONDS - start_time ))
    if [ $exit_code -eq 0 ]; then
        echo -e "${green}Success:${nc} '$1' extracted in ${blue}${elapsed}s${nc}."
    else
        echo -e "${red}Error:${nc} Extraction failed after ${elapsed}s."
        return $exit_code
    fi
}

# Quick backup of a file
function bak() { cp "$1" "$1.bak"; }

# -----------------------------------------------------------------------------
# Machine-local overrides
# -----------------------------------------------------------------------------
# This repo is public — nothing host-specific belongs in it. Absolute paths,
# project shortcuts and the like go in local.sh, which is gitignored.
[ -f "$DOTFILES_DIR/local.sh" ] && source "$DOTFILES_DIR/local.sh"

# =============================================================================
