#!/usr/bin/env bash
# Fetch and install the themes that kde/config/ names.
#
# The configuration in config/ is a set of NAMES: an icon theme, a look and
# feel package, a decoration, wallpapers. KDE does not complain about a name
# it cannot resolve — it falls back to the default without a word — so a
# machine with the config and none of these comes up looking like stock
# Plasma and nothing says why. This script closes that gap.
#
# Everything is fetched, nothing is vendored. What to fetch is in themes.tsv,
# which carries KDE Store content ids; the download URLs themselves are signed
# and expire, so they are resolved through the Store API at run time and
# cannot be hard-coded.
#
# Safe to re-run: every entry is skipped when its target already exists.

set -uo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$src/themes.tsv"
share="$HOME/.local/share"
api="https://api.kde-look.org/ocs/v1/content/data"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

installed=0 skipped=0 failed=0 ratelimited=0

say()  { echo "    $*"; }
ok()   { echo "  ✓ $*"; installed=$((installed+1)); }
skip() { echo "  · $* — already installed"; skipped=$((skipped+1)); }
bad()  { echo "  ! $*"; failed=$((failed+1)); }

for c in curl tar kpackagetool6; do
    command -v "$c" &>/dev/null || { echo "missing: $c"; exit 1; }
done

# Resolve one Store id + filename pattern to a download URL.
#
# The Store returns several files for some items, and the FIRST is not
# reliably the one wanted: a2n.blur's downloadlink1 is 3.5.2 while the
# current release is 3.6.0, and a neighbouring file is a variant for older
# Plasma releases that must not be picked up by accident. So the pattern
# decides, and among matches the last wins — upstream adds new versions at
# the end, so this keeps working across a version bump.
store_url() {
    # Declared separately on purpose: bash expands every word of a `local`
    # command before it assigns any of them, so `xml="$tmp/$id.xml"` on the
    # same line reads $id before it exists — silent without `set -u`, fatal
    # with it.
    local id="$1"
    local pattern="$2"
    local xml="$tmp/$id.xml"
    local i name link=""
    curl -sS --max-time 30 "$api/$id" -o "$xml" || return 1
    for i in $(seq 1 9); do
        name="$(grep -oP "(?<=<downloadname$i>)[^<]+" "$xml" 2>/dev/null | head -1)"
        [ -n "$name" ] || continue
        if echo "$name" | grep -qE "$pattern"; then
            link="$(grep -oP "(?<=<downloadlink$i>)[^<]+" "$xml" | head -1)"
        fi
    done
    [ -n "$link" ] && echo "$link"
}

# Unpack into a directory under ~/.local/share. -a lets tar work out the
# compression: the set is mostly .tar.gz but the icons are .tar.xz.
install_tar() {
    local file="$1" dir="$share/$2"
    mkdir -p "$dir"
    tar -xaf "$file" -C "$dir" --no-xattrs 2>/dev/null
}

install_kpackage() {
    local file="$1" type="$2"
    kpackagetool6 -t "$type" -i "$file" &>/dev/null
}

echo "KDE themes -> $share"
echo

while IFS=$'\t' read -r source ref pattern method target; do
    case "$source" in ''|\#*) continue ;; esac

    # ---- packages ---------------------------------------------------------
    # Kept in the same manifest because they are part of the same look, but
    # they are not home-directory installs: the cursor theme and the X11
    # rounded-corners effect both come from the AUR. On apt or dnf they are
    # simply absent, and saying so is better than a failed install command.
    if [ "$source" = aur ]; then
        if command -v paru &>/dev/null; then
            if pacman -Q "$ref" &>/dev/null; then skip "$ref"
            elif paru -S --noconfirm "$ref" &>/dev/null; then ok "$ref"
            else bad "$ref — install by hand"
            fi
        else
            bad "$ref — AUR only, not available on this distribution"
        fi
        continue
    fi

    [ -e "$share/$target" ] && { skip "$(basename "$target")"; continue; }

    case "$source" in
        store)
            url="$(store_url "$ref" "$pattern")"
            if [ -z "$url" ]; then
                bad "$(basename "$target") — no file matching /$pattern/ at store id $ref"
                continue
            fi
            # Saved under the name the Store gave it, extension included.
            # kpackagetool6 decides how to open an archive from its
            # extension, not its contents: the same file named ".pkg" is
            # refused, which is a confusing way to fail because the download
            # succeeded.
            file="$tmp/$(basename "${url%%\?*}")"
            curl -sSL --max-time 300 -o "$file" "$url" || { bad "$(basename "$target") — download failed"; continue; }

            # The Store answers a rate-limited download with HTTP 200 and an
            # XML error body, which then lands on disk under the archive's
            # name. Without this check the failure surfaces three lines later
            # as "unpack failed", which points at the wrong thing entirely —
            # measured while testing this script: a dozen downloads in a few
            # minutes is enough to trip it, and it asks for 900 seconds.
            if head -c 5 "$file" | grep -q '<?xml'; then
                msg="$(grep -oP '(?<=<message>)[^<]+' "$file" | head -1)"
                bad "$(basename "$target") — store refused: ${msg:-unknown error}"
                case "$msg" in *"too many requests"*) ratelimited=1 ;; esac
                continue
            fi

            # Spread the requests out. The limit above is the reason; a set
            # this size hits it reliably without a pause and the whole run
            # then has to be repeated.
            sleep 3
            ;;
        git)
            clone="$tmp/$(basename "$ref")"
            git clone -q --depth 1 "$ref" "$clone" 2>/dev/null || { bad "$(basename "$target") — clone failed"; continue; }
            file="$clone/$pattern"
            ;;
        *)  bad "unknown source '$source'"; continue ;;
    esac

    case "$method" in
        tar:*)      install_tar      "$file" "${method#tar:}"      && ok "$(basename "$target")" || bad "$(basename "$target") — unpack failed" ;;
        kpackage:*) install_kpackage "$file" "${method#kpackage:}" && ok "$(basename "$target")" || bad "$(basename "$target") — kpackagetool6 refused it" ;;
        *)          bad "unknown method '$method'" ;;
    esac
done < "$manifest"

echo
echo "  $installed installed, $skipped already present, $failed failed"
if [ "$ratelimited" -gt 0 ]; then
    echo
    echo "  The KDE Store rate-limited this run. Wait ~15 minutes and run it"
    echo "  again — everything already fetched is skipped, so a second run"
    echo "  only picks up what is missing:"
    echo "      bash $src/themes.sh"
elif [ "$failed" -gt 0 ]; then
    echo "  Failures are not fatal: KDE falls back to a default for anything missing."
fi
exit 0
