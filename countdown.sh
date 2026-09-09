#!/usr/bin/env bash
# =============================================================================
# countdown.sh — full-screen countdown to a time or duration, tty-clock style
# Repo:   https://github.com/murty206/dotfiles
# Usage:  countdown <HH:MM | duration> [label]
#
# An argument containing ":" is read as a wall-clock time, anything else as a
# duration from now. Current time is shown above at half scale. Ctrl+C quits.
#
# Once it hits zero the screen becomes a waiting state: a key menu in the footer
# ([r]estart, [c]lock, [x] run a command, [q]uit) and, if nobody presses
# anything, a plain full-screen clock after COUNTDOWN_MENU_TIMEOUT seconds.
#
# Pure bash + coreutils — no dependencies, works in a bare TTY.
# Run with bash explicitly; it uses bash arrays and is not zsh-compatible.
# =============================================================================

set -uo pipefail

usage() {
    cat <<'USAGE'
countdown — full-screen countdown to a time of day, or after a duration

  countdown 16:45              wall-clock time; tomorrow if already past today
  countdown 25m                25 minutes from now
  countdown 1h30m              hours and minutes
  countdown 90s                seconds
  countdown 25                 a bare number means minutes
  countdown 16:45 "Standup"    second argument is a label above the digits

The rule is one character: an argument containing ":" is a wall-clock time,
anything else is a duration. So "1:30" means half past one on the clock, not
one and a half hours — write 1h30m when you mean the duration. The resolved
target and the time left appear in the footer from the first frame, and a
target that landed on the next day is marked "(tomorrow)", so a misread shows
up immediately rather than an hour later.

When time is up the footer turns into a menu:

  r   restart — same duration from now, or the target's next occurrence
  c   switch to the clock now
  x   run $COUNTDOWN_CMD, if one was set
  q   quit

Left alone it falls back to a full-screen clock after 30 seconds, so a finished
countdown leaves something useful on the monitor. Two environment variables:

  COUNTDOWN_MENU_TIMEOUT=90   seconds before the clock takes over; 0 stays on 00:00
  COUNTDOWN_CMD='mpv ~/a.mp3' command offered under [x]; unset hides the key

The menu needs a keyboard, so it is skipped where COUNTDOWN_NO_HINT is set or
stdin is not a terminal — there the clock simply takes over on the same timer.
USAGE
}

