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

    # Claude Code slash commands. Looped rather than named one by one, so a
    # command added to the repo reaches every machine on the next `update`
    # without an install.sh re-run. Editing an already-linked file needs no
    # step at all — the symlink points straight at the repo.
    if [ -d "$DOTFILES_DIR/claude-commands" ]; then
        mkdir -p "$HOME/.claude/commands"
        for _cmd in "$DOTFILES_DIR"/claude-commands/*.md; do
            [ -e "$_cmd" ] || continue
            _target="$HOME/.claude/commands/$(basename "$_cmd")"
            if [ -L "$_target" ]; then
                :
            elif [ -f "$_target" ]; then
                # Never clobber a hand-written command, but do not fail quietly
                # either: a real file here means this machine stopped receiving
                # updates for that command, and nothing else would say so. On a
                # Windows box installed by copy this is the normal state and the
                # line is the cue to re-copy — see WINDOWS.md.
                echo "! $(basename "$_cmd") exists as a real file — not linked, not updating (see WINDOWS.md)"
            else
                ln -s "$_cmd" "$_target"
                echo "→ $(basename "$_cmd") symlinked"
            fi
        done
        unset _cmd _target
    fi

    if [ -f "$DOTFILES_DIR/claude-global.md" ] \
       && [ ! -L "$HOME/.claude/CLAUDE.md" ] && [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
        mkdir -p "$HOME/.claude"
        ln -s "$DOTFILES_DIR/claude-global.md" "$HOME/.claude/CLAUDE.md"
        echo "→ global CLAUDE.md symlinked"
    fi

    # Git identity and mailmap — the same two things install.sh sets, re-checked
    # here so a machine configured before they existed catches up.
    #
    # Quiet when correct, and it never rewrites an identity: a host that
    # deliberately commits under a work name is the mirror image of the problem
    # this guards against. Like the "exists as a real file" line above, the
    # warning is the whole mechanism — it repeats every `update` until the
    # machine is fixed by hand.
    if [ -f "$DOTFILES_DIR/.mailmap" ] \
       && [ "$(git config --global mailmap.file 2>/dev/null)" != "$DOTFILES_DIR/.mailmap" ]; then
        git config --global mailmap.file "$DOTFILES_DIR/.mailmap"
        echo "→ git mailmap pointed at dotfiles"
    fi

    _gn="$(git config --global user.name 2>/dev/null)"
    _ge="$(git config --global user.email 2>/dev/null)"
    if [ -z "$_gn" ] && [ -z "$_ge" ]; then
        git config --global user.name  "murty"
        git config --global user.email "murty206@gmail.com"
        echo "→ git identity set to murty <murty206@gmail.com>"
    elif [ "$_gn" != "murty" ] || [ "$_ge" != "murty206@gmail.com" ]; then
        echo "! git identity is ${_gn:-<unset>} <${_ge:-<unset>}>, not murty <murty206@gmail.com> — not changed"
        echo "  git config --global user.name murty && git config --global user.email murty206@gmail.com"
    fi
    unset _gn _ge

    # Pull in anything install.sh would have set up but this machine is missing
    ensure_tty_clock
    ensure_gh
    ensure_speedtest

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

# GitHub CLI. Note the package name is NOT the command name on Arch — the
# binary is `gh`, the package is `github-cli`, so the guard checks the command
# and the install uses the distro's own name for it.
function ensure_gh() {
    command -v gh &>/dev/null && return 0

    echo "→ gh not found — installing GitHub CLI..."
    if command -v paru &>/dev/null;    then paru -S --noconfirm github-cli
    elif command -v apt &>/dev/null;   then sudo apt install -y gh
    elif command -v dnf &>/dev/null;   then sudo dnf install -y gh
    else
        echo "! No supported package manager — install gh manually."
        return 1
    fi

    echo "→ gh installed. Authenticate once with:  gh auth login"
    echo "  (choose GitHub.com → SSH; skip the key upload if your key is already on the account)"
}

# Ookla's official speedtest client backs the `speed` alias. It is in no
# distro's repos, so this fetches the vendor's static binary — the same route
# install.sh already takes for Starship and fastfetch, and one code path for all
# three distros instead of three package branches.
#
# The distro-packaged `speedtest-cli` (sivel's) was the first choice and is the
# wrong one: upstream archived it after v2.1.3 in 2021, and the legacy endpoint
# it still calls now geolocates this connection ~2200 km away, so it picks a
# French server and reports a 512 ms ping on a link that measures 102 ms to
# Ankara. Ookla's own client is frozen at 1.2.0 too, but it is first-party
# against the backend Ookla actually operates, and it resolves correctly.
#
# Installed as `ookla-speedtest`, NOT `speedtest`: Debian's speedtest-cli
# package also ships /usr/bin/speedtest, and ~/.local/bin comes first in PATH,
# so the short name would silently shadow it and neither would be obvious.
#
# Ookla publishes no checksums or signatures, so the tarball is pinned to a
# sha256 taken from a verified download. A mismatch aborts this one install and
# says so rather than running an unexpected binary; `update` carries on.
# Mirrors the speedtest-cli section in install.sh; keep the two in step —
# including the version, the architecture map and the hash.
function ensure_speedtest() {
    command -v ookla-speedtest &>/dev/null && return 0

    local ver="1.2.0" arch sum url tmp
    case "$(uname -m)" in
        x86_64)  arch="x86_64"
                 sum="5690596c54ff9bed63fa3732f818a05dbc2db19ad36ed68f21ca5f64d5cfeeb7" ;;
        # Ookla builds these too, but no hash has been verified for them here —
        # add one the first time such a machine appears rather than guessing.
        aarch64) arch="aarch64"; sum="" ;;
        armv7l)  arch="armhf";   sum="" ;;
        i686)    arch="i386";    sum="" ;;
        *) echo "! No Ookla build for $(uname -m) — 'speed' will not work."; return 1 ;;
    esac

    echo "→ ookla-speedtest not found — downloading (needed by 'speed')..."
    url="https://install.speedtest.net/app/cli/ookla-speedtest-${ver}-linux-${arch}.tgz"
    tmp=$(mktemp -d) || return 1

    if ! curl -fsSL "$url" -o "$tmp/ookla.tgz"; then
        echo "! Download failed: $url"
        rm -rf "$tmp"; return 1
    fi

    if [ -n "$sum" ]; then
        if ! printf '%s  %s\n' "$sum" "$tmp/ookla.tgz" | sha256sum -c --status -; then
            echo "! Checksum mismatch — not installing. Expected $sum"
            echo "  If Ookla rebuilt $ver, verify the download by hand and update the hash."
            rm -rf "$tmp"; return 1
        fi
    else
        echo "  (no pinned checksum for $arch — skipping verification)"
    fi

    if ! tar xzf "$tmp/ookla.tgz" -C "$tmp" speedtest 2>/dev/null; then
        echo "! Tarball did not contain the expected binary."
        rm -rf "$tmp"; return 1
    fi

    mkdir -p "$HOME/.local/bin"
    mv "$tmp/speedtest" "$HOME/.local/bin/ookla-speedtest"
    chmod +x "$HOME/.local/bin/ookla-speedtest"
    rm -rf "$tmp"
    echo "→ ookla-speedtest installed to ~/.local/bin"

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) echo "! ~/.local/bin is not on PATH — 'speed' will not find it." ;;
    esac
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
# Ping / download / upload against the nearest Ookla server, ~30s. The two
# accept flags only matter on a machine's first run — Ookla's client blocks on a
# licence prompt otherwise, which would hang `speed` with no explanation. Append
# flags as usual: `speed -f json` for machine-readable output, `speed -L` to
# list nearby servers, `speed -s <id>` to pin one.
alias speed='ookla-speedtest --accept-license --accept-gdpr'


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
