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

if [ "${XDG_CURRENT_DESKTOP:-}" != "KDE" ]; then
    echo "This is not a KDE session (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})."
    echo "Nothing was changed."
    exit 1
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

echo
echo "Done. Log out and back in — panels, shortcuts and the root-window"
echo "cursor are read once at session start."
echo
echo "The themes these files NAME are not installed by this script."
echo "See kde/README.md for the list and where each one came from."