[[ $# -eq 0 || "${1:-}" == -h || "${1:-}" == --help ]] && { usage; exit 0; }

SPEC="$1"
LABEL="${2:-}"
LABEL_H=0; [[ -n "$LABEL" ]] && LABEL_H=2   # rows the label costs, used by both the scale fit and the centering

# The footer normally ends with a "Ctrl+C to quit" hint. Set COUNTDOWN_NO_HINT=1
# to drop it — useful where the keyboard never reaches this process anyway, such
# as behind a locked screensaver, where the hint promises an exit that isn't there.
if [[ -n "${COUNTDOWN_NO_HINT:-}" ]]; then HINT=""; else HINT="  ·  Ctrl+C to quit"; fi

# ---- colors (ANSI background codes)
COLOR_CLOCK=44      # current time         : blue
COLOR_NORMAL=46     # countdown            : cyan
COLOR_WARN=43       # last 30 minutes      : yellow
COLOR_URGENT=41     # last 5 minutes       : red
COLOR_DONE=47       # alternating frame once time is up

# ---- alert when time is up; each layer is optional and degrades silently
ALERT_BELL=1        # terminal bell: PC-speaker buzzer in a bare TTY,
                    # window urgency hint in kitty (kitty.conf has
                    # enable_audio_bell no, so it flashes rather than beeps)
ALERT_NOTIFY=1      # desktop notification via notify-send, needs a graphical session
ALERT_SOUND=1       # actual audible sound through the sound server
ALERT_SOUNDS=(
    /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
    /usr/share/sounds/freedesktop/stereo/complete.oga
)

# ---- what the screen does once the countdown reaches zero
# It stops being a countdown and becomes a waiting state: a key menu in the
# footer, and — if nobody presses anything — a plain clock, which is the useful
# thing to leave on a monitor once the meeting it was counting to has started.
# The menu needs a keyboard, so it is off wherever the hint above is off, and
# wherever stdin is not a terminal; there the clock still takes over on the same
# timer, since that half needs nobody present.
MENU_TIMEOUT="${COUNTDOWN_MENU_TIMEOUT:-30}"    # seconds; 0 keeps 00:00 on screen
[[ "$MENU_TIMEOUT" =~ ^[0-9]+$ ]] || MENU_TIMEOUT=30
MENU_CMD="${COUNTDOWN_CMD:-}"                   # offered as [x]; empty hides the key
if [[ -t 0 && -z "${COUNTDOWN_NO_HINT:-}" ]]; then MENU=1; else MENU=0; fi

# ---- 3x5 digit bitmaps, one space-separated word per row
declare -A SEG
SEG[0]="111 101 101 101 111"
SEG[1]="010 110 010 010 111"
SEG[2]="111 001 111 100 111"
SEG[3]="111 001 111 001 111"
SEG[4]="101 101 111 001 001"
SEG[5]="111 100 111 001 111"
SEG[6]="111 100 111 101 111"
SEG[7]="111 001 001 001 001"
SEG[8]="111 101 111 101 111"
SEG[9]="111 101 111 001 111"
SEG[:]="0 1 0 1 0"

# ---- resolve target: ":" means a clock time, anything else a duration
# A function rather than a straight run, because [r] restarts the countdown and
# has to go through exactly this path again: a duration restarts from now, and a
# wall-clock target resolves to its *next* occurrence instead of firing at once.
# Sets TARGET_EPOCH, TOMORROW and TARGET; exits on bad input, which can only
# happen on the first call.
resolve_target() {
    local secs rest ok
    TOMORROW=""

    if [[ "$SPEC" == *:* ]]; then
        if ! TARGET_EPOCH="$(date -d "$SPEC" +%s 2>/dev/null)"; then
            echo "Invalid time: $SPEC   (example: 16:45)" >&2
            exit 1
        fi
        if [[ "$TARGET_EPOCH" -le "$(date +%s)" ]]; then
            TARGET_EPOCH="$(date -d "tomorrow $SPEC" +%s)"
            TOMORROW=" (tomorrow)"
        fi
    else
        secs=0; rest="$SPEC"; ok=0
        if [[ "$rest" =~ ^[0-9]+$ ]]; then
            secs=$(( rest * 60 )); ok=1                     # bare number = minutes
        else
            while [[ "$rest" =~ ^([0-9]+)([hms])(.*)$ ]]; do
                case "${BASH_REMATCH[2]}" in
                    h) secs=$(( secs + BASH_REMATCH[1] * 3600 ));;
                    m) secs=$(( secs + BASH_REMATCH[1] * 60   ));;
                    s) secs=$(( secs + BASH_REMATCH[1]        ));;
                esac
                rest="${BASH_REMATCH[3]}"; ok=1
            done
            [[ -n "$rest" ]] && ok=0                        # trailing junk
        fi
        if [[ "$ok" -ne 1 || "$secs" -le 0 ]]; then
            echo "Invalid duration: $SPEC   (examples: 25m, 1h30m, 90s, 25)" >&2
            exit 1
        fi
        TARGET_EPOCH=$(( $(date +%s) + secs ))
        [[ "$(date -d "@$TARGET_EPOCH" +%F)" != "$(date +%F)" ]] && TOMORROW=" (tomorrow)"
    fi

    # What the footer and title call the target — always a clock time, so a
    # duration shows you the wall-clock moment it resolved to.
    TARGET="$(date -d "@$TARGET_EPOCH" '+%H:%M')"
}

