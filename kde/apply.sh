#!/usr/bin/env bash
# Install this repo's KDE configuration into the current user's home.
#
# The files in config/ are stored with the literal string $HOME where this
# machine had an absolute home path, so the same set works under any user
# name. This script puts the real path back.
#
# Every file it replaces is backed up first — nothing is overwritten
# without a copy surviving.

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$HOME/.config/kde-backup-$stamp"

# The test is whether Plasma is INSTALLED, not whether it is the session
# running right now. On a fresh machine this is most often run from a TTY or
# over SSH before anyone has logged into the desktop, and XDG_CURRENT_DESKTOP
# is empty there — refusing on that would refuse exactly the case the whole
# directory exists for.
if ! command -v plasmashell &>/dev/null; then
    echo "Plasma is not installed here (no plasmashell on PATH)."
    echo "Nothing was changed."
    exit 1
fi

if [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ]; then
    echo "Note: Plasma is running. It keeps its own copy of these settings in"
    echo "memory and rewrites some of them at logout, which can undo this."
    echo "Log out right after this finishes."
    echo
fi

echo "KDE configuration -> $HOME/.config"
echo "Backups           -> $backup"
echo

mkdir -p "$backup"

for f in "$src"/config/*; do
    name="$(basename "$f")"
    target="$HOME/.config/$name"
    [ -e "$target" ] && cp -a "$target" "$backup/$name"
    sed "s|\$HOME|$HOME|g" "$f" > "$target"
    echo "  $name"
done

# The cursor fix lives outside ~/.config: KDE's own cursor setting reaches
# only KDE applications, while the desktop's root window resolves the theme
# named "default". This file is what points that name somewhere.
mkdir -p "$HOME/.icons/default"
if [ -e "$HOME/.icons/default/index.theme" ]; then
    cp -a "$HOME/.icons/default/index.theme" "$backup/icons-default-index.theme"
fi
cp "$src/icons/default/index.theme" "$HOME/.icons/default/index.theme"
echo "  ~/.icons/default/index.theme"

# A marker, so install.sh can tell a fresh machine from one that already has
# this. It records which commit was applied: "when" alone would not say what,
# and the set changes over time.
{
    echo "applied=$(date -Iseconds)"
    echo "commit=$(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo unknown)"
} > "$HOME/.config/.dotfiles-kde-applied"

echo
echo "Done. Log out and back in — panels, shortcuts and the root-window"
echo "cursor are read once at session start."
echo
echo "The themes these files NAME are installed separately, by:"
echo "    bash $src/themes.sh"
echo "Without them KDE falls back to its defaults without saying so."