resolve_target

# ---- terminal title: without this the tab just shows "bash countdown.sh"
# Terminated with ST (ESC \), not BEL — a BEL-terminated OSC would emit a
# bell character every second, which rings on terminals with the audio bell on.
set_title() { [[ -t 1 ]] && printf '\e]0;%s\e\\' "$1"; }

TTY_STATE=""                        # non-empty means the terminal owes a restore

# On EXIT, not inside cleanup: a Ctrl+C lands while `read` is waiting for a menu
# key, and bash puts back the settings *it* saved when read started — which are
# ours with echo already off — after the INT trap has run. Restoring from the
# trap therefore gets silently undone and the shell comes back with a dead
# keyboard. The EXIT trap runs last, which is the only place this holds.
tty_restore() { [[ -n "$TTY_STATE" ]] && stty "$TTY_STATE" 2>/dev/null; }
trap tty_restore EXIT

cleanup() {
    set_title "${SHELL##*/}"        # hand the title back to the shell
    printf '\e[?25h\e[0m\n'         # cursor on, attributes reset
    exit 0
}
trap cleanup INT TERM

# Echo goes off for the whole run, not just while the menu is reading keys:
# anything typed at the countdown would otherwise be printed on top of the
# digits. That means the terminal has to be handed back exactly as it was, so
# the settings are saved here and restored in cleanup — and this sits *below*
# the argument parsing on purpose, so a usage error never exits with echo off.
if [[ "$MENU" -eq 1 ]] && command -v stty >/dev/null 2>&1; then
    TTY_STATE="$(stty -g 2>/dev/null)"
    [[ -n "$TTY_STATE" ]] && stty -echo 2>/dev/null
fi

printf '\e[?25l\e[2J'

pad() { printf '%*s' "$1" ''; }

# Fire every configured alert layer once. Anything unavailable is skipped
# without noise, so the same script works in a bare TTY and on a desktop.
alert() {
    local msg="$1" f

    if [[ "$ALERT_BELL" == 1 ]]; then
        for _ in 1 2 3 4 5; do printf '\a'; sleep 0.2; done
    fi

    if [[ "$ALERT_NOTIFY" == 1 ]] && command -v notify-send >/dev/null 2>&1 \
       && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        notify-send -u critical -i alarm -a countdown \
            "${LABEL:-Countdown}" "$msg" >/dev/null 2>&1 &
    fi

    # Players are wrapped in timeout: with no real sink (a dummy auto_null
    # output, e.g. nothing plugged in) they block forever instead of failing.
    if [[ "$ALERT_SOUND" == 1 ]]; then
        local run=""
        command -v timeout >/dev/null 2>&1 && run="timeout 10"
        for f in "${ALERT_SOUNDS[@]}"; do
            [[ -r "$f" ]] || continue
            if   command -v pw-play >/dev/null 2>&1; then $run pw-play "$f" >/dev/null 2>&1 &
            elif command -v paplay  >/dev/null 2>&1; then $run paplay  "$f" >/dev/null 2>&1 &
            elif command -v aplay   >/dev/null 2>&1; then $run aplay -q "$f" >/dev/null 2>&1 &
            fi
            break
        done
    fi
}

# Throw away whatever was typed while the countdown ran. Without this the menu
# opens and instantly consumes a stray keystroke from minutes ago — and one of
# the keys it could land on is [q].
flush_keys() {
    local _k
    while IFS= read -rsn1 -t 0.001 _k; do :; done
}

# [x] — run the configured command, detached. stdin comes from /dev/null so the
# child cannot eat the keystrokes meant for the menu, and both output streams go
# nowhere: anything it printed would land in the middle of the drawn screen.
notice=""; notice_until=0
run_cmd() {
    ( eval "$MENU_CMD" ) </dev/null >/dev/null 2>&1 &
    notice="ran: $MENU_CMD"
    notice_until=$(( $(date +%s) + 3 ))
}

# emit one big-digit string, row by row
draw() {
    local text="$1" hs="$2" vs="$3" color="$4"
    local r i b v c seg line
    local -a parts
    for ((r=0; r<5; r++)); do
        line=""
        for ((i=0; i<${#text}; i++)); do
            c="${text:i:1}"
            read -ra parts <<< "${SEG[$c]}"
            seg="${parts[$r]}"
            for ((b=0; b<${#seg}; b++)); do
                if [[ "${seg:b:1}" == "1" ]]; then
                    line+="\e[${color}m$(pad "$hs")\e[0m"
                else
                    line+="$(pad "$hs")"
                fi
            done
            line+="$(pad "$hs")"
        done
        for ((v=0; v<vs; v++)); do printf '%b\n' "$line"; done
    done
}

# on-screen width of a big-digit string
width() {
    local text="$1" hs="$2" i c w=0
    local -a parts
    for ((i=0; i<${#text}; i++)); do
        c="${text:i:1}"
        read -ra parts <<< "${SEG[$c]}"
        w=$(( w + ${#parts[0]} * hs + hs ))
    done
    echo $(( w - hs ))
}

print_digits() {
    local text="$1" hs="$2" vs="$3" color="$4" cols="$5"
    local w left
    w="$(width "$text" "$hs")"
    left=$(( (cols - w) / 2 )); [[ "$left" -lt 0 ]] && left=0
    draw "$text" "$hs" "$vs" "$color" | while IFS= read -r l; do
        printf '\e[K%*s%b\n' "$left" '' "$l"
    done
}

print_text() {
    local text="$1" cols="$2" style="${3:-2}"
    local left=$(( (cols - ${#text}) / 2 )); [[ "$left" -lt 0 ]] && left=0
    printf '\e[K%*s\e[%sm%s\e[0m\n' "$left" '' "$style" "$text"
}

# Three states, in this order: count -> menu -> clock. [r] sends it back to
# count from either of the other two, which is the whole reason the target is
# resolved by a function.
mode=count
expired=0
expired_at=0

while :; do
    now_epoch="$(date +%s)"
    left_secs=$(( TARGET_EPOCH - now_epoch ))

    if [[ "$left_secs" -le 0 && "$expired" -eq 0 ]]; then
        expired=1
        expired_at="$now_epoch"
        mode=menu
        alert "$TARGET reached."
        flush_keys
    fi
    # The menu is a waiting state, and waiting states need an end: with nobody
    # there to press a key it hands the screen to a plain clock, which is the
    # useful thing to leave on a monitor. MENU_TIMEOUT=0 keeps 00:00 instead.
    if [[ "$mode" == menu && "$MENU_TIMEOUT" -gt 0 \
          && $(( now_epoch - expired_at )) -ge "$MENU_TIMEOUT" ]]; then
        mode=clock
    fi

    # The key line is a real row and has to be paid for out of the same vertical
    # budget as everything else, or it pushes the footer off a short screen.
    menu_h=0; [[ "$MENU" -eq 1 && "$mode" != count ]] && menu_h=1

    cols="$(tput cols  2>/dev/null || echo 80)"
    rows="$(tput lines 2>/dev/null || echo 24)"

    # Scale to whichever axis runs out first. Every state renders 5 characters
    # (HH:MM or MM:SS) = 18 cells wide per unit of scale, so the width gives a
    # starting point; then step down until the stacked rows fit too. Without the
    # vertical pass a wide-but-short window silently clips the digits, and a
    # fixed ceiling would leave a 1920x1080 terminal rendering at a fraction of
    # the space it has. The remaining cap is only a sanity bound.
    hs=$(( (cols - 4) / 18 )); [[ "$hs" -gt 20 ]] && hs=20
    while [[ "$hs" -gt 1 ]]; do
        _hs_s=$(( hs / 2 ));         [[ "$_hs_s" -lt 1 ]] && _hs_s=1
        _vs_s=$(( (_hs_s + 1) / 2 )); [[ "$_vs_s" -lt 1 ]] && _vs_s=1
        _vs=$(( (hs + 1) / 2 ))
        # mirrors the "base" budget used for vertical centering below
        [[ $(( 5 * _vs_s + 1 + LABEL_H + 5 * _vs + 1 + 2 + menu_h )) -le "$rows" ]] && break
        hs=$(( hs - 1 ))
    done
    [[ "$hs" -lt 1 ]] && hs=1
    vs=$(( (hs + 1) / 2 ));      [[ "$vs" -lt 1 ]] && vs=1
    hs_s=$(( hs / 2 ));          [[ "$hs_s" -lt 1 ]] && hs_s=1
    vs_s=$(( (hs_s + 1) / 2 ));  [[ "$vs_s" -lt 1 ]] && vs_s=1

    # Even the smallest scale needs 14 rows with the clock on top. Below that
    # the clock goes, which is the least useful of the three (the countdown is
    # the point, and the footer carries the target). Order of sacrifice on a
    # shrinking window: date, then clock.
    clock_h=1
    [[ $(( 5 * vs_s + 1 + LABEL_H + 5 * vs + 1 + 2 + menu_h )) -gt "$rows" ]] && clock_h=0

    today="$(date '+%A, %-d %B %Y')"     # follows LC_TIME
    now="$(date '+%H:%M')"
    keys=""

    # Adaptive precision: always the two most significant units. Seconds are
    # noise while hours remain, so they only appear inside the last hour.
    if [[ "$mode" == clock ]]; then
        # The big digits *are* the clock now, so the half-scale one on top goes:
        # two copies of the same time is the one layout worth vetoing.
        digits="$now"
        units=""
        color=$COLOR_CLOCK
        clock_h=0
        footer="target $TARGET reached"
        if [[ "$MENU" -eq 1 ]]; then
            keys="[r] restart   [q] quit"
        else
            footer+="$HINT"
        fi
        [[ "${#footer}" -gt "$cols" ]] && footer="$TARGET reached"
        set_title "${LABEL:+$LABEL — }$now"
    elif [[ "$mode" == menu ]]; then
        digits="00:00"
        units="minutes : seconds"
        color=$COLOR_URGENT
        [[ $(( now_epoch % 2 )) -eq 0 ]] && color=$COLOR_DONE
        footer="TIME'S UP  —  target $TARGET"
        [[ "$MENU_TIMEOUT" -gt 0 ]] && \
            footer+="  ·  clock in $(( MENU_TIMEOUT - (now_epoch - expired_at) ))s"
        if [[ "$MENU" -eq 1 ]]; then
            keys="[r] restart   [c] clock${MENU_CMD:+   [x] run}   [q] quit"
        else
            footer+="$HINT"
        fi
        # A footer wider than the screen wraps, and a wrapped line costs a row
        # the vertical budget never allowed for — what falls off the bottom is
        # the key line. So on a narrow terminal the extras go instead.
        [[ "${#footer}" -gt "$cols" ]] && footer="TIME'S UP  ·  $TARGET"
        set_title "TIME'S UP - $TARGET"
    else
        if [[ "$left_secs" -ge 3600 ]]; then
            printf -v digits '%02d:%02d' \
                $(( left_secs / 3600 )) $(( left_secs % 3600 / 60 ))
            units="hours : minutes"
            remaining="$(( left_secs / 3600 ))h $(( left_secs % 3600 / 60 ))m left"
        else
            printf -v digits '%02d:%02d' \
                $(( left_secs / 60 )) $(( left_secs % 60 ))
            units="minutes : seconds"
            remaining="$(( left_secs / 60 ))m $(( left_secs % 60 ))s left"
        fi
        if   [[ "$left_secs" -lt 300  ]]; then color=$COLOR_URGENT
        elif [[ "$left_secs" -lt 1800 ]]; then color=$COLOR_WARN
        else                                   color=$COLOR_NORMAL
        fi
        footer="target $TARGET$TOMORROW  ·  $remaining$HINT"
        set_title "${LABEL:+$LABEL — }$remaining -> $TARGET"
    fi

    # Same reasoning for the key line: the brackets and the wide gaps are the
    # part that can go, and only once it would not fit as it stands.
    if [[ -n "$keys" && "${#keys}" -gt "$cols" ]]; then
        keys="${keys//\[/}"; keys="${keys//] /=}"; keys="${keys//   / }"
    fi

    # [x] gets its confirmation in the footer for three seconds — a detached
    # command produces nothing visible, so without this the key looks dead.
    if [[ -n "$notice" ]]; then
        if [[ "$now_epoch" -lt "$notice_until" ]]; then
            footer="$notice"
            # A command is usually a path, and a path is usually longer than the
            # footer it has to fit in; wrapping here costs the same unbudgeted row.
            [[ "${#footer}" -gt "$cols" ]] && footer="${footer:0:cols-1}…"
        else
            notice=""
        fi
    fi

    # vertical centering; the date is the first thing dropped on a short screen
    label_h=$LABEL_H
    base=$(( clock_h * (5 * vs_s + 1) + label_h + 5 * vs + 1 + 2 + menu_h ))
    date_h=1; [[ $(( base + date_h )) -gt "$rows" ]] && date_h=0
    total=$(( base + date_h ))
    top=$(( (rows - total) / 2 )); [[ "$top" -lt 0 ]] && top=0

    {
        printf '\e[H'
        for ((k=0; k<top; k++)); do printf '\e[K\n'; done

        [[ "$date_h" -eq 1 ]] && print_text "$today" "$cols" "2"
            if [[ "$clock_h" -eq 1 ]]; then
            print_digits "$now" "$hs_s" "$vs_s" "$COLOR_CLOCK" "$cols"
            printf '\e[K\n'
        fi

        if [[ -n "$LABEL" ]]; then
            print_text "$LABEL" "$cols" "1"
            printf '\e[K\n'
        fi

        print_digits "$digits" "$hs" "$vs" "$color" "$cols"
        print_text "$units" "$cols" "2"

        printf '\e[K\n'
        print_text "$footer" "$cols" "2"
        [[ "$menu_h" -eq 1 ]] && print_text "$keys" "$cols" "1"
        printf '\e[J'
    }

    # Sleep to the next wall-clock second rather than a flat 1s. Each frame
    # forks tput twice and date three times, so a flat sleep makes the period
    # ~1.03s and the display drops a second every half minute (46 -> 44).
    rem=$(( 1000000000 - 10#$(date +%N) ))
    nap="$(printf '%d.%09d' "$(( rem / 1000000000 ))" "$(( rem % 1000000000 ))")"

    # While the menu is up the wait *is* the keyboard read — same fractional
    # deadline, so the frame still lands on the second whether a key arrives or
    # not. Only the states after zero listen: a key pressed at the countdown
    # would be an easy way to lose one by accident, and Ctrl+C already quits.
    if [[ "$menu_h" -eq 1 ]]; then
        key=""
        IFS= read -rsn1 -t "$nap" key
        case "$key" in
            q|Q) cleanup ;;
            c|C) mode=clock ;;
            r|R) resolve_target; expired=0; mode=count; notice="" ;;
            x|X) [[ -n "$MENU_CMD" ]] && run_cmd ;;
        esac
        # A keypress is proof somebody is here, which is the one thing the
        # timeout is testing for — so it starts over rather than pulling the
        # menu out from under a hand that is still using it.
        [[ -n "$key" && "$mode" == menu ]] && expired_at="$now_epoch"
    else
        sleep "$nap"
    fi
done
